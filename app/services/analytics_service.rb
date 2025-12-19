# Сервис для трекинга аналитических событий
#
# Отвечает за сбор и хранение аналитических данных о взаимодействии пользователей с системой.
# Обеспечивает асинхронную обработку событий без влияния на производительность основного приложения.
#
# Основные функции:
# - Трекинг событий диалогов с AI
# - Измерение времени ответа системы
# - Отслеживание конверсии в заявки
# - Мониторинг ошибок системы
#
# @see FIP-001-analytics-system.md - Feature Implementation Plan
# @see TDD-001-analytics-system.md - Technical Design Document
# @see AnalyticsEvent - Модель хранения событий
class AnalyticsService
  include ErrorLogger

  # Event constants for consistency - use EventConstants module
  module Events
    DIALOG_STARTED = Analytics::EventConstants.event_name(:dialog_started)
    GREETING_SENT = Analytics::EventConstants.event_name(:greeting_sent)
    USER_ENGAGEMENT = Analytics::EventConstants.event_name(:user_engagement)
    SERVICE_SUGGESTED = Analytics::EventConstants.event_name(:service_suggested)
    SERVICE_ADDED = Analytics::EventConstants.event_name(:service_added)
    CART_CONFIRMED = Analytics::EventConstants.event_name(:cart_confirmed)
    BOOKING_CREATED = Analytics::EventConstants.event_name(:booking_created)
    SUGGESTION_ACCEPTED = Analytics::EventConstants.event_name(:suggestion_accepted)
    RESPONSE_TIME = Analytics::EventConstants.event_name(:response_time)
    ERROR_OCCURRED = Analytics::EventConstants.event_name(:error_occurred)
  end

  class << self
    # Основной метод для трекинга событий
    #
    # @param event_name [String] Тип события
    # @param chat_id [Integer] ID чата пользователя
    # @param properties [Hash] Дополнительные свойства события
    # @param occurred_at [Time] Время события (по умолчанию текущее)
    def track(event_name, chat_id:, properties: {}, occurred_at: Time.current)
      return unless tracking_enabled?
      return unless Current.tenant # Skip tracking if no tenant context

      # Validate event data
      return unless validate_event_data(event_name, properties)

      # Process asynchronously to avoid blocking main flow
      AnalyticsJob.perform_later(
        event_name: event_name,
        chat_id: chat_id,
        properties: properties,
        occurred_at: occurred_at,
        session_id: generate_session_id(chat_id),
        tenant_id: Current.tenant&.id
      )
    rescue => e
      # Never break main functionality due to analytics errors
      log_error(e, {
        event_name: event_name,
        chat_id: chat_id,
        properties: properties
      })
    end

    # Трекинг времени ответа AI
    #
    # @param chat_id [Integer] ID чата
    # @param duration_ms [Integer] Длительность ответа в миллисекундах
    # @param model_used [String] Используемая модель AI
    def track_response_time(chat_id, duration_ms, model_used)
      track(
        Events::RESPONSE_TIME,
        chat_id: chat_id,
        properties: {
          duration_ms: duration_ms,
          model_used: model_used,
          timestamp: Time.current.to_f
        }
      )
    end

    # Трекинг конверсионных событий
    #
    # @param event_name [String] Тип события
    # @param chat_id [Integer] ID чата
    # @param conversion_data [Hash] Данные о конверсии
    def track_conversion(event_name, chat_id, conversion_data)
      track(event_name, chat_id: chat_id, properties: conversion_data)
    end

    # Трекинг ошибок системы
    #
    # @param error [Exception] Объект ошибки
    # @param context [Hash] Контекст ошибки
    def track_error(error, context = {})
      track(
        Events::ERROR_OCCURRED,
        chat_id: context[:chat_id] || 0,
        properties: {
          error_class: error.class.name,
          error_message: error.message,
          context: context[:context] || 'unknown',
          timestamp: Time.current.to_f
        }
      )
    end

    private

    # Проверка включена ли аналитика
    #
    # @return [Boolean] true если аналитика включена
    def tracking_enabled?
      Rails.application.config.analytics_enabled ||
      Rails.env.production? || Rails.env.staging? || ENV['FORCE_ANALYTICS']
    end

    # Валидация данных события
    #
    # @param event_name [String] Тип события
    # @param properties [Hash] Свойства события
    # @return [Boolean] true если данные валидны
    def validate_event_data(event_name, properties)
      # Find event key by name
      event_key = Analytics::EventConstants::ALL_EVENTS.find { |_, event| event[:name] == event_name }&.first
      return true unless event_key # Allow unknown events for flexibility

      Analytics::EventConstants.validate_properties(event_key, properties)
    end

    # Генерация ID сессии для отслеживания пути пользователя
    #
    # @param chat_id [Integer] ID чата
    # @return [String] MD5 хеш сессии
    def generate_session_id(chat_id)
      # Generate daily session identifier for user journey tracking
      Digest::MD5.hexdigest("#{chat_id}-#{Date.current}-#{Rails.application.secret_key_base}")
    end
  end
end
