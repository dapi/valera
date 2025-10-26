# Резервный сервис хранения событий при проблемах с базой данных
#
# Используется для хранения критических событий когда основная база данных недоступна
module Analytics
  class FallbackService
    class << self
      # Сохранение события в резервное хранилище
      #
      # @param event_data [Hash] Данные события
      def store_event(event_data)
        # Пока реализуем простое логирование
        # В будущем можно добавить file storage или Redis
        Rails.logger.error "Analytics fallback: #{event_data.to_json}"
      end
    end
  end
end