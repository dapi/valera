# frozen_string_literal: true

# Controller for handling Telegram bot webhooks
module Telegram
  # Handles incoming webhook updates from Telegram bot API and processes them through LLM
  class WebhookController < Telegram::Bot::UpdatesController
    include ErrorLogger

    before_action :telegram_user
    before_action :llm_chat

    rescue_from StandardError, with: :handle_error
    # Basic webhook endpoint for Telegram bot
    # This controller inherits from Telegram::Bot::UpdatesController
    # which provides all the basic functionality for handling bot updates
    #

    # Handle incoming messages - передаем в LLM систему через ruby_llm
    def message(message)
      return unless text_message?(message)

      setup_chat_tools
      ai_response = process_message(message['text'])
      send_response_to_user(ai_response)
    end

    # Проверяет, что это текстовое сообщение
    def text_message?(message)
      return true if message['text'].present?

      respond_with :message, text: 'Напишите, пожалуйста, текстом'
      false
    end

    # Настраивает инструменты для чата
    def setup_chat_tools
      llm_chat.with_tool(BookingTool.new(telegram_user:, chat: llm_chat))
              .on_tool_call { |tool_call| handle_tool_call(tool_call) }
              .on_tool_result { |result| handle_tool_result(result) }
    end

    # Обрабатывает вызов инструмента
    def handle_tool_call(tool_call)
      Rails.logger.debug { "Calling tool: #{tool_call.name}" }
      Rails.logger.debug { "Arguments: #{tool_call.arguments}" }
    end

    # Обрабатывает результат инструмента
    def handle_tool_result(result)
      Rails.logger.debug { "Tool returned: #{result}" }
    end

    # Обрабатывает сообщение через LLM
    def process_message(text)
      llm_chat.say(text)
    end

    # Отправляет ответ пользователю
    def send_response_to_user(ai_response)
      content = ai_response.content
      Rails.logger.debug { "AI Response: #{content}" }
      respond_with :message, text: MarkdownCleaner.clean(content), parse_mode: 'Markdown'
    end

    # Handle callback queries from inline keyboards
    def callback_query(_data)
      answer_callback_query('Получено!')
    end

    # Command handler /start - отправка welcome message
    def start!(*_args)
      # Отправляем приветствие новому пользователю через WelcomeService
      WelcomeService.new.send_welcome_message(telegram_user, self)
    end

    def reset!(*_args)
      llm_chat.reset!
      respond_with :message, text: 'Ваши данные и диалоги удалены из базы данных. Можно начинать сначала'
    end

    private

    def handle_error(error)
      # Обработка ошибок AI с расширенным логированием
      case error
      when Telegram::Bot::Forbidden
        Rails.logger.error error
      else # ActiveRecord::ActiveRecordError
        Rails.logger.error "ERROR DETAILS: #{error.class.name}: #{error.message}"
        Rails.logger.error "BACKTRACE: #{error.backtrace&.first(5)&.join("\n")}"
        log_error(error, {
                    controller: self.class.name,
                    update: update,
                    telegram_user_id: telegram_user&.id,
                    chat_id: llm_chat&.id
                  })
        respond_with :message, text: 'Извините, произошла ошибка. Попробуйте еще раз.'
      end
    end

    def telegram_user
      @telegram_user ||= TelegramUser.find_or_create_by_telegram_data! from
    end

    def llm_chat
      @llm_chat ||= Chat.find_or_create_by!(telegram_user: telegram_user)
    end
  end
end
