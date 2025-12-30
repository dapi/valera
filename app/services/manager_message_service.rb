# frozen_string_literal: true

# Сервис для отправки сообщений менеджером клиенту
#
# Позволяет менеджеру отправлять сообщения клиенту через Telegram
# в режиме takeover (когда AI-бот отключен).
#
# @example Отправка сообщения
#   service = ManagerMessageService.new(chat)
#   message = service.send!(user, "Здравствуйте!")
#
# @see Chat модель чата
# @see Message модель сообщения
# @author Danil Pismenny
# @since 0.1.0
class ManagerMessageService
  include ErrorLogger

  # Ограничения
  MAX_MESSAGES_PER_HOUR = 60

  # Ошибки сервиса
  class NotInManagerModeError < StandardError; end
  class NotTakenByUserError < StandardError; end
  class RateLimitExceededError < StandardError; end

  # @param chat [Chat] чат для отправки сообщения
  def initialize(chat)
    @chat = chat
  end

  # Отправляет сообщение от менеджера клиенту
  #
  # @param user [User] менеджер, отправляющий сообщение
  # @param text [String] текст сообщения
  # @return [Message] созданное сообщение
  # @raise [NotInManagerModeError] если чат не в manager_mode
  # @raise [NotTakenByUserError] если чат перехвачен другим пользователем
  # @raise [RateLimitExceededError] если превышен лимит сообщений
  def send!(user, text)
    validate_send_conditions!(user)

    # Отправка в Telegram
    chat.tenant.bot_client.send_message(
      chat_id: chat.telegram_user.telegram_id,
      text: text
    )

    # Сохранение сообщения
    message = chat.messages.create!(
      role: :assistant,
      content: text,
      sender_type: :manager,
      sender: user
    )

    # Продление таймаута при активности
    refresh_takeover_timeout

    # Рассылка обновления через Turbo Streams
    broadcast_new_message(message)

    message
  rescue StandardError => e
    log_error(e, context: { chat_id: chat.id, user_id: user&.id, operation: 'send_message' })
    raise
  end

  private

  attr_reader :chat

  # Валидирует условия для отправки сообщения
  #
  # @param user [User] пользователь
  # @raise [NotInManagerModeError] если чат не в manager_mode
  # @raise [NotTakenByUserError] если чат перехвачен другим пользователем
  # @raise [RateLimitExceededError] если превышен лимит
  def validate_send_conditions!(user)
    raise NotInManagerModeError, 'Сначала перехватите диалог' unless chat.manager_mode?
    raise NotTakenByUserError, 'Диалог перехвачен другим менеджером' unless chat.taken_by == user
    raise RateLimitExceededError, 'Превышен лимит сообщений (60/час)' if rate_limited?(user)
  end

  # Проверяет rate limit для пользователя
  #
  # @param user [User] пользователь
  # @return [Boolean] true если превышен лимит
  def rate_limited?(user)
    recent_messages_count = chat.messages
                                .where(sender: user, sender_type: :manager)
                                .where('created_at > ?', 1.hour.ago)
                                .count

    recent_messages_count >= MAX_MESSAGES_PER_HOUR
  end

  # Продлевает таймаут takeover
  #
  # @return [void]
  def refresh_takeover_timeout
    ChatTakeoverService.new(chat).extend_timeout!
  end

  # Рассылает новое сообщение через Turbo Streams
  #
  # @param message [Message] созданное сообщение
  # @return [void]
  def broadcast_new_message(message)
    Turbo::StreamsChannel.broadcast_append_to(
      "tenant_#{chat.tenant_id}_chat_#{chat.id}",
      target: 'chat_messages',
      partial: 'tenants/chats/message',
      locals: { message: message }
    )
  end
end
