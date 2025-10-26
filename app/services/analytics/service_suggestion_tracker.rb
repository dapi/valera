# Сервис для отслеживания предложений услуг AI
#
# Собирает данные о том, какие услуги предлагает AI и как пользователи
# на них реагируют. Используется для анализа качества AI рекомендаций
module Analytics
  class ServiceSuggestionTracker
    include ErrorLogger

    class << self
      # Трекинг предложения услуги от AI
      #
      # @param chat_id [Integer] ID чата
      # @param service_name [String] Название услуги
      # @param confidence_score [Float] Уверенность AI в предложении
      # @param context [Hash] Контекст предложения
      def track_suggestion(chat_id, service_name, confidence_score, context = {})
        AnalyticsService.track(
          AnalyticsService::Events::SERVICE_SUGGESTED,
          chat_id: chat_id,
          properties: {
            service_name: service_name,
            confidence_score: confidence_score,
            suggestion_type: 'ai_generated',
            context: context[:context] || 'consultation',
            user_intent: context[:user_intent] || 'unknown',
            timestamp: Time.current.to_f
          }
        )
      end

      # Трекинг принятия предложения услуги
      #
      # @param chat_id [Integer] ID чата
      # @param service_name [String] Название услуги
      # @param booking_id [Integer] ID созданной заявки
      def track_acceptance(chat_id, service_name, booking_id = nil)
        AnalyticsService.track(
          AnalyticsService::Events::SUGGESTION_ACCEPTED,
          chat_id: chat_id,
          properties: {
            service_name: service_name,
            booking_id: booking_id,
            acceptance_type: booking_id ? 'booking_created' : 'verbal_acceptance',
            timestamp: Time.current.to_f
          }
        )
      end

      # Трекинг добавления услуги в корзину/заявку
      #
      # @param chat_id [Integer] ID чата
      # @param service_name [String] Название услуги
      # @param quantity [Integer] Количество (по умолчанию 1)
      # @param price [Float] Цена услуги
      def track_service_added(chat_id, service_name, quantity = 1, price = nil)
        AnalyticsService.track(
          AnalyticsService::Events::SERVICE_ADDED,
          chat_id: chat_id,
          properties: {
            service_name: service_name,
            quantity: quantity,
            price: price,
            total_price: quantity * (price || 0),
            timestamp: Time.current.to_f
          }
        )
      end

      # Трекинг подтверждения корзины/заказа
      #
      # @param chat_id [Integer] ID чата
      # @param services_count [Integer] Количество услуг
      # @param total_amount [Float] Общая сумма
      def track_cart_confirmation(chat_id, services_count, total_amount)
        AnalyticsService.track(
          AnalyticsService::Events::CART_CONFIRMED,
          chat_id: chat_id,
          properties: {
            services_count: services_count,
            total_amount: total_amount,
            confirmation_type: 'booking_confirmed',
            timestamp: Time.current.to_f
          }
        )
      end

      # Анализ эффективности предложений услуг
      #
      # @param period [Integer] Период анализа в днях
      # @return [Hash] Статистика эффективности
      def suggestion_effectiveness(period = 7)
        end_date = Time.current
        start_date = period.days.ago

        suggestions = AnalyticsEvent
          .by_event(AnalyticsService::Events::SERVICE_SUGGESTED)
          .in_period(start_date, end_date)

        acceptances = AnalyticsEvent
          .by_event(AnalyticsService::Events::SUGGESTION_ACCEPTED)
          .in_period(start_date, end_date)

        {
          total_suggestions: suggestions.count,
          total_acceptances: acceptances.count,
          acceptance_rate: suggestions.count > 0 ? (acceptances.count.to_f / suggestions.count * 100).round(2) : 0,
          period_days: period,
          top_services: top_suggested_services(suggestions),
          average_confidence: average_confidence_score(suggestions)
        }
      end

      private

      # Топ предлагаемых услуг
      #
      # @param suggestions [ActiveRecord::Relation] Предложения услуг
      # @return [Array] Топ услуг
      def top_suggested_services(suggestions)
        services = Hash.new(0)

        suggestions.each do |suggestion|
          service_name = suggestion.properties['service_name']
          services[service_name] += 1 if service_name
        end

        services.sort_by { |_, count| -count }.first(5)
      end

      # Средняя уверенность AI в предложениях
      #
      # @param suggestions [ActiveRecord::Relation] Предложения услуг
      # @return [Float] Средняя уверенность
      def average_confidence_score(suggestions)
        return 0.0 if suggestions.empty?

        total_confidence = suggestions.sum do |suggestion|
          suggestion.properties['confidence_score'] || 0.0
        end

        (total_confidence / suggestions.count).round(3)
      end
    end
  end
end
