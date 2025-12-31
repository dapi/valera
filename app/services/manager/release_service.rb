# frozen_string_literal: true

module Manager
  # Сервис для возврата чата боту
  #
  # Переводит чат обратно в режим бота и опционально уведомляет клиента
  # о том, что его переключили обратно на AI-ассистента.
  #
  # @example Возврат чата боту
  #   result = Manager::ReleaseService.call(chat: chat, user: current_user)
  #   if result.success?
  #     puts "Чат возвращён боту"
  #   end
  #
  # @since 0.38.0
  class ReleaseService
    include ErrorLogger

    # Ошибки которые мы обрабатываем gracefully
    HANDLED_ERRORS = [
      ActiveRecord::RecordInvalid,
      ActiveRecord::RecordNotSaved
    ].freeze

    # Ошибка валидации входных параметров сервиса
    class ValidationError < StandardError; end

    # @return [Chat] чат для возврата
    attr_reader :chat

    # @return [User, nil] менеджер, возвращающий чат (опционально для валидации)
    attr_reader :user

    # @return [Boolean] отправлять ли уведомление клиенту
    attr_reader :notify_client

    Result = Struct.new(:success?, :chat, :notification_sent, :error, keyword_init: true)

    # Фабричный метод для создания и выполнения сервиса
    #
    # @param chat [Chat] чат для возврата
    # @param user [User, nil] менеджер (для валидации прав)
    # @param notify_client [Boolean] уведомлять ли клиента
    # @return [Result] результат операции
    def self.call(chat:, user: nil, notify_client: true)
      new(chat:, user:, notify_client:).call
    end

    # @param chat [Chat] чат для возврата
    # @param user [User, nil] менеджер
    # @param notify_client [Boolean] уведомлять ли клиента
    def initialize(chat:, user: nil, notify_client: true)
      @chat = chat
      @user = user
      @notify_client = notify_client
    end

    # Выполняет возврат чата боту
    #
    # @return [Result] результат операции
    def call
      validate!

      # Сохраняем данные ДО release, так как после release они будут nil
      taken_by_id = chat.taken_by_id
      taken_at = chat.taken_at

      notification_result = (notify_client && chat.manager_mode?) ? notify_client_about_release : nil
      release_chat
      track_manual_release(taken_by_id:, taken_at:)
      build_success_result(notification_result)
    rescue ValidationError => e
      Rails.logger.warn("[#{self.class.name}] Validation failed: #{e.message}")
      Result.new(success?: false, error: e.message)
    rescue *HANDLED_ERRORS => e
      log_error(e, safe_context)
      Result.new(success?: false, error: e.message)
    end

    private

    def validate!
      raise ValidationError, 'Chat is required' if chat.nil?
      raise ValidationError, 'Chat is not in manager mode' unless chat.manager_mode?

      # Если передан user, проверяем что это активный менеджер или админ
      return unless user.present?
      return if user_can_release?

      raise ValidationError, 'User is not authorized to release this chat'
    end

    def user_can_release?
      # Активный менеджер может вернуть свой чат
      chat.taken_by_id == user.id
      # TODO: добавить проверку админских прав когда будет система ролей
    end

    def notify_client_about_release
      result = TelegramMessageSender.call(
        chat:,
        text: I18n.t('manager.release.client_notification')
      )

      unless result.success?
        log_error(
          StandardError.new("Failed to notify client about release: #{result.error}"),
          safe_context.merge(notification_error: result.error)
        )
      end

      result
    end

    def release_chat
      chat.release_to_bot!
    end

    def build_success_result(notification_result)
      Result.new(
        success?: true,
        chat: chat.reload,
        notification_sent: notification_result&.success?
      )
    end

    def safe_context
      {
        service: self.class.name,
        chat_id: chat&.id,
        user_id: user&.id
      }
    end

    # Отслеживает событие ручного возврата чата боту
    #
    # @param taken_by_id [Integer] ID менеджера (сохранён до release)
    # @param taken_at [Time] время takeover (сохранено до release)
    # @return [void]
    def track_manual_release(taken_by_id:, taken_at:)
      duration_minutes = calculate_takeover_duration(taken_at)

      AnalyticsService.track(
        AnalyticsService::Events::CHAT_TAKEOVER_ENDED,
        tenant: chat.tenant,
        chat_id: chat.id,
        properties: {
          taken_by_id: taken_by_id,
          released_by_id: user&.id,
          reason: 'manual',
          duration_minutes: duration_minutes
        }
      )
    end

    # Рассчитывает продолжительность takeover в минутах
    #
    # @param taken_at [Time] время начала takeover
    # @return [Integer] продолжительность в минутах
    def calculate_takeover_duration(taken_at)
      return 0 unless taken_at.present?

      ((Time.current - taken_at) / 60).round
    end
  end
end
