# frozen_string_literal: true

# Provides error handling functionality for controllers
# Handles different types of errors with appropriate logging and responses
module RescueErrors
  extend ActiveSupport::Concern

  included do
    rescue_from Telegram::Bot::Forbidden, with: :handle_forbidden_error
    rescue_from StandardError, with: :handle_standard_error
  end

  private

  def handle_forbidden_error(error)
    Rails.logger.error error
  end

  def handle_standard_error(error)
    log_error_details(error)
    log_error_with_context(error)
    send_error_response
  end

  def log_error_details(error)
    Rails.logger.error "ERROR DETAILS: #{error.class.name}: #{error.message}"
    Rails.logger.error "BACKTRACE: #{error.backtrace&.first(5)&.join("\n")}"
  end

  def log_error_with_context(error)
    if respond_to?(:log_error, true)
      log_error(error, error_context)
    else
      Rails.logger.error "CONTEXT: #{error_context}"
    end
  end

  def send_error_response
    return unless respond_to?(:respond_with, true)

    respond_with :message, text: 'Извините, произошла ошибка. Попробуйте еще раз.'
  end

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
