# frozen_string_literal: true

# Сервис для управления перехватом чата менеджером
#
# Обеспечивает takeover (перехват) и release (возврат) чата между
# AI-ботом и менеджером с уведомлением клиента через Telegram.
#
# @example Перехват чата
#   service = ChatTakeoverService.new(chat)
#   service.takeover!(current_user)
#
# @example Возврат чата боту
#   service.release!
#
# @example Автоматический возврат по таймауту
#   service.release!(timeout: true)
#
# @see ChatTakeoverTimeoutJob для автоматического таймаута
# @see Chat#mode для состояния чата
# @author Danil Pismenny
# @since 0.38.0
class ChatTakeoverService
  include ErrorLogger

  # Сообщения для уведомления клиента о смене режима
  NOTIFICATION_MESSAGES = {
    takeover: 'Вас переключили на менеджера. Сейчас с вами общается живой оператор.',
    release: 'Спасибо за обращение! Если будут вопросы — AI-ассистент всегда на связи.',
    timeout: 'Менеджер сейчас недоступен. AI-ассистент снова на связи!'
  }.freeze

  # Ошибка при попытке перехватить уже перехваченный чат
  class AlreadyTakenError < StandardError
    def initialize(msg = 'Chat is already in manager mode')
      super
    end
  end

  # Ошибка при попытке вернуть неперехваченный чат
  class NotTakenError < StandardError
    def initialize(msg = 'Chat is not in manager mode')
      super
    end
  end

  # Ошибка валидации состояния
  class ValidationError < StandardError; end

  # Результат операции takeover
  TakeoverResult = Struct.new(:chat, :notification_sent, keyword_init: true)

  # @param chat [Chat] чат для управления
  def initialize(chat)
    @chat = chat || raise('No chat')
  end

  # Перехватывает чат для менеджера
  #
  # @param user [User] менеджер, берущий чат
  # @param timeout_minutes [Integer, nil] кастомный таймаут в минутах
  # @param notify_client [Boolean] отправлять ли уведомление клиенту
  # @return [TakeoverResult] результат с чатом и статусом уведомления
  # @raise [AlreadyTakenError] если чат уже в режиме менеджера
  def takeover!(user, timeout_minutes: nil, notify_client: true)
    timeout = (timeout_minutes || ApplicationConfig.manager_takeover_timeout_minutes).minutes

    chat.with_lock do
      chat.reload
      raise AlreadyTakenError if chat.manager_mode?

      chat.update!(
        mode: :manager_mode,
        taken_by: user,
        taken_at: Time.current,
        manager_active_until: Time.current + timeout
      )

      schedule_timeout(timeout)
    end

    notification_sent = notify_client ? send_notification(:takeover) : nil
    track_takeover_started(user, timeout_minutes: timeout_minutes || ApplicationConfig.manager_takeover_timeout_minutes)

    TakeoverResult.new(chat: chat, notification_sent: notification_sent)
  end

  # Возвращает чат боту
  #
  # @param timeout [Boolean] true если возврат по таймауту
  # @return [Chat] обновлённый чат
  # @raise [NotTakenError] если чат не в режиме менеджера
  def release!(timeout: false)
    raise NotTakenError unless chat.manager_mode?

    user = chat.taken_by
    duration = Time.current - chat.taken_at if chat.taken_at

    chat.with_lock do
      chat.update!(
        mode: :ai_mode,
        taken_by: nil,
        taken_at: nil,
        manager_active_until: nil
      )
    end

    send_notification(timeout ? :timeout : :release)
    track_takeover_ended(user, timeout:, duration:)

    chat
  end

  private

  attr_reader :chat

  # Отправляет уведомление клиенту в Telegram
  #
  # @param type [Symbol] тип уведомления (:takeover, :release, :timeout)
  # @return [Boolean] true если уведомление отправлено успешно
  # @note TelegramMessageSender уже обрабатывает ошибки Telegram API gracefully
  #   и возвращает Result(success?: false). Программные ошибки должны
  #   пробрасываться наверх согласно CLAUDE.md guidelines.
  def send_notification(type)
    message = NOTIFICATION_MESSAGES[type]

    result = Manager::TelegramMessageSender.call(chat:, text: message)

    # TelegramMessageSender уже логирует ошибки в Bugsnag с полным контекстом.
    # Здесь только debug для локальной отладки без дублирования в production.
    unless result.success?
      Rails.logger.debug(
        "[#{self.class.name}] Notification #{type} for chat #{chat.id} failed: #{result.error}"
      )
    end

    result.success?
  end

  # Планирует автоматический возврат боту по таймауту
  #
  # @param timeout [ActiveSupport::Duration] длительность таймаута
  # @return [void]
  def schedule_timeout(timeout)
    ChatTakeoverTimeoutJob
      .set(wait: timeout)
      .perform_later(chat.id, chat.taken_at.to_i)
  end

  # Отслеживает начало takeover
  #
  # @param user [User] менеджер
  # @param timeout_minutes [Integer] таймаут в минутах
  # @return [void]
  def track_takeover_started(user, timeout_minutes:)
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

  # Отслеживает окончание takeover
  #
  # @param user [User] менеджер, который владел чатом
  # @param timeout [Boolean] по таймауту ли
  # @param duration [Float, nil] длительность сессии в секундах
  # @return [void]
  def track_takeover_ended(user, timeout:, duration:)
    AnalyticsService.track(
      AnalyticsService::Events::CHAT_TAKEOVER_ENDED,
      tenant: chat.tenant,
      chat_id: chat.id,
      properties: {
        taken_by_id: user&.id,
        released_by_id: timeout ? nil : user&.id,
        reason: timeout ? 'timeout' : 'manual',
        duration_minutes: duration ? (duration / 60.0).round(1) : nil
      }
    )
  end
end
