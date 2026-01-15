# frozen_string_literal: true

module Manager
  # Сервис для перехвата чата менеджером
  #
  # Делегирует основную логику ChatTakeoverService,
  # добавляя структурированный Result-объект.
  #
  # @example Перехват чата
  #   result = Manager::TakeoverService.call(chat: chat, user: current_user)
  #   if result.success?
  #     puts "Чат перехвачен до #{result.active_until}"
  #   end
  #
  # @see ChatTakeoverService для core логики takeover/release
  # @since 0.38.0
  class TakeoverService
    include ErrorLogger

    # Ошибки которые мы обрабатываем gracefully
    HANDLED_ERRORS = [
      ActiveRecord::RecordInvalid,
      ActiveRecord::RecordNotSaved,
      ChatTakeoverService::AlreadyTakenError,
      ChatTakeoverService::ValidationError
    ].freeze

    # @return [Chat] чат для перехвата
    attr_reader :chat

    # @return [User] менеджер, который берёт чат
    attr_reader :user

    # @return [Boolean] отправлять ли уведомление клиенту
    attr_reader :notify_client

    # @return [Integer, nil] кастомный таймаут в минутах
    attr_reader :timeout_minutes

    Result = Struct.new(:success?, :chat, :active_until, :notification_sent, :error, keyword_init: true)

    # Фабричный метод для создания и выполнения сервиса
    #
    # @param chat [Chat] чат для перехвата
    # @param user [User] менеджер
    # @param timeout_minutes [Integer, nil] кастомный таймаут в минутах
    # @param notify_client [Boolean] уведомлять ли клиента
    # @return [Result] результат операции
    def self.call(chat:, user:, timeout_minutes: nil, notify_client: true)
      new(chat:, user:, timeout_minutes:, notify_client:).call
    end

    # @param chat [Chat] чат для перехвата
    # @param user [User] менеджер
    # @param timeout_minutes [Integer, nil] кастомный таймаут в минутах
    # @param notify_client [Boolean] уведомлять ли клиента
    # @raise [RuntimeError] если chat или user не переданы
    def initialize(chat:, user:, timeout_minutes: nil, notify_client: true)
      @chat = chat || raise('No chat')
      @user = user || raise('No user')
      @timeout_minutes = timeout_minutes
      @notify_client = notify_client
    end

    # Выполняет перехват чата через ChatTakeoverService
    #
    # @return [Result] результат с данными о перехвате
    def call
      takeover_result = ChatTakeoverService.new(chat).takeover!(
        user,
        timeout_minutes: timeout_minutes,
        notify_client: notify_client
      )

      build_success_result(takeover_result)
    rescue *HANDLED_ERRORS => e
      log_error(e, { service: self.class.name, chat_id: chat.id, user_id: user.id })
      Result.new(success?: false, error: e.message)
    end

    private

    def build_success_result(takeover_result)
      Result.new(
        success?: true,
        chat: chat.reload,
        active_until: chat.manager_active_until,
        notification_sent: takeover_result.notification_sent
      )
    end
  end
end
