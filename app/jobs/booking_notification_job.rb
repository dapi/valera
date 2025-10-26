# frozen_string_literal: true

# Job для асинхронной отправки уведомлений о новых заявках в менеджерский чат
class BookingNotificationJob < ApplicationJob
  include ErrorLogger
  queue_as :default

  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform(booking)
    unless ApplicationConfig.admin_chat_id.present?
      Rails.logger.warn("Так как admin_chat_id не установлен - пропускаю уведомления админов")
      return
    end

    # Используем Telegram API для отправки сообщения в менеджерский чат
    Telegram.bot.send_message(
      chat_id: ApplicationConfig.admin_chat_id,
      text: booking.details,
      parse_mode: 'Markdown'
    )
  rescue => e
    log_error(e, {
      job: self.class.name,
      booking_id: booking.id
    })
    raise e
  end
end
