# frozen_string_literal: true

# Controller for handling Telegram bot webhooks
class Telegram::WebhookController < Telegram::Bot::UpdatesController
  before_action :find_or_create_telegram_user
  before_action :find_or_create_llm_chat
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

  attr_reader :telegram_user # Текущийп пользовтель
  attr_reader :llm_chat # Текущий LLM Chat

  def find_or_create_telegram_user
    @telegram_user = TelegramUser.find_or_create_by!(id: from['id'])
  end

  def find_or_create_llm_chat
    @llm_chat = Chat.find_or_create_by!(telegram_user: telegram_user)
  end

  # Add any helper methods here
end
