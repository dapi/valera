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
# @attr [Integer] number порядковый номер заявки внутри тенанта (начинается с 1)
# @attr [String] public_number публичный номер формата "{tenant_id}-{number}"
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
  belongs_to :chat, counter_cache: true
  belongs_to :tenant, counter_cache: true
  belongs_to :client
  belongs_to :vehicle, optional: true

  has_one :telegram_user, through: :client

  # Сортирует заявки по времени создания (новые первые)
  scope :recent, -> { order(created_at: :desc) }

  before_create :set_booking_numbers
  after_create :update_chat_booking_timestamps

  # Находит заявку по публичному номеру (формат: "{tenant_id}-{number}")
  #
  # @param public_number [String] публичный номер заявки
  # @return [Booking, nil] найденная заявка или nil
  # @example
  #   Booking.find_by_public_number("5-42") # => Booking с tenant_id=5, number=42
  def self.find_by_public_number(public_number)
    parts = public_number.to_s.split('-')
    return nil unless parts.size == 2

    tenant_id, number = parts.map(&:to_i)
    return nil if tenant_id.zero? || number.zero?

    find_by(tenant_id: tenant_id, number: number)
  end

  # Отправляет уведомление о новой заявке в административный чат
  #
  # @return [void]
  # @note Выполняется асинхронно через BookingNotificationJob
  # @see BookingNotificationJob для логики отправки
  after_commit on: :create do
    BookingNotificationJob.perform_later(self)
  end

  private

  # Устанавливает номер заявки и публичный номер перед созданием
  #
  # Номер вычисляется как максимальный номер в рамках тенанта + 1.
  # При конфликте (race condition) база данных откатит транзакцию
  # благодаря уникальному индексу на (tenant_id, number).
  def set_booking_numbers
    self.number = (tenant.bookings.maximum(:number) || 0) + 1
    self.public_number = "#{tenant_id}-#{number}"
  end

  # Обновляет статистику заявок в связанном чате
  #
  # Устанавливает first_booking_at при создании первой заявки,
  # и всегда обновляет last_booking_at.
  #
  # @return [void]
  # @api private
  def update_chat_booking_timestamps
    chat.update_columns(
      first_booking_at: chat.first_booking_at || created_at,
      last_booking_at: created_at
    )
  end
end
