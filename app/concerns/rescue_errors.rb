# frozen_string_literal: true

# Модуль для обработки ошибок в контроллерах
#
# Предоставляет унифицированную обработку различных типов ошибок
# с логированием и отправкой соответствующих ответов пользователю.
#
# @example Использование в контроллере
#   class MyController < ApplicationController
#     include RescueErrors
#   end
#
# @see ErrorLogger для детального логирования ошибок
# @author Danil Pismenny
# @since 0.1.0
module RescueErrors
  extend ActiveSupport::Concern

  included do
    rescue_from Telegram::Bot::Forbidden, with: :handle_forbidden_error
    rescue_from StandardError, with: :handle_standard_error
  end

  private

  # Обрабатывает ошибки доступа Telegram API
  #
  # @param error [Telegram::Bot::Forbidden] ошибка запрета доступа
  # @return [void] логирует ошибку
  # @note Пользователь заблокировал бота или нет доступа к чату
  def handle_forbidden_error(error)
    Rails.logger.error error
  end

  # Обрабатывает стандартные ошибки приложения
  #
  # @param error [StandardError] стандартная ошибка
  # @return [void] логирует ошибку и отправляет ответ пользователю
  def handle_standard_error(error)
    log_error_details(error)
    log_error_with_context(error)
    send_error_response
  end

  # Логирует детали ошибки
  #
  # @param error [StandardError] ошибка для логирования
  # @return [void]
  # @note Сохраняет только первые 5 строк backtrace для чистоты логов
  def log_error_details(error)
    Rails.logger.error "ERROR DETAILS: #{error.class.name}: #{error.message}"
    Rails.logger.error "BACKTRACE: #{error.backtrace&.first(5)&.join("\n")}"
  end

  # Логирует ошибку с контекстной информацией
  #
  # @param error [StandardError] ошибка для логирования
  # @return [void]
  # @note Использует ErrorLogger если доступен, иначе просто логирует контекст
  def log_error_with_context(error)
    if respond_to?(:log_error, true)
      log_error(error, error_context)
    else
      Rails.logger.error "CONTEXT: #{error_context}"
    end
  end

  # Отправляет сообщение об ошибке пользователю
  #
  # @return [void] отправляет сообщение через Telegram API если возможно
  # @note Отправляется только если контроллер поддерживает respond_with
  def send_error_response
    return unless respond_to?(:respond_with, true)

    respond_with :message, text: 'Извините, произошла ошибка. Попробуйте еще раз.'
  end

  # Формирует контекст ошибки для логирования
  #
  # @return [Hash] хеш с контекстной информацией
  # @note Включает контроллер, обновление, пользователя и чат
  def error_context
    context = {
      controller: self.class.name
    }

    context[:update] = update if respond_to?(:update, true)
    context[:telegram_user_id] = telegram_user&.id if respond_to?(:telegram_user, true)
    context[:chat_id] = llm_chat&.id if respond_to?(:llm_chat, true)

    context
  end
end
