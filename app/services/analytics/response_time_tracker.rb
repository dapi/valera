# Сервис для отслеживания времени ответа AI
#
# Измеряет производительность AI ответов и собирает метрики
# для анализа производительности системы
module Analytics
  class ResponseTimeTracker
    include ErrorLogger

    class << self
      # Измеряет время выполнения блока и трекирует его
      #
      # @param chat_id [Integer] ID чата
      # @param operation [String] Тип операции
      # @param model_used [String] Используемая модель
      # @yield Блок кода для измерения времени выполнения
      # @return [Object] Результат выполнения блока
      def measure(chat_id, operation, model_used = 'deepseek-chat')
        start_time = Time.current

        result = yield

        duration_ms = ((Time.current - start_time) * 1000).to_i

        # Track response time
        AnalyticsService.track_response_time(chat_id, duration_ms, model_used)

        # Log slow responses
        if duration_ms > 3000 # > 3 seconds
          Rails.logger.warn "Slow AI response detected: #{duration_ms}ms for #{operation}"
        end

        result
      rescue => e
        duration_ms = ((Time.current - start_time) * 1000).to_i

        # Track error timing
        AnalyticsService.track_error(e, {
          chat_id: chat_id,
          context: operation,
          duration_ms: duration_ms,
          model_used: model_used
        })

        raise e
      end
    end
  end
end
