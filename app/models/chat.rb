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

  has_one :telegram_user, through: :client

  has_many :bookings, dependent: :destroy

  acts_as_chat

  # Scope для предзагрузки данных клиента и Telegram пользователя
  # Используется в dashboard для отображения информации о клиенте
  scope :with_client_details, -> { includes(client: :telegram_user) }

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
  rescue StandardError => e
    log_error(e, {
                tool: 'booking_creator',
                tool_call_id: tool_call.id,
                telegram_user_id: telegram_user&.id,
                chat_id: id,
                parameters: parameters
              })
  end
end
