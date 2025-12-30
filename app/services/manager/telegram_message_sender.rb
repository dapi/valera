# frozen_string_literal: true

module Manager
  # Отправляет сообщения клиенту в Telegram от имени бота тенанта
  #
  # Низкоуровневый сервис для отправки сообщений через Telegram Bot API.
  # Используется другими сервисами (Manager::MessageService, Manager::TakeoverService и др.).
  #
  # @example Отправка простого сообщения
  #   result = Manager::TelegramMessageSender.call(chat: chat, text: "Привет!")
  #   if result.success?
  #     puts "Сообщение отправлено: #{result.telegram_message_id}"
  #   end
  #
  # @author AI Assistant
  # @since 0.38.0
  class TelegramMessageSender
    include ErrorLogger

    # Ошибки Telegram API которые мы обрабатываем gracefully
    TELEGRAM_ERRORS = [
      Telegram::Bot::Error,
      Faraday::Error,
      Timeout::Error
    ].freeze

    # @return [Chat] чат, в который отправляется сообщение
    attr_reader :chat

    # @return [String] текст сообщения
    attr_reader :text

    # @return [String] режим парсинга (HTML, Markdown, MarkdownV2)
    attr_reader :parse_mode

    Result = Struct.new(:success?, :telegram_message_id, :error, keyword_init: true)

    # Фабричный метод для создания и выполнения сервиса
    #
    # @param chat [Chat] чат для отправки
    # @param text [String] текст сообщения
    # @param parse_mode [String] режим парсинга
    # @return [Result] результат операции
    def self.call(chat:, text:, parse_mode: 'HTML')
      new(chat:, text:, parse_mode:).call
    end

    # @param chat [Chat] чат для отправки
    # @param text [String] текст сообщения
    # @param parse_mode [String] режим парсинга
    def initialize(chat:, text:, parse_mode: 'HTML')
      @chat = chat
      @text = text
      @parse_mode = parse_mode
    end

    # Выполняет отправку сообщения
    #
    # @return [Result] результат с telegram_message_id или ошибкой
    def call
      validate!
      send_message
    rescue ArgumentError => e
      Result.new(success?: false, error: e.message)
    rescue *TELEGRAM_ERRORS => e
      log_error(e, safe_context)
      Result.new(success?: false, error: e.message)
    end

    private

    def validate!
      raise ArgumentError, 'Chat is required' if chat.nil?
      raise ArgumentError, 'Text is required' if text.blank?
      raise ArgumentError, 'Chat has no telegram_user' if telegram_chat_id.blank?
    end

    def send_message
      response = bot_client.send_message(
        chat_id: telegram_chat_id,
        text: text,
        parse_mode: parse_mode
      )

      Result.new(
        success?: true,
        telegram_message_id: response&.dig('result', 'message_id')
      )
    end

    def bot_client
      chat.tenant.bot_client
    end

    def telegram_chat_id
      chat.client.telegram_user_id
    end

    def safe_context
      {
        service: self.class.name,
        chat_id: chat&.id,
        tenant_id: chat&.tenant_id,
        telegram_chat_id: chat&.client&.telegram_user_id
      }
    end
  end
end
