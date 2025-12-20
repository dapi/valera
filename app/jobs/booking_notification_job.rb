# frozen_string_literal: true

# Фоновая задача для отправки уведомлений о новых заявках
#
# Асинхронно отправляет детали созданных заявок в административный чат
# Telegram для обработки менеджерами.
#
# В multi-tenant режиме использует tenant.admin_chat_id и tenant.bot_token
# для отправки через правильного бота, с fallback на глобальные настройки.
#
# @example Использование задачи
#   BookingNotificationJob.perform_later(booking)
#   #=> Уведомление будет отправлено асинхронно
#
# @see Booking для модели заявки
# @see Tenant для настроек admin_chat_id
# @see ApplicationConfig для глобальной конфигурации
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
  # @note Пропускает отправку если admin_chat_id не настроен
  # @example
  #   BookingNotificationJob.perform_later(booking)
  #   #=> Уведомление будет отправлено асинхронно
  def perform(booking)
    admin_chat_id = resolve_admin_chat_id(booking)

    if admin_chat_id.blank?
      Rails.logger.warn('Так как admin_chat_id не установлен - пропускаю уведомления админов')
      return
    end

    bot_client = resolve_bot_client(booking)

    # Используем Telegram API для отправки сообщения в менеджерский чат
    bot_client.send_message(
      chat_id: admin_chat_id,
      text: booking.details
    )
  rescue StandardError => e
    log_error(e,
              job: self.class.name,
              booking_id: booking.id,
              tenant_id: booking.tenant_id)
    raise e
  end

  private

  # Определяет admin_chat_id для уведомления
  #
  # Приоритет: booking.tenant.admin_chat_id -> ApplicationConfig.admin_chat_id
  #
  # @param booking [Booking] заявка
  # @return [Integer, nil] ID чата для уведомлений
  # @api private
  def resolve_admin_chat_id(booking)
    tenant_chat_id = booking.tenant&.admin_chat_id
    return tenant_chat_id if tenant_chat_id.present?

    ApplicationConfig.admin_chat_id
  end

  # Определяет Telegram Bot клиент для отправки
  #
  # Приоритет: tenant bot -> глобальный Telegram.bot
  #
  # @param booking [Booking] заявка
  # @return [Telegram::Bot::Client] клиент бота
  # @api private
  def resolve_bot_client(booking)
    tenant = booking.tenant
    tenant&.bot_token.present? ? tenant.bot_client : Telegram.bot
  end
end
