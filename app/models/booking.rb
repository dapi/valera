# frozen_string_literal: true

# Модель заявки на автосервис
#
# Представляет заявку на обслуживание, созданную пользователем через чат.
# Связывает tenant, client, чат и детали заявки, отправляет уведомления.
#
# @attr [Integer] tenant_id ID арендатора (автосервиса)
# @attr [Integer] client_id ID клиента
# @attr [Integer] chat_id ID чата
# @attr [Integer] vehicle_id ID автомобиля (опционально)
# @attr [Hash] meta метаданные заявки (данные клиента, авто, услуги)
# @attr [String] details детали заявки в формате Markdown
# @attr [Hash] context контекст диалога
# @attr [DateTime] created_at время создания
# @attr [DateTime] updated_at время обновления
#
# @example Создание новой заявки
#   booking = Booking.create!(
#     tenant: tenant,
#     client: client,
#     chat: chat,
#     meta: { customer_name: "Иван", car_brand: "Toyota" },
#     details: "Заявка на ТО для Toyota Camry",
#     context: { date: "2024-12-01" }
#   )
#
# @see BookingTool для создания заявок
# @see BookingNotificationJob для отправки уведомлений
# @author Danil Pismenny
# @since 0.1.0
class Booking < ApplicationRecord
  belongs_to :chat
  belongs_to :tenant, counter_cache: true
  belongs_to :client
  belongs_to :vehicle, optional: true

  has_one :telegram_user, through: :client

  # Сортирует заявки по времени создания (новые первые)
  scope :recent, -> { order(created_at: :desc) }

  # Отправляет уведомление о новой заявке в административный чат
  #
  # @return [void]
  # @note Выполняется асинхронно через BookingNotificationJob
  # @see BookingNotificationJob для логики отправки
  after_commit on: :create do
    BookingNotificationJob.perform_later(self)
  end
end
