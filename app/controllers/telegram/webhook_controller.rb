# frozen_string_literal: true

# Controller for handling Telegram bot webhooks
class Telegram::WebhookController < Telegram::Bot::UpdatesController
  include ErrorLogger
  before_action :find_or_create_telegram_user
  before_action :find_or_create_llm_chat
  # Basic webhook endpoint for Telegram bot
  # This controller inherits from Telegram::Bot::UpdatesController
  # which provides all the basic functionality for handling bot updates

  # Handle incoming messages - передаем в LLM систему через ruby_llm
  def message(message)
    # Проверяем, что это текстовое сообщение
    return unless message['text'].present?

    # Передаем сообщение в LLM через chat.ask
    # ruby_llm автоматически:
    # 1. Сохранит сообщение в Message модель
    # 2. Использует системный промпт (уже с инструкциями по консультациям!)
    # 3. Сгенерирует AI ответ

    ai_response = llm_chat.ask(message['text'])

    # Отправляем ответ клиенту через Telegram API
    respond_with :message, text: ai_response
  rescue => e
    # Обработка ошибок AI с расширенным логированием
    log_error(e, {
      controller: self.class.name,
      action: 'message',
      message_text: message['text'],
      telegram_user_id: telegram_user&.id,
      chat_id: llm_chat&.id
    })
    respond_with :message, text: "Извините, произошла ошибка. Попробуйте еще раз."
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
    @llm_chat = Chat.find_or_create_by!(telegram_user: telegram_user) do |chat|
      # Устанавливаем модель по умолчанию для новых чатов
      chat.model = Model.find_by!(provider: ApplicationConfig.llm_provider, model_id: ApplicationConfig.llm_model)
    end
  end

  # Add any helper methods here
end
