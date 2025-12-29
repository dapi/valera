# frozen_string_literal: true

module Manager
  # Сервис для отправки сообщения от менеджера клиенту
  #
  # Сохраняет сообщение в БД с ролью 'manager' и отправляет его клиенту в Telegram.
  # Автоматически продлевает таймаут менеджера при каждом сообщении.
  #
  # @example Отправка сообщения
  #   result = Manager::MessageService.call(
  #     chat: chat,
  #     user: current_user,
  #     content: "Здравствуйте! Чем могу помочь?"
  #   )
  #   if result.success?
  #     puts "Сообщение #{result.message.id} отправлено"
  #   end
  #
  # @author AI Assistant
  # @since 0.38.0
  class MessageService
    include ErrorLogger

    # Ошибки которые мы обрабатываем gracefully
    HANDLED_ERRORS = [
      ActiveRecord::RecordInvalid,
      ActiveRecord::RecordNotSaved
    ].freeze

    # @return [Chat] чат для отправки
    attr_reader :chat

    # @return [User] менеджер, отправляющий сообщение
    attr_reader :user

    # @return [String] текст сообщения
    attr_reader :content

    # @return [Boolean] продлевать ли таймаут
    attr_reader :extend_timeout

    Result = Struct.new(:success?, :message, :telegram_sent, :error, keyword_init: true)

    # Фабричный метод для создания и выполнения сервиса
    #
    # @param chat [Chat] чат
    # @param user [User] менеджер
    # @param content [String] текст сообщения
    # @param extend_timeout [Boolean] продлевать ли таймаут менеджера
    # @return [Result] результат операции
    def self.call(chat:, user:, content:, extend_timeout: true)
      new(chat:, user:, content:, extend_timeout:).call
    end

    # @param chat [Chat] чат
    # @param user [User] менеджер
    # @param content [String] текст сообщения
    # @param extend_timeout [Boolean] продлевать ли таймаут менеджера
    def initialize(chat:, user:, content:, extend_timeout: true)
      @chat = chat
      @user = user
      @content = content
      @extend_timeout = extend_timeout
    end

    # Выполняет отправку сообщения
    #
    # @return [Result] результат с сообщением и статусом отправки
    def call
      validate!
      message = create_message
      telegram_result = send_to_telegram
      extend_manager_timeout if extend_timeout
      build_success_result(message, telegram_result)
    rescue ArgumentError => e
      Result.new(success?: false, error: e.message)
    rescue *HANDLED_ERRORS => e
      log_error(e, safe_context)
      Result.new(success?: false, error: e.message)
    end

    private

    def validate!
      raise ArgumentError, 'Chat is required' if chat.nil?
      raise ArgumentError, 'User is required' if user.nil?
      raise ArgumentError, 'Content is required' if content.blank?
      raise ArgumentError, 'Chat is not in manager mode' unless chat.manager_mode?
      raise ArgumentError, 'User is not the active manager' unless user_is_active_manager?
    end

    def user_is_active_manager?
      chat.manager_user_id == user.id
    end

    def create_message
      chat.messages.create!(
        role: 'manager',
        content:,
        sent_by_user: user
      )
    end

    def send_to_telegram
      TelegramMessageSender.call(chat:, text: content)
    end

    def extend_manager_timeout
      chat.extend_manager_timeout!
    end

    def build_success_result(message, telegram_result)
      Result.new(
        success?: true,
        message:,
        telegram_sent: telegram_result.success?
      )
    end

    def safe_context
      {
        service: self.class.name,
        chat_id: chat&.id,
        user_id: user&.id,
        content_length: content&.length
      }
    end
  end
end
