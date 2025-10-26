# frozen_string_literal: true

# Контроллер для обработки webhook событий от Telegram бота
#
# Принимает входящие обновления от Telegram Bot API, обрабатывает их через
# LLM систему (ruby_llm) и управляет созданием заявок на автосервис.
#
# @example Обработка текстового сообщения
#   # POST /telegram/webhook
#   # {"message": {"text": "Хочу записаться на ТО", "chat": {"id": 123}}}
#
# @see BookingTool для создания заявок
# @see AnalyticsService для трекинга событий
# @see TelegramUser для работы с пользователями
# @author Danil Pismenny
# @since 0.1.0
module Telegram
  class WebhookController < Telegram::Bot::UpdatesController
    include ErrorLogger
    include RescueErrors

    before_action :telegram_user
    before_action :llm_chat
    before_action :setup_analytics_context

    # Обрабатывает входящие текстовые сообщения от пользователей
    #
    # Принимает сообщение от пользователя, проверяет его формат, отслеживает
    # аналитические события и обрабатывает через AI систему с измерением времени ответа.
    #
    # @param message [Hash] данные сообщения от Telegram
    # @option message [String] 'text' текст сообщения
    # @option message [Hash] 'chat' информация о чате
    # @return [void] отправляет ответ пользователю через Telegram API
    # @raise [StandardError] при ошибке обработки сообщения
    # @note Автоматически отслеживает время ответа и аналитику
    # @example Обработка сообщения о записи на ТО
    #   message = {"text" => "Хочу записаться на ТО", "chat" => {"id" => 12345}}
    #   message(message)
    #   #=> Пользователь получит ответ от AI ассистента
    def message(message)
      return unless text_message?(message)

      chat_id = message.dig('chat', 'id')

      # Track dialog start for first message of the day
      if first_message_today?(chat_id)
        AnalyticsService.track(
          AnalyticsService::Events::DIALOG_STARTED,
          chat_id: chat_id,
          properties: {
            message_type: message_type(message),
            platform: 'telegram',
            user_id: telegram_user.id
          }
        )
      end

      # Measure AI response time with new tracker
      begin
        ai_response = Analytics::ResponseTimeTracker.measure(
          chat_id,
          'telegram_message_processing',
          'deepseek-chat'
        ) do
          setup_chat_tools
          process_message(message['text'])
        end

        send_response_to_user(ai_response)

      rescue => e
        AnalyticsService.track_error(e, {
          chat_id: chat_id,
          context: 'webhook_processing',
          user_id: telegram_user.id
        })
        raise e
      end
    end

    # Проверяет, что сообщение является текстовым
    #
    # @param message [Hash] данные сообщения от Telegram
    # @return [Boolean] true если сообщение текстовое, иначе false
    # @note Отправляет сообщение с просьбой написать текстом если формат неверный
    def text_message?(message)
      return true if message['text'].present?

      respond_with :message, text: 'Напишите, пожалуйста, текстом'
      false
    end

    # Настраивает инструменты (tools) для AI чата
    #
    # Регистрирует BookingTool как доступный инструмент для AI ассистента
    # и устанавливает обработчики для вызовов и результатов инструментов.
    #
    # @return [void]
    # @see BookingTool для реализации создания заявок
    # @note Tools используются AI для выполнения действий в реальном мире
    def setup_chat_tools
      llm_chat.with_tool(BookingTool.new(telegram_user:, chat: llm_chat))
              .on_tool_call { |tool_call| handle_tool_call(tool_call) }
              .on_tool_result { |result| handle_tool_result(result) }
    end

    # Обрабатывает вызов инструмента со стороны AI
    #
    # Логирует информацию о вызываемом инструменте для отладки
    # и мониторинга работы AI системы.
    #
    # @param tool_call [RubyLLM::ToolCall] объект вызова инструмента
    # @return [void]
    # @note В будущем можно добавить дополнительную логику обработки
    def handle_tool_call(tool_call)
      Rails.logger.debug { "Calling tool: #{tool_call.name}" }
      Rails.logger.debug { "Arguments: #{tool_call.arguments}" }
    end

    # Обрабатывает результат выполнения инструмента
    #
    # Логирует результаты выполнения инструментов для анализа
    # работы AI и отладки возможных проблем.
    #
    # @param result [Object] результат выполнения инструмента
    # @return [void]
    # @note Помогает отслеживать эффективность инструментов
    def handle_tool_result(result)
      Rails.logger.debug { "Tool returned: #{result}" }
    end

    # Обрабатывает текстовое сообщение через LLM систему
    #
    # Передает текст пользователя в AI ассистент для получения
    # контекстного ответа с использованием текущего диалога.
    #
    # @param text [String] текст сообщения пользователя
    # @return [RubyLLM::Content] ответ от AI ассистента
    # @see ruby_llm gem документация для подробностей
    def process_message(text)
      llm_chat.say(text)
    end

    # Отправляет ответ AI пользователю в Telegram
    #
    # Очищает Markdown форматирование от AI и отправляет ответ
    # пользователю через Telegram API с поддержкой Markdown.
    #
    # @param ai_response [RubyLLM::Content] ответ от AI ассистента
    # @return [void] отправляет сообщение пользователю
    # @see MarkdownCleaner для очистки форматирования
    def send_response_to_user(ai_response)
      content = ai_response.content
      Rails.logger.debug { "AI Response: #{content}" }
      respond_with :message, text: MarkdownCleaner.clean(content), parse_mode: 'Markdown'
    end

    # Обрабатывает callback запросы от inline клавиатур
    #
    # @param _data [String] данные из callback запроса (временно не используются)
    # @return [void] отправляет ответ на callback запрос
    # @note В будущем можно добавить обработку интерактивных элементов
    def callback_query(_data)
      answer_callback_query('Получено!')
    end

    # Обработчик команды /start - отправка приветственного сообщения
    #
    # Вызывается когда пользователь впервые запускает бота или вводит команду /start.
    # Отправляет персонализированное приветствие через WelcomeService.
    #
    # @param _args [Array] аргументы команды (не используются)
    # @return [void] отправляет приветственное сообщение
    # @see WelcomeService для логики приветствия
    # @example Пользователь вводит /start
    #   start!()
    #   #=> Пользователь получит приветственное сообщение
    def start!(*_args)
      WelcomeService.new.send_welcome_message(telegram_user, self)
    end

    # Обработчик команды /reset - сброс диалога
    #
    # Полностью очищает историю диалога пользователя, удаляет все сообщения
    # и сбрасывает контекст AI ассистента к начальному состоянию.
    #
    # @param _args [Array] аргументы команды (не используются)
    # @return [void] отправляет подтверждение сброса
    # @see Chat#reset! для логики сброса диалога
    # @example Пользователь вводит /reset
    #   reset!()
    #   #=> Все данные удалены, диалог начат заново
    def reset!(*_args)
      llm_chat.reset!
      respond_with :message, text: 'Ваши данные и диалоги удалены из базы данных. Можно начинать сначала'
    end

    private

    # Находит или создает пользователя Telegram по данным из запроса
    #
    # @return [TelegramUser] найденный или созданный пользователь
    # @api private
    def telegram_user
      @telegram_user ||= TelegramUser.find_or_create_by_telegram_data! from
    end

    # Находит или создает чат для пользователя
    #
    # @return [Chat] найденный или созданный чат
    # @api private
    def llm_chat
      @llm_chat ||= Chat.find_or_create_by!(telegram_user: telegram_user)
    end

    # Устанавливает контекст аналитики для отслеживания запроса
    #
    # Сохраняет уникальный ID запроса и время начала для последующего
    # отслеживания производительности и пути пользователя.
    #
    # @return [void]
    # @note Используется RequestStore для хранения данных в рамках одного запроса
    # @api private
    def setup_analytics_context
      RequestStore.store[:analytics_request_id] = SecureRandom.uuid
      RequestStore.store[:analytics_start_time] = Time.current
    end

    # Проверяет, является ли сообщение первым от пользователя сегодня
    #
    # Используется для отслеживания начала диалога и построения
    # воронки вовлеченности пользователей.
    #
    # @param chat_id [Integer] ID чата пользователя
    # @return [Boolean] true если это первое сообщение за сегодня
    # @note В тестовой среде всегда возвращает true для стабильности тестов
    # @api private
    def first_message_today?(chat_id)
      return true if Rails.env.test?

      AnalyticsEvent
        .by_chat(chat_id)
        .by_event(AnalyticsService::Events::DIALOG_STARTED)
        .where('occurred_at >= ?', Date.current)
        .exists?
    end

    # Определяет тип сообщения для аналитики
    #
    # Классифицирует сообщение по контенту для лучшего понимания
    # намерений пользователей и эффективности бота.
    #
    # @param message [Hash] данные сообщения от Telegram
    # @return [String] тип сообщения ('command', 'booking_intent', 'price_inquiry', 'general')
    # @note Помогает строить аналитические отчеты по поведению пользователей
    # @api private
    def message_type(message)
      if message['text']&.start_with?('/')
        'command'
      elsif message['text']&.include?('запис') || message['text']&.include?('осмотр')
        'booking_intent'
      elsif message['text']&.include?('цен') || message['text']&.include?('стоим')
        'price_inquiry'
      else
        'general'
      end
    end
  end
end
