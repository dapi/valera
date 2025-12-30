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
  # @author AI Assistant
  # @since 0.38.0
  class ReleaseService
    include ErrorLogger

    # Ошибки которые мы обрабатываем gracefully
    HANDLED_ERRORS = [
      ActiveRecord::RecordInvalid,
      ActiveRecord::RecordNotSaved
    ].freeze

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
      notification_result = (notify_client && chat.manager_mode?) ? notify_client_about_release : nil
      release_chat
      build_success_result(notification_result)
    rescue ArgumentError => e
      Result.new(success?: false, error: e.message)
    rescue *HANDLED_ERRORS => e
      log_error(e, safe_context)
      Result.new(success?: false, error: e.message)
    end

    private

    def validate!
      raise ArgumentError, 'Chat is required' if chat.nil?

      # Если передан user, проверяем что это активный менеджер или админ
      return unless user.present? && chat.manager_mode?
      return if user_can_release?

      raise ArgumentError, 'User is not authorized to release this chat'
    end

    def user_can_release?
      # Активный менеджер может вернуть свой чат
      chat.manager_user_id == user.id
      # TODO: добавить проверку админских прав когда будет система ролей
    end

    def notify_client_about_release
      TelegramMessageSender.call(
        chat:,
        text: I18n.t('manager.release.client_notification')
      )
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
  end
end
