class Booking < ApplicationRecord
  belongs_to :telegram_user
  belongs_to :chat, optional: true

  # Валидации согласно TDD-002b
  validates :telegram_user, presence: true
  validate :validate_meta_data

  # Scope для получения предстоящих записей
  scope :upcoming, -> { where('created_at > ?', 1.day.ago) }
  scope :recent, -> { order(created_at: :desc) }

  # Вспомогательные методы для доступа к данным из meta
  def customer_name
    meta['customer_name']
  end

  def customer_phone
    meta['customer_phone']
  end

  def car_info
    meta['car_info']
  end

  def preferred_date
    meta['preferred_date']
  end

  def preferred_time
    meta['preferred_time']
  end

  def scheduled_at
    meta['scheduled_at']
  end

  private

  def validate_meta_data
    # Проверяем обязательные поля в meta
    errors.add(:meta, 'должно содержать имя клиента') if customer_name.blank?
    errors.add(:meta, 'должно содержать телефон клиента') if customer_phone.blank?
    errors.add(:meta, 'должно содержать информацию об автомобиле') if car_info.blank?

    # Валидация формата телефона - более гибкая
    if customer_phone.present? && customer_phone.gsub(/\D/, '').length < 10
      errors.add(:meta, 'телефон клиента должен содержать минимум 10 цифр')
    end
  end
end
