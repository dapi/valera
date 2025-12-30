# frozen_string_literal: true

# Сервис для управления перехватом диалога менеджером
#
# Позволяет менеджеру "перехватить" чат у AI-бота,
# отвечать клиенту напрямую и возвращать диалог боту.
#
# @example Перехват диалога
#   service = ChatTakeoverService.new(chat)
#   service.takeover!(user)
#
# @example Возврат диалога боту
#   service = ChatTakeoverService.new(chat)
#   service.release!
#
# @see Chat модель чата
# @see User модель пользователя
# @author Danil Pismenny
# @since 0.1.0
class ChatTakeoverService
  include ErrorLogger

  # Время неактивности менеджера до автоматического возврата диалога боту
  TIMEOUT_DURATION = 30.minutes

  # Шаблоны уведомлений клиенту
  NOTIFICATION_MESSAGES = {
    takeover: 'Вас переключили на менеджера. Сейчас с вами общается %<name>s',
    release: 'Спасибо за обращение! Если будут вопросы — AI-ассистент всегда на связи',
    timeout: 'Менеджер сейчас недоступен. AI-ассистент снова на связи!'
  }.freeze

  # Ошибки сервиса
  class AlreadyTakenError < StandardError; end
  class NotTakenError < StandardError; end
  class UnauthorizedError < StandardError; end

  # @param chat [Chat] чат для управления
  def initialize(chat)
    @chat = chat
  end

  # Перехватывает диалог от бота
  #
  # @param user [User] пользователь, перехватывающий диалог
  # @return [Chat] обновлённый чат
  # @raise [AlreadyTakenError] если чат уже в manager_mode
  # @raise [UnauthorizedError] если пользователь не имеет доступа к tenant'у
  def takeover!(user)
    raise AlreadyTakenError, 'Диалог уже перехвачен' if chat.manager_mode?
    raise UnauthorizedError, 'Нет доступа к этому чату' unless user.has_access_to?(chat.tenant)

    ActiveRecord::Base.transaction do
      chat.update!(
        mode: :manager_mode,
        taken_by: user,
        taken_at: Time.current
      )

      notify_client(:takeover, name: user.display_name)
      schedule_timeout
    end

    broadcast_state_change
    chat
  rescue StandardError => e
    log_error(e, context: { chat_id: chat.id, user_id: user&.id, operation: 'takeover' })
    raise
  end

  # Возвращает диалог боту
  #
  # @param timeout [Boolean] true если вызвано по таймауту
  # @param user [User, nil] пользователь, возвращающий диалог (nil для timeout/system)
  # @return [Chat] обновлённый чат
  # @raise [NotTakenError] если чат не в manager_mode
  # @raise [UnauthorizedError] если user не тот кто перехватил и не админ
  def release!(timeout: false, user: nil)
    raise NotTakenError, 'Диалог не был перехвачен' unless chat.manager_mode?

    # Проверка авторизации (пропускаем для timeout и system вызовов)
    if user && !timeout
      unless user == chat.taken_by || can_force_release?(user)
        raise UnauthorizedError, 'Только перехвативший менеджер или админ может вернуть диалог'
      end
    end

    ActiveRecord::Base.transaction do
      chat.update!(
        mode: :ai_mode,
        taken_by: nil,
        taken_at: nil
      )

      notify_client(timeout ? :timeout : :release)
    end

    broadcast_state_change
    chat
  rescue StandardError => e
    log_error(e, context: { chat_id: chat.id, operation: 'release', timeout: timeout })
    raise
  end

  # Продлевает таймаут takeover (при активности менеджера)
  #
  # @return [void]
  def extend_timeout!
    return unless chat.manager_mode?

    chat.update!(taken_at: Time.current)
    schedule_timeout
  end

  private

  attr_reader :chat

  # Проверяет может ли пользователь принудительно вернуть чат боту
  # (owner tenant'а или admin membership)
  #
  # @param user [User]
  # @return [Boolean]
  def can_force_release?(user)
    user.owner_of?(chat.tenant) || user.membership_for(chat.tenant)&.admin?
  end

  # Отправляет уведомление клиенту в Telegram
  #
  # Разделяет Telegram API вызов и сохранение в БД:
  # - Telegram ошибки логируются, но не прерывают операцию
  # - DB ошибки пробрасываются для отката транзакции
  #
  # @param type [Symbol] тип уведомления (:takeover, :release, :timeout)
  # @param params [Hash] параметры для интерполяции
  # @return [void]
  def notify_client(type, **params)
    message_text = format(NOTIFICATION_MESSAGES[type], **params)

    # Отправка в Telegram (внешний API - ошибки не критичны)
    send_telegram_notification(message_text)

    # Сохранение как системное сообщение (DB - ошибки критичны, откатят транзакцию)
    chat.messages.create!(
      role: :assistant,
      content: message_text,
      sender_type: :system
    )
  end

  # Отправляет сообщение в Telegram
  #
  # @param text [String] текст сообщения
  # @return [void]
  # @note Ошибки Telegram API логируются, но не прерывают операцию
  def send_telegram_notification(text)
    chat.tenant.bot_client.send_message(
      chat_id: chat.telegram_user.telegram_id,
      text: text
    )
  rescue Telegram::Bot::Error => e
    # Telegram API недоступен - логируем, но продолжаем
    log_error(e, context: { chat_id: chat.id, operation: 'telegram_notification' })
  rescue Faraday::Error => e
    # Сетевые ошибки - логируем, но продолжаем
    log_error(e, context: { chat_id: chat.id, operation: 'telegram_notification' })
  end

  # Планирует автоматический возврат диалога боту
  #
  # @return [void]
  def schedule_timeout
    ChatTakeoverTimeoutJob
      .set(wait: TIMEOUT_DURATION)
      .perform_later(chat.id, chat.taken_at.to_i)
  end

  # Рассылает обновление состояния через Turbo Streams
  #
  # @return [void]
  def broadcast_state_change
    Turbo::StreamsChannel.broadcast_replace_to(
      "tenant_#{chat.tenant_id}_chats",
      target: "chat_#{chat.id}_status",
      partial: 'tenants/chats/status',
      locals: { chat: chat }
    )
  end
end
