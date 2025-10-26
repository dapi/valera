# frozen_string_literal: true

# Фоновая задача для отправки уведомлений о новых заявках
#
# Асинхронно отправляет детали созданных заявок в административный чат
# Telegram для обработки менеджерами.
#
# @example Использование задачи
#   BookingNotificationJob.perform_later(booking)
#   #=> Уведомление будет отправлено асинхронно
#
# @see Booking для модели заявки
# @see ApplicationConfig для настройки admin_chat_id
# @see MarkdownCleaner для очистки форматирования
# @author Danil Pismenny
# @since 0.1.0
class BookingNotificationJob < ApplicationJob
  include ErrorLogger

  queue_as :default

  # Повторяет выполнение при стандартных ошибках
  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  # Выполняет отправку уведомления о новой заявке
  #
  # @param booking [Booking] созданная заявка для уведомления
  # @return [void] отправляет сообщение в административный чат
  # @raise [StandardError] при ошибке отправки (с retry логикой)
  # @note Пропускает отправку если admin_chat_id не настроен
  # @example
  #   BookingNotificationJob.perform_later(booking)
  #   #=> Уведомление будет отправлено асинхронно
  def perform(booking)
    if ApplicationConfig.admin_chat_id.blank?
      Rails.logger.warn('Так как admin_chat_id не установлен - пропускаю уведомления админов')
      return
    end

    # Используем Telegram API для отправки сообщения в менеджерский чат
    Telegram.bot.send_message(
      chat_id: ApplicationConfig.admin_chat_id,
      text: MarkdownCleaner.clean(booking.details),
      parse_mode: 'Markdown'
    )
  rescue StandardError => e
    log_error(e,
              job: self.class.name,
              booking_id: booking.id)
    raise e
  end
end
