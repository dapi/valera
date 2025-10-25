# frozen_string_literal: true

# Base Telegram controller for handling bot updates
class TelegramController < Telegram::Bot::UpdatesController
  # Basic webhook endpoint for Telegram bot
  # This controller inherits from Telegram::Bot::UpdatesController
  # which provides all the basic functionality for handling bot updates

  # Handle incoming messages with a simple response
  def message(message)
    respond_with :message, text: "Сообщение получено!"
  end

  # Handle callback queries from inline keyboards
  def callback_query(data)
    answer_callback_query('Получено!')
  end

  # Example command handler
  def start!(*args)
    respond_with :message, text: "Привет! Я бот для автосервиса."
  end

  private

  # Add any helper methods here
end