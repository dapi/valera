# frozen_string_literal: true

# Controller for handling Telegram bot webhooks
class Telegram::WebhookController < Telegram::Bot::UpdatesController
  include ErrorLogger
  before_action :find_or_create_telegram_user
  before_action :find_or_create_llm_chat

  rescue_from StandardError, with: :handle_error
  # Basic webhook endpoint for Telegram bot
  # This controller inherits from Telegram::Bot::UpdatesController
  # which provides all the basic functionality for handling bot updates
  #

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

    #(ruby) ai_response
    ##<RubyLLM::Message:0x00007eb1c73ecf90
     #@content=
      ##<RubyLLM::Content:0x00007eb1c74532b8
       #@attachments=[],
       #@text=
        #"It looks like you’ve typed a series of random characters or possibly placeholder text like \"asdsa\", \"sdasd\", \"asda\", etc.  \n\nIf this was accidental or a test, no worries — I’m here.  \nIf you meant to ask something or need help with a specific task, feel free to explain, and I’ll do my best to assist!">,
     #@input_tokens=31,
     #@model_id="deepseek-chat",
     #@output_tokens=80,
     #@role=:assistant,
     #@tool_call_id=nil,
     #@tool_calls=nil>

    # Альтернативный способ поднять последнее сообщение от LLM
    #assistant_message_record = chat_record.messages.last
    #puts assistant_message_record.content # => "The capital of France is Paris."

    # Отправляем ответ клиенту через Telegram API
    content = ai_response.content
    puts content
    respond_with :message, text: content, parse_mode: 'Markdown'
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
    llm_chat.reset!
    # Отправляем приветствие новому пользователю через WelcomeService
    WelcomeService.new.send_welcome_message(telegram_user, self)
  end

  private

  attr_reader :telegram_user # Текущийп пользовтель
  attr_reader :llm_chat # Текущий LLM Chat

  def handle_error(error)
    case error
    when Telegram::Bot::Forbidden
      Rails.logger.error error
    else # ActiveRecord::ActiveRecordError
      Rails.logger.error error
      Bugsnag.notify error do |b|
        b.meta_data = { chat: chat, from: from }
      end
      respond_with :message, text: "Error: #{error.message}"
    end
  end

  def find_or_create_telegram_user
    @telegram_user = TelegramUser.find_or_create_by_telegram_data! from
  end

  def find_or_create_llm_chat
    @llm_chat = Chat.find_or_create_by!(telegram_user: telegram_user)
  end
end
