# frozen_string_literal: true

# Controller for handling Telegram bot webhooks
class Telegram::WebhookController < Telegram::Bot::UpdatesController
  before_action :find_or_create_telegram_user
  before_action :find_or_create_llm_chat
  # Basic webhook endpoint for Telegram bot
  # This controller inherits from Telegram::Bot::UpdatesController
  # which provides all the basic functionality for handling bot updates

  # Handle incoming messages - передаем в LLM систему через ruby_llm
  def message(message)
    # Создаем Chat запись, если ее нет
    # ruby_llm автоматически обработает сообщение через acts_as_chat
    # Ничего не делаем здесь - LLM система обрабатывает сообщения автоматически
  end

  # Handle callback queries from inline keyboards
  def callback_query(data)
    answer_callback_query('Получено!')
  end

  # Command handler /start - отправка welcome message
  def start!(*args)
    # Отправляем приветствие новому пользователю через WelcomeService
    WelcomeService.new.send_welcome_message(telegram_user, self)

    nil
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
