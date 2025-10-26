# frozen_string_literal: true

# Модуль для расширенного логирования ошибок с backtrace
# Используется во всех rescue блоках для детальной диагностики проблем
module ErrorLogger
  extend ActiveSupport::Concern

  class_methods do
    # Логирует ошибку с полным backtrace и контекстом И отправляет в Bugsnag
    # @param error [Exception] - объект исключения
    # @param context [Hash] - дополнительный контекст (опционально)
    # @param logger [Logger] - кастомный логгер (опционально)
    # @param send_to_bugsnag [Boolean] - флаг отправки в Bugsnag (по умолчанию true)
    def log_error_with_backtrace(error, context = {}, logger = nil, send_to_bugsnag = true)
      target_logger = logger || Rails.logger

      # Базовая информация об ошибке
      target_logger.error "=== ERROR DETAILS ==="
      target_logger.error "Error Class: #{error.class.name}"
      target_logger.error "Error Message: #{error.message}"

      # Контекст если передан
      unless context.empty?
        target_logger.error "Context: #{context.inspect}"
        # Добавляем контекст в Bugsnag metadata
        if send_to_bugsnag && defined?(Bugsnag)
          Bugsnag.notify(error) do |report|
            context.each { |key, value| report.add_metadata(key, value) }
          end
        end
      end

      # Полный backtrace
      target_logger.error "Backtrace:"
      if error.backtrace
        error.backtrace.each_with_index do |line, index|
          target_logger.error "  #{index + 1}: #{line}"
        end
      else
        target_logger.error "  No backtrace available"
      end

      target_logger.error "=== END ERROR DETAILS ==="
      target_logger.error "" # пустая строка для читаемости

      # Отправляем в Bugsnag если нужно и если доступен
      return unless send_to_bugsnag && defined?(Bugsnag) && context.empty?

      Bugsnag.notify(error)
    end

    # Безопасное выполнение блока с автоматическим логированием ошибок
    # @param context [Hash] - контекст для логирования
    # @param logger [Logger] - кастомный логгер (опционально)
    # @yield блок кода для безопасного выполнения
    def safe_execute_with_logging(context = {}, logger = nil)
      yield
    rescue StandardError => e
      log_error_with_backtrace(e, context, logger)
      raise # пробрасываем ошибку дальше
    end

    # Безопасное выполнение блока с возвратом значения по умолчанию при ошибке
    # @param default_value [Any] - значение при ошибке
    # @param context [Hash] - контекст для логирования
    # @param logger [Logger] - кастомный логгер (опционально)
    # @yield блок кода для безопасного выполнения
    # @return результат блока или default_value
    def safe_execute_with_default(default_value = nil, context = {}, logger = nil)
      yield
    rescue StandardError => e
      log_error_with_backtrace(e, context, logger)
      default_value
    end
  end

  # Инстанс-методы для включения в классы
  def log_error(error, context = {})
    # debugger if Rails.env.test?
    self.class.log_error_with_backtrace(error, context)
  end
end
