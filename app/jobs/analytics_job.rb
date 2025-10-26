# Фоновая задача для обработки аналитических событий
#
# Асинхронно сохраняет аналитические события в базу данных.
# Обеспечивает отказоустойчивость и повторные попытки при ошибках.
#
# @see AnalyticsService - Сервис трекинга событий
# @see AnalyticsEvent - Модель хранения событий
class AnalyticsJob < ApplicationJob
  queue_as :analytics

  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  # Выполнение задачи по сохранению аналитического события
  #
  # @param event_data [Hash] Данные события
  def perform(event_data)
    AnalyticsEvent.create!(
      event_name: event_data[:event_name],
      chat_id: event_data[:chat_id],
      properties: event_data[:properties],
      occurred_at: event_data[:occurred_at],
      session_id: event_data[:session_id]
    )

    # Optional: Real-time alerts for critical events
    Analytics::AlertService.check_event(event_data) if critical_event?(event_data[:event_name])
  rescue => e
    # Use database connection fallback for critical events
    Analytics::FallbackService.store_event(event_data) if should_fallback?(e)
    raise e
  end

  private

  # Проверка является ли событие критическим
  #
   # @param event_name [String] Тип события
   # @return [Boolean] true если событие критическое
  def critical_event?(event_name)
    [
      AnalyticsService::Events::BOOKING_CREATED,
      AnalyticsService::Events::ERROR_OCCURRED
    ].include?(event_name)
  end

  # Проверка необходимости использования резервного хранения
  #
  # @param error [Exception] Ошибка
  # @return [Boolean] true если нужно использовать fallback
  def should_fallback?(error)
    error.is_a?(ActiveRecord::ConnectionNotEstablished) ||
    error.is_a?(ActiveRecord::StatementInvalid)
  end
end