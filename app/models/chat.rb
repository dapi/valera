# frozen_string_literal: true

# Модель диалога между пользователем и AI ассистентом
#
# Управляет разговором с AI, хранит сообщения, обрабатывает tool calls
# и обеспечивает персистентность контекста диалога.
#
# @attr [Integer] tenant_id ID арендатора (автосервиса)
# @attr [Integer] client_id ID клиента
# @attr [Integer] ruby_llm_model_id ID используемой AI модели (реестр RubyLLM)
# @attr [Hash] context контекст диалога (например, API ключи)
# @attr [DateTime] created_at время создания
# @attr [DateTime] updated_at время обновления
#
# @example Создание нового диалога
#   chat = Chat.create!(tenant: tenant, client: client)
#   chat.say("Привет, как дела?")
#
# @see Message для отдельных сообщений
# @see RubyLLM::ActiveRecord::ToolCall для вызовов инструментов
# @see ruby_llm gem документация
# @author Danil Pismenny
# @since 0.1.0
class Chat < ApplicationRecord
  include ErrorLogger

  belongs_to :tenant, counter_cache: true
  belongs_to :client
  belongs_to :chat_topic, optional: true
  belongs_to :taken_by, class_name: 'User', optional: true

  has_one :telegram_user, through: :client

  has_many :bookings, dependent: :destroy

  acts_as_chat

  # Broadcast page refresh when chat changes (mode, takeover status, etc.)
  # Uses Turbo 8 morphing for smooth updates
  broadcasts_refreshes

  # Takeover support
  # mode: ai_mode (по умолчанию) - бот отвечает автоматически
  # mode: manager_mode - менеджер перехватил диалог, бот не отвечает
  enum :mode, { ai_mode: 0, manager_mode: 1 }, default: :ai_mode

  validates :taken_by, presence: true, if: :manager_mode?
  validates :taken_at, presence: true, if: :manager_mode?

  scope :in_manager_mode, -> { where(mode: :manager_mode) }
  scope :in_ai_mode, -> { where(mode: :ai_mode) }
  scope :taken_by_user, ->(user) { where(taken_by: user) }

  # Alias for ai_mode? for backward compatibility
  alias_method :bot_mode?, :ai_mode?

  # Возвращает true если менеджер активен и timeout не истёк
  # @return [Boolean] true если в manager_mode и timeout не истёк
  def manager_active?
    manager_mode? && !takeover_expired?
  end

  # Scope для предзагрузки данных клиента и Telegram пользователя
  # Используется в dashboard для отображения информации о клиенте
  scope :with_client_details, -> { includes(client: :telegram_user) }

  # Возвращает оставшееся время до автоматического возврата боту
  #
  # Использует колонку `manager_active_until` для расчёта
  #
  # @return [Numeric, nil] секунды до таймаута или nil если не в manager_mode
  def takeover_time_remaining
    return nil unless manager_mode? && manager_active_until

    [ manager_active_until - Time.current, 0 ].max
  end

  # Проверяет, истёк ли таймаут takeover
  # @return [Boolean]
  def takeover_expired?
    manager_mode? && manager_active_until && manager_active_until < Time.current
  end

  # Переключает чат в режим менеджера
  #
  # @param user [User] менеджер, берущий чат
  # @param timeout_minutes [Integer] таймаут в минутах (по умолчанию из конфига)
  # @return [Chat] self после обновления
  # @raise [ActiveRecord::RecordInvalid] при ошибке валидации
  def takeover_by_manager!(user, timeout_minutes: nil)
    timeout = (timeout_minutes || ApplicationConfig.manager_takeover_timeout_minutes).minutes
    update!(
      mode: :manager_mode,
      taken_by: user,
      taken_at: Time.current,
      manager_active_until: Time.current + timeout
    )
  end

  # Возвращает чат в режим AI-бота
  #
  # @return [Chat] self после обновления
  # @raise [ActiveRecord::RecordInvalid] при ошибке валидации
  def release_to_bot!
    update!(
      mode: :ai_mode,
      taken_by: nil,
      taken_at: nil,
      manager_active_until: nil
    )
  end

  # Продлевает таймаут менеджера
  #
  # @param timeout_minutes [Integer] новый таймаут в минутах
  # @return [Boolean] true при успехе, false если не в manager_mode
  # @raise [ActiveRecord::RecordInvalid] при ошибке валидации
  def extend_manager_timeout!(timeout_minutes: nil)
    return false unless manager_mode?

    timeout = (timeout_minutes || ApplicationConfig.manager_takeover_timeout_minutes).minutes
    update!(
      taken_at: Time.current,
      manager_active_until: Time.current + timeout
    )
    true
  end

  # Alias для takeover_time_remaining
  alias_method :time_until_auto_release, :takeover_time_remaining

  # Устанавливает модель AI по умолчанию при создании
  #
  # RubyLLM разрешает модель в реестре в before_save, поэтому провайдер и модель
  # задаются раньше — в before_validation.
  #
  # @return [void]
  # @note Использует модель из конфигурации приложения
  # @see ApplicationConfig для настроек LLM
  before_validation on: :create do
    if model.nil?
      self.provider = ApplicationConfig.llm_provider
      self.model = ApplicationConfig.llm_model
      # Gateway aliases (e.g. LiteLLM subscription models) are not in the registry.
      self.assume_model_exists = true
    end
  end

  # Сбрасывает диалог к начальному состоянию
  #
  # Удаляет все сообщения и устанавливает системные инструкции заново.
  # Используется для очистки контекста диалога.
  #
  # @return [void]
  # @example
  #   chat.reset!
  #   #=> все сообщения удалены, инструкции установлены заново
  # @note Также можно использовать для очистки контекста при ошибках
  def reset!
    messages.destroy_all
  end

  private

  # Сохраняет tool calls штатно (RubyLLM) и запускает создание заявки
  #
  # @param tool_calls [Hash] хеш с tool calls
  # @param message_record [Message] сообщение ассистента с вызовами
  # @return [void]
  # @raise [StandardError] при ошибке сохранения tool calls
  # @api private
  def persist_tool_calls(tool_calls, message_record: @message)
    super
    tool_calls.each_value do |tool_call|
      handle_booking_creator_persisted(tool_call) if tool_call.name == 'booking_creator'
    end
  rescue StandardError => e
    log_error(e, {
                model: self.class.name,
                method: 'persist_tool_calls',
                chat_id: id
              })
    raise e
  end

  # Обрабатывает tool call для создания заявки
  #
  # @param tool_call [RubyLLM::ToolCall] tool call с именем 'booking_creator'
  # @return [void]
  # @api private
  def handle_booking_creator_persisted(tool_call)
    # Извлекаем параметры из tool call
    arguments = tool_call.arguments
    parameters = arguments.is_a?(String) ? JSON.parse(arguments.presence || '{}') : arguments.to_h

    # Вызываем BookingCreatorTool с нужным контекстом
    result = BookingCreatorTool.call(
      parameters: parameters,
      context: {
        telegram_user: telegram_user,
        chat: self
      }
    )

    Rails.logger.info "Booking creator tool executed successfully: #{result[:booking_id]}"
  end
end
