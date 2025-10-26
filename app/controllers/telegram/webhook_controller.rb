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
    unless message['text'].present?
      respond_with :message, text: 'Напишите, пожалуйста, текстом'
      return
    end

    # Проверяем есть ли незавершенные tool calls
    # Хотя откуда одни? Бага?
    # if llm_chat.pending_tool_calls?
    # debugger
    ## Очищаем состояние перед новым сообщением
    # llm_chat.clear_pending_tool_calls
    # end

    # Передаем сообщение в LLM через chat.ask
    # ruby_llm автоматически:
    # 1. Сохранит сообщение в Message модель
    # 2. Использует системный промпт (уже с инструкциями по консультациям!)
    # 3. Сгенерирует AI ответ

    llm_chat.with_tool(BookingTool.new(telegram_user:, chat: llm_chat))
            .on_tool_call do |tool_call|
      # Called when the AI decides to use a tool
      Rails.logger.debug { "Calling tool: #{tool_call.name}" }
      Rails.logger.debug { "Arguments: #{tool_call.arguments}" }
    end
      .on_tool_result do |result|
        # Called after the tool returns its result
        Rails.logger.debug "Tool returned: #{result}"
      end

    ai_response = llm_chat.say(message['text'])

    # Альтернативный способ поднять последнее сообщение от LLM
    # assistant_message_record = chat_record.messages.last
    # puts assistant_message_record.content # => "The capital of France is Paris."

    # Отправляем ответ клиенту через Telegram API
    content = ai_response.content
    Rails.logger.debug { "AI Response: #{content}" }
    respond_with :message, text: MarkdownCleaner.clean(content), parse_mode: 'Markdown'
  end

  # Handle callback queries from inline keyboards
  def callback_query(data)
    answer_callback_query('Получено!')
  end

  # Command handler /start - отправка welcome message
  def start!(*args)
    # Отправляем приветствие новому пользователю через WelcomeService
    WelcomeService.new.send_welcome_message(telegram_user, self)
  end

  def reset!(*args)
    llm_chat.reset!
    respond_with :message, text: 'Ваши данные и диалоги удалены из базы данных. Можно начинать сначала'
  end

  private

  attr_reader :telegram_user # Текущийп пользовтель
  attr_reader :llm_chat # Текущий LLM Chat

  def handle_error(error)
    # Обработка ошибок AI с расширенным логированием
    case error
    when Telegram::Bot::Forbidden
      Rails.logger.error error
    else # ActiveRecord::ActiveRecordError
      log_error(error, {
                  controller: self.class.name,
                  update: update,
                  telegram_user_id: telegram_user&.id,
                  chat_id: llm_chat&.id
                })
      respond_with :message, text: "Извините, произошла ошибка. Попробуйте еще раз."
    end
  end

  def find_or_create_telegram_user
    @find_or_create_telegram_user ||= TelegramUser.find_or_create_by_telegram_data! from
  end

  def find_or_create_llm_chat
    @find_or_create_llm_chat ||= Chat.find_or_create_by!(telegram_user: telegram_user)
  end
end
