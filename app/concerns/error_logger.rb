# frozen_string_literal: true

# Модуль для расширенного логирования ошибок с backtrace
# Используется во всех rescue блоках для детальной диагностики проблем
module ErrorLogger
  extend ActiveSupport::Concern

  class_methods do
    # Логирует ошибку с полным backtrace и контекстом И отправляет в Bugsnag
    # @param error [Exception] - объект исключения
    # @param context [Hash] - дополнительный контекст (опционально)
    def log_error_with_backtrace(error, context = {})
      log_basic_error_info(Rails.logger, error)
      log_error_context(Rails.logger, context, error)
      log_error_backtrace(Rails.logger, error)
      finalize_error_log(Rails.logger)
      send_to_bugsnag_service(error, context)
    end

    private

    # Логирует базовую информацию об ошибке
    def log_basic_error_info(logger, error)
      logger.error "=== ERROR DETAILS ==="
      logger.error "Error Class: #{error.class.name}"
      logger.error "Error Message: #{error.message}"
    end

    # Логирует контекст ошибки и отправляет в Bugsnag если нужно
    def log_error_context(logger, context, error)
      return if context.empty?

      logger.error "Context: #{context.inspect}"
      return unless defined?(Bugsnag)

      Bugsnag.notify(error) do |report|
        context.each { |key, value| report.add_metadata(key, value) }
      end
    end

    # Логирует backtrace ошибки
    def log_error_backtrace(logger, error)
      logger.error "Backtrace:"
      if error.backtrace
        error.backtrace.each_with_index do |line, index|
          logger.error "  #{index + 1}: #{line}"
        end
      else
        logger.error "  No backtrace available"
      end
    end

    # Завершает логирование ошибки
    def finalize_error_log(logger)
      logger.error "=== END ERROR DETAILS ==="
      logger.error "" # пустая строка для читаемости
    end

    # Отправляет ошибку в Bugsnag
    def send_to_bugsnag_service(error, context)
      return unless defined?(Bugsnag) && context.empty?

      Bugsnag.notify(error)
    end

    # Безопасное выполнение блока с автоматическим логированием ошибок
    # @param context [Hash] - контекст для логирования
    # @yield блок кода для безопасного выполнения
    def safe_execute_with_logging(context = {})
      yield
    rescue StandardError => e
      log_error_with_backtrace(e, context)
      raise # пробрасываем ошибку дальше
    end

    # Безопасное выполнение блока с возвратом значения по умолчанию при ошибке
    # @param default_value [Any] - значение при ошибке
    # @param context [Hash] - контекст для логирования
    # @yield блок кода для безопасного выполнения
    # @return результат блока или default_value
    def safe_execute_with_default(default_value = nil, context = {})
      yield
    rescue StandardError => e
      log_error_with_backtrace(e, context)
      default_value
    end
  end

  # Инстанс-методы для включения в классы
  def log_error(error, context = {})
    # debugger if Rails.env.test?
    self.class.log_error_with_backtrace(error, context)
  end
end
