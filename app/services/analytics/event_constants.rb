# Константы для аналитических событий
#
# Централизованное хранилище названий событий и их описаний
# для обеспечения консистентности в системе аналитики
module Analytics
  module EventConstants
    # Диалоговые события
    DIALOG_STARTED = {
      name: 'ai_dialog_started',
      description: 'Начало диалога с AI ассистентом',
      category: 'dialog',
      properties: [ :platform, :user_id, :message_type ]
    }.freeze

    # События предложений услуг
    SERVICE_SUGGESTED = {
      name: 'service_suggested',
      description: 'AI предложил услугу пользователю',
      category: 'service',
      properties: [ :service_name, :confidence_score, :suggestion_type, :context ]
    }.freeze

    SERVICE_ADDED = {
      name: 'service_added',
      description: 'Пользователь добавил услугу в заявку',
      category: 'service',
      properties: [ :service_name, :quantity, :price, :total_price ]
    }.freeze

    SUGGESTION_ACCEPTED = {
      name: 'ai_suggestion_accepted',
      description: 'Пользователь принял предложение AI',
      category: 'service',
      properties: [ :service_name, :booking_id, :acceptance_type ]
    }.freeze

    # События конверсии
    CART_CONFIRMED = {
      name: 'cart_confirmed',
      description: 'Пользователь подтвердил состав заявки',
      category: 'conversion',
      properties: [ :services_count, :total_amount, :confirmation_type ]
    }.freeze

    BOOKING_CREATED = {
      name: 'booking_request_created',
      description: 'Создана заявка на обслуживание',
      category: 'conversion',
      properties: [ :booking_id, :services_count, :estimated_total, :processing_time_ms, :user_segment ]
    }.freeze

    # События производительности
    RESPONSE_TIME = {
      name: 'ai_response_time',
      description: 'Время ответа AI системы',
      category: 'performance',
      properties: [ :duration_ms, :model_used, :timestamp ]
    }.freeze

    # События ошибок
    ERROR_OCCURRED = {
      name: 'error_occurred',
      description: 'Произошла ошибка в системе',
      category: 'error',
      properties: [ :error_class, :error_message, :context, :timestamp ]
    }.freeze

    # Все события в виде хеша для удобного доступа
    ALL_EVENTS = {
      dialog_started: DIALOG_STARTED,
      service_suggested: SERVICE_SUGGESTED,
      service_added: SERVICE_ADDED,
      suggestion_accepted: SUGGESTION_ACCEPTED,
      cart_confirmed: CART_CONFIRMED,
      booking_created: BOOKING_CREATED,
      response_time: RESPONSE_TIME,
      error_occurred: ERROR_OCCURRED
    }.freeze

    # Категории событий
    CATEGORIES = {
      dialog: 'Диалоговые события',
      service: 'Предложения услуг',
      conversion: 'Конверсионные события',
      performance: 'Производительность системы',
      error: 'Ошибки системы'
    }.freeze

    class << self
      # Получить название события по ключу
      #
      # @param key [Symbol] Ключ события
      # @return [String] Название события
      def event_name(key)
        ALL_EVENTS[key]&.dig(:name)
      end

      # Получить описание события
      #
      # @param key [Symbol] Ключ события
      # @return [String] Описание события
      def event_description(key)
        ALL_EVENTS[key]&.dig(:description)
      end

      # Получить категорию события
      #
      # @param key [Symbol] Ключ события
      # @return [String] Категория события
      def event_category(key)
        ALL_EVENTS[key]&.dig(:category)
      end

      # Получить обязательные свойства события
      #
      # @param key [Symbol] Ключ события
      # @return [Array] Массив обязательных свойств
      def event_properties(key)
        ALL_EVENTS[key]&.dig(:properties) || []
      end

      # Получить все события по категории
      #
      # @param category [String] Категория
      # @return [Array] Массив событий категории
      def events_by_category(category)
        ALL_EVENTS.select { |_, event| event[:category] == category }
      end

      # Валидация свойств события
      #
      # @param key [Symbol] Ключ события
      # @param properties [Hash] Свойства для проверки
      # @return [Boolean] True если свойства валидны
      def validate_properties(key, properties)
        required = event_properties(key)
        required.all? { |prop| properties.key?(prop) }
      end

      # Получить человеко-читаемое описание всех событий
      #
      # @return [String] Форматированный текст
      def events_summary
        summary = "Аналитические события системы:\n\n"

        CATEGORIES.each do |category_key, category_name|
          events = events_by_category(category_key)
          next if events.empty?

          summary += "#{category_name}:\n"
          events.each do |event_key, event|
            summary += "  #{event[:name]} - #{event[:description]}\n"
          end
          summary += "\n"
        end

        summary
      end
    end
  end
end
