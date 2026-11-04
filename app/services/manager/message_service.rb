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
  # @since 0.38.0
  class MessageService
    include ErrorLogger

    # Ошибки которые мы обрабатываем gracefully
    HANDLED_ERRORS = [
      ActiveRecord::RecordInvalid,
      ActiveRecord::RecordNotSaved
    ].freeze

    # Максимальная длина сообщения в Telegram Bot API (не конфигурируется)
    # @see https://core.telegram.org/bots/api#sendmessage
    MAX_MESSAGE_LENGTH = 4096

    # Ошибка валидации входных параметров сервиса
    class ValidationError < StandardError; end

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
    # @raise [RuntimeError] если chat, user или content не переданы
    def initialize(chat:, user:, content:, extend_timeout: true)
      @chat = chat || raise('No chat')
      @user = user || raise('No user')
      @content = content.presence || raise('No content')
      @extend_timeout = extend_timeout
    end

    # Выполняет отправку сообщения
    #
    # Порядок операций важен для предсказуемости:
    # 1. Сначала отправляем в Telegram
    # 2. Только после успешной отправки сохраняем в БД
    #
    # Это гарантирует, что если менеджер видит сообщение в dashboard,
    # то клиент точно его получил в Telegram.
    #
    # @return [Result] результат с сообщением и статусом отправки
    def call
      validate_state!

      # Сначала отправляем в Telegram - если не доставили, не сохраняем
      telegram_result = send_to_telegram
      unless telegram_result.success?
        log_error(
          StandardError.new("Telegram delivery failed: #{telegram_result.error}"),
          safe_context.merge(telegram_error: telegram_result.error)
        )
        return Result.new(success?: false, error: I18n.t('manager.message.telegram_delivery_failed'))
      end

      # Только после успешной отправки в Telegram сохраняем в БД
      message = create_message
      extend_manager_timeout if extend_timeout
      track_message_sent
      build_success_result(message, telegram_result)
    rescue ValidationError => e
      Rails.logger.warn("[#{self.class.name}] Validation failed: #{e.message}")
      Result.new(success?: false, error: e.message)
    rescue *HANDLED_ERRORS => e
      log_error(e, safe_context)
      Result.new(success?: false, error: e.message)
    end

    private

    def validate_state!
      raise ValidationError, 'Content is too long' if content.length > MAX_MESSAGE_LENGTH
      raise ValidationError, 'Chat is not in manager mode' unless chat.manager_mode?
      raise ValidationError, 'Manager session has expired' unless chat.manager_active?
      raise ValidationError, 'User is not the active manager' unless user_is_active_manager?
    end

    def user_is_active_manager?
      chat.taken_by_id == user.id
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
        chat_id: chat.id,
        user_id: user.id,
        content_length: content.length
      }
    end

    # Отслеживает событие отправки сообщения менеджером
    #
    # @return [void]
    def track_message_sent
      AnalyticsService.track(
        AnalyticsService::Events::MANAGER_MESSAGE_SENT,
        tenant: chat.tenant,
        chat_id: chat.id,
        properties: {
          manager_id: user.id,
          message_length: content.length
        }
      )
    end
  end
end
