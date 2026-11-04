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
  self.enqueue_after_transaction_commit = false

  retry_on StandardError,
           wait: ->(attempt) { attempt**2 + ApplicationConfig.telegram_delivery_retry_seconds },
           attempts: ApplicationConfig.telegram_delivery_attempts do |job, error|
    job.arguments.first.update!(notification_failed_at: Time.current)
    job.log_error(error, job: job.class.name, booking_id: job.arguments.first.id)
    raise error
  end

  # Не ретрить Telegram ошибки - они обычно постоянные (чат не найден, бот заблокирован)
  discard_on Telegram::Bot::Error do |job, error|
    job.arguments.first.update!(notification_failed_at: Time.current)
    job.log_error(error, job: job.class.name, booking_id: job.arguments.first.id)
  end

  rescue_from Telegram::TransientApiError do |error|
    if executions < ApplicationConfig.telegram_delivery_attempts
      delay = [ error.retry_after.to_i, executions**2 + ApplicationConfig.telegram_delivery_retry_seconds ].max
      retry_job wait: delay.seconds
    else
      arguments.first.update!(notification_failed_at: Time.current)
      log_error(error, job: self.class.name, booking_id: arguments.first.id)
      raise error
    end
  end

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

    unless tenant.admin_chat_id.present?
      Rails.logger.info("[BookingNotificationJob] Skipping: admin_chat_id not configured for tenant #{tenant.id}")
      return
    end

    # Используем Telegram API для отправки сообщения в менеджерский чат
    booking.with_lock do
      return if booking.notified_at?

      tenant.bot_client.send_message(chat_id: tenant.admin_chat_id, text: booking.details)
      booking.update!(notified_at: Time.current, notification_failed_at: nil)
    end
  rescue Telegram::Bot::Error => e
    log_error(e,
              job: self.class.name,
              booking_id: booking.id,
              tenant_id: booking.tenant_id)
    raise e
  end
end
