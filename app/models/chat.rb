# frozen_string_literal: true

# Модель диалога между пользователем и AI ассистентом
#
# Управляет разговором с AI, хранит сообщения, обрабатывает tool calls
# и обеспечивает персистентность контекста диалога.
#
# @attr [Integer] tenant_id ID арендатора (автосервиса)
# @attr [Integer] client_id ID клиента
# @attr [Integer] model_id ID используемой AI модели
# @attr [Hash] context контекст диалога (например, API ключи)
# @attr [DateTime] created_at время создания
# @attr [DateTime] updated_at время обновления
#
# @example Создание нового диалога
#   chat = Chat.create!(tenant: tenant, client: client)
#   chat.say("Привет, как дела?")
#
# @see Message для отдельных сообщений
# @see ToolCall для вызовов инструментов
# @see ruby_llm gem документация
# @author Danil Pismenny
# @since 0.1.0
class Chat < ApplicationRecord
  include ErrorLogger

  # Manager takeover timeout in minutes
  MANAGER_TAKEOVER_TIMEOUT = 30

  belongs_to :tenant, counter_cache: true
  belongs_to :client
  belongs_to :chat_topic, optional: true
  belongs_to :manager_user, class_name: 'User', optional: true

  has_one :telegram_user, through: :client

  has_many :bookings, dependent: :destroy

  acts_as_chat

  # Scope для предзагрузки данных клиента и Telegram пользователя
  # Используется в dashboard для отображения информации о клиенте
  scope :with_client_details, -> { includes(client: :telegram_user) }

  # Scopes для фильтрации по режиму менеджера
  scope :manager_controlled, -> { where(manager_active: true) }
  scope :bot_controlled, -> { where(manager_active: false) }

  # Проверяет, активен ли менеджер в чате (с учётом таймаута)
  #
  # @return [Boolean] true если менеджер активен и таймаут не истёк
  def manager_mode?
    return false unless manager_active?

    # Проверяем таймаут
    if manager_active_until.present? && manager_active_until < Time.current
      release_to_bot!
      return false
    end

    true
  end

  # Проверяет, управляется ли чат ботом
  #
  # @return [Boolean] true если чат в режиме бота
  def bot_mode?
    !manager_mode?
  end

  # Менеджер берёт контроль над чатом
  #
  # @param user [User] пользователь, который берёт контроль
  # @param timeout_minutes [Integer] время таймаута в минутах
  # @return [Boolean] успешность операции
  def takeover_by_manager!(user, timeout_minutes: MANAGER_TAKEOVER_TIMEOUT)
    update!(
      manager_active: true,
      manager_user: user,
      manager_active_at: Time.current,
      manager_active_until: timeout_minutes.minutes.from_now
    )
  end

  # Продлевает время активности менеджера
  #
  # @param timeout_minutes [Integer] время таймаута в минутах
  # @return [Boolean] успешность операции
  def extend_manager_timeout!(timeout_minutes: MANAGER_TAKEOVER_TIMEOUT)
    return false unless manager_active?

    update!(manager_active_until: timeout_minutes.minutes.from_now)
  end

  # Возвращает чат боту
  #
  # @return [Boolean] успешность операции
  def release_to_bot!
    update!(
      manager_active: false,
      manager_user: nil,
      manager_active_at: nil,
      manager_active_until: nil
    )
  end

  # Время до автоматического возврата боту
  #
  # @return [ActiveSupport::Duration, nil] оставшееся время или nil
  def time_until_auto_release
    return nil unless manager_active? && manager_active_until.present?

    remaining = manager_active_until - Time.current
    remaining.positive? ? remaining.seconds : nil
  end

  # Устанавливает модель AI по умолчанию перед созданием
  #
  # @return [void]
  # @note Использует модель из конфигурации приложения
  # @see ApplicationConfig для настроек LLM
  before_create do
    self.model ||= Model.find_by!(provider: ApplicationConfig.llm_provider, model_id: ApplicationConfig.llm_model)
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

  # Сохраняет новое сообщение без контента (заготовка)
  #
  # @return [Message] новое сообщение с ролью :assistant
  # @api private
  def persist_new_message
    @message = messages.new(role: :assistant)
  end

  # Сохраняет завершение сообщения с контентом и токенами
  #
  # @param message [RubyLLM::Message] сообщение от LLM
  # @return [void]
  # @api private
  def persist_message_completion(message)
    return unless message

    # Find tool_call database ID if this is a tool result message
    tool_call_db_id = find_tool_call_db_id(message.tool_call_id) if message.tool_call_id

    # Fill in attributes and save once we have content
    @message.assign_attributes(
      role: message.role,
      content: message.content,
      model: Model.find_by(model_id: message.model_id),
      input_tokens: message.input_tokens,
      output_tokens: message.output_tokens
    )

    # Set tool_call_id for tool result messages
    @message.tool_call_id = tool_call_db_id if tool_call_db_id

    @message.save!

    # Handle tool calls if present
    persist_tool_calls(message.tool_calls) if message.tool_calls.present?

    # TODO: Implement context compaction service that preserves original messages
    # See FIP-020 for requirements
  end

  # Обрабатывает и сохраняет tool calls из сообщения
  #
  # @param tool_calls [Hash] хеш с tool calls
  # @return [void]
  # @raise [StandardError] при ошибке сохранения tool calls
  # @api private
  def persist_tool_calls(tool_calls)
    tool_calls.each_value do |tool_call|
      attributes = tool_call.to_h
      attributes[:tool_call_id] = attributes.delete(:id)
      @message.tool_calls.create!(**attributes)

      # Обрабатываем tool calls если это booking_creator
      handle_booking_creator_persisted(tool_call) if tool_call.name == 'booking_creator'
    end
  rescue StandardError => e
    log_error(e, {
                model: self.class.name,
                method: 'persist_tool_calls',
                chat_id: id,
                tool_call_data: tool_call&.to_h
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
    parameters = JSON.parse(tool_call.arguments || '{}')

    # Вызываем BookingCreatorTool с нужным контекстом
    result = BookingCreatorTool.call(
      parameters: parameters,
      context: {
        telegram_user: telegram_user,
        chat: self
      }
    )

    Rails.logger.info "Booking creator tool executed successfully: #{result[:booking_id]}"
  rescue StandardError => e
    log_error(e, {
                tool: 'booking_creator',
                tool_call_id: tool_call.id,
                telegram_user_id: telegram_user&.id,
                chat_id: id,
                parameters: parameters
              })
  end

  # Находит ID записи tool call в базе данных по API ID
  #
  # @param api_tool_call_id [String] ID tool call от API (например, "call_00_...")
  # @return [Integer, nil] ID записи в базе данных или nil если не найден
  # @api private
  def find_tool_call_db_id(api_tool_call_id)
    tool_call_record = ToolCall.find_by(tool_call_id: api_tool_call_id)
    tool_call_record&.id
  end
end
