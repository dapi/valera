# frozen_string_literal: true

module Manager
  # Сервис для перехвата чата менеджером
  #
  # Переводит чат в режим менеджера и опционально уведомляет клиента
  # о том, что его переключили на живого оператора.
  #
  # @example Перехват чата
  #   result = Manager::TakeoverService.call(chat: chat, user: current_user)
  #   if result.success?
  #     puts "Чат перехвачен до #{result.active_until}"
  #   end
  #
  # @author AI Assistant
  # @since 0.38.0
  class TakeoverService
    include ErrorLogger

    # Ошибки которые мы обрабатываем gracefully
    HANDLED_ERRORS = [
      ActiveRecord::RecordInvalid,
      ActiveRecord::RecordNotSaved
    ].freeze

    # Ошибка валидации входных параметров сервиса
    class ValidationError < StandardError; end

    # @return [Chat] чат для перехвата
    attr_reader :chat

    # @return [User] менеджер, который берёт чат
    attr_reader :user

    # @return [Integer] таймаут в минутах
    attr_reader :timeout_minutes

    # @return [Boolean] отправлять ли уведомление клиенту
    attr_reader :notify_client

    Result = Struct.new(:success?, :chat, :active_until, :notification_sent, :error, keyword_init: true)

    # Фабричный метод для создания и выполнения сервиса
    #
    # @param chat [Chat] чат для перехвата
    # @param user [User] менеджер
    # @param timeout_minutes [Integer] таймаут (по умолчанию из конфига)
    # @param notify_client [Boolean] уведомлять ли клиента
    # @return [Result] результат операции
    def self.call(chat:, user:, timeout_minutes: nil, notify_client: true)
      new(chat:, user:, timeout_minutes:, notify_client:).call
    end

    # @param chat [Chat] чат для перехвата
    # @param user [User] менеджер
    # @param timeout_minutes [Integer] таймаут
    # @param notify_client [Boolean] уведомлять ли клиента
    def initialize(chat:, user:, timeout_minutes: nil, notify_client: true)
      @chat = chat
      @user = user
      @timeout_minutes = timeout_minutes || ApplicationConfig.manager_takeover_timeout_minutes
      @notify_client = notify_client
    end

    # Выполняет перехват чата
    #
    # Операции takeover и schedule_timeout_job выполняются в транзакции
    # с pessimistic locking (with_lock), чтобы гарантировать:
    # 1. Атомарность: либо чат перехвачен И job запланирован, либо ничего не изменилось
    # 2. Защиту от race condition: два менеджера не могут одновременно перехватить чат
    #
    # @return [Result] результат с данными о перехвате
    def call
      # Валидация nil-аргументов до with_lock
      raise ValidationError, 'Chat is required' if chat.nil?
      raise ValidationError, 'User is required' if user.nil?

      chat.with_lock do
        validate_chat_state!
        takeover_chat
        schedule_timeout_job
      end

      # Уведомление и аналитика выполняются вне транзакции,
      # так как их неудача не должна откатывать takeover
      notification_result = notify_client ? notify_client_about_takeover : nil
      track_takeover_started
      build_success_result(notification_result)
    rescue ValidationError => e
      Rails.logger.warn("[#{self.class.name}] Validation failed: #{e.message}")
      Result.new(success?: false, error: e.message)
    rescue *HANDLED_ERRORS => e
      log_error(e, safe_context)
      Result.new(success?: false, error: e.message)
    end

    private

    # Валидация состояния чата (вызывается внутри with_lock)
    def validate_chat_state!
      raise ValidationError, 'Chat is already in manager mode' if chat.manager_mode?
    end

    def takeover_chat
      chat.takeover_by_manager!(user, timeout_minutes:)
    end

    def notify_client_about_takeover
      result = TelegramMessageSender.call(
        chat:,
        text: I18n.t('manager.takeover.client_notification')
      )

      unless result.success?
        log_error(
          StandardError.new("Failed to notify client about takeover: #{result.error}"),
          safe_context.merge(notification_error: result.error)
        )
      end

      result
    end

    def build_success_result(notification_result)
      Result.new(
        success?: true,
        chat: chat.reload,
        active_until: chat.manager_active_until,
        notification_sent: notification_result&.success?
      )
    end

    def safe_context
      {
        service: self.class.name,
        chat_id: chat&.id,
        user_id: user&.id,
        timeout_minutes:
      }
    end

    # Планирует фоновую задачу для автоматического возврата чата боту
    #
    # @return [void]
    def schedule_timeout_job
      ChatTakeoverTimeoutJob
        .set(wait: timeout_minutes.minutes)
        .perform_later(chat.id, chat.taken_at)
    end

    # Отслеживает событие начала takeover
    #
    # @return [void]
    def track_takeover_started
      AnalyticsService.track(
        AnalyticsService::Events::CHAT_TAKEOVER_STARTED,
        tenant: chat.tenant,
        chat_id: chat.id,
        properties: {
          taken_by_id: user.id,
          timeout_minutes: timeout_minutes
        }
      )
    end
  end
end
