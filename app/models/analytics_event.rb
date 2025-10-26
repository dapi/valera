# Модель для хранения аналитических событий
#
# Отвечает за хранение всех событий аналитики системы:
# - Начало диалогов с AI
# - Создание заявок на запись
# - Время ответа AI
# - Ошибки системы
#
# Используется для построения воронок конверсии и анализа производительности
#
# @see FIP-001-analytics-system.md - Feature Implementation Plan
# @see TDD-001-analytics-system.md - Technical Design Document
# @see AnalyticsService - Сервис для трекинга событий
class AnalyticsEvent < ApplicationRecord
  # Validations
  validates :event_name, presence: true, length: { maximum: 50 }
  validates :chat_id, presence: true, numericality: { only_integer: true }
  validates :occurred_at, presence: true

  # Scopes для эффективных запросов
  scope :by_event, ->(event) { where(event_name: event) }
  scope :by_chat, ->(chat_id) { where(chat_id: chat_id) }
  scope :recent, ->(hours = 24) { where('occurred_at >= ?', hours.hours.ago) }
  scope :in_period, ->(start_date, end_date) {
    where(occurred_at: start_date..end_date)
  }

  # JSONB helpers для статистики
  def self.properties_stats(keys = [])
    select("
      event_name,
      COUNT(*) as event_count,
      #{keys.map { |k| "AVG(CAST(properties->>'#{k}' as NUMERIC)) as avg_#{k}" }.join(', ')}
    ").group(:event_name)
  end

  # Воронка конверсии для анализа пользовательского пути
  def self.conversion_funnel(start_date, end_date)
    where(occurred_at: start_date..end_date)
      .group(:chat_id, :event_name)
      .select(
        'chat_id',
        'event_name',
        'MIN(occurred_at) as first_occurrence',
        'COUNT(*) as event_count'
      )
  end
end