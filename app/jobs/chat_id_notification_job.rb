# frozen_string_literal: true

# Job для отправки уведомления с chat_id при добавлении бота в группу
#
# Асинхронно отправляет chat_id группы, в которую был добавлен бот,
# чтобы владельцы автосервиса могли настроить работу с чатом.
#
# @example Использование задачи
#   ChatIdNotificationJob.perform_later(chat_id)
#   #=> Уведомление будет отправлено асинхронно
#
# @see ApplicationConfig для настройки bot_token
# @author AI Assistant
# @since 1.0.0
class ChatIdNotificationJob < ApplicationJob
  include ErrorLogger

  queue_as :default

  # Выполняет отправку уведомления с chat_id в чат
  #
  # @param chat_id [Integer] ID чата, куда отправить уведомление
  # @return [void] отправляет сообщение с chat_id в чат
  # @raise [StandardError] при ошибке отправки (с retry логикой)
  # @note Пропускает отправку если chat_id не задан
  # @example
  #   ChatIdNotificationJob.perform_later(-1001234567890)
  #   #=> Уведомление с chat_id будет отправлено асинхронно
  def perform(chat_id)
    return if chat_id.blank?

    chat = Chat.find chat_id
    # Используем Telegram API для отправки сообщения в чат
    chat.tenant.bot_client.send_message(
      chat_id: chat_id,
      text: I18n.t('chat_id_notification.message', chat_id: chat_id),
      parse_mode: 'Markdown'
    )
  rescue StandardError => e
    log_error(e,
              job: self.class.name,
              chat_id: chat_id)
    raise e
  end
end
