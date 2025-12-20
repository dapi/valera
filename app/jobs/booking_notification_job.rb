# frozen_string_literal: true

# Фоновая задача для отправки уведомлений о новых заявках
#
# Асинхронно отправляет детали созданных заявок в административный чат
# Telegram для обработки менеджерами.
#
# Использует tenant.admin_chat_id и tenant.bot_client для отправки
# через правильного бота тенанта.
#
# @example Использование задачи
#   BookingNotificationJob.perform_later(booking)
#   #=> Уведомление будет отправлено асинхронно
#
# @see Booking для модели заявки
# @see Tenant для настроек admin_chat_id и bot_token
# @author Danil Pismenny
# @since 0.1.0
class BookingNotificationJob < ApplicationJob
  include ErrorLogger

  queue_as :default

  # Выполняет отправку уведомления о новой заявке
  #
  # @param booking [Booking] созданная заявка для уведомления
  # @return [void] отправляет сообщение в административный чат
  # @raise [StandardError] при ошибке отправки (с retry логикой)
  # @example
  #   BookingNotificationJob.perform_later(booking)
  #   #=> Уведомление будет отправлено асинхронно
  def perform(booking)
    tenant = booking.tenant

    # Используем Telegram API для отправки сообщения в менеджерский чат
    tenant.bot_client.send_message(
      chat_id: tenant.admin_chat_id,
      text: booking.details
    )
  rescue StandardError => e
    log_error(e,
              job: self.class.name,
              booking_id: booking.id,
              tenant_id: booking.tenant_id)
    raise e
  end
end
