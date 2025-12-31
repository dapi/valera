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

      # Проверяем настроенность tenant только для приватных чатов
      if private_chat?(message)
        return unless tenant_configured_for_private_chat?
      end

      current_tenant.touch(:last_message_at)

      chat_id = message.dig('chat', 'id')

      # Если чат находится в режиме менеджера - не вызываем AI
      if llm_chat.manager_mode?
        handle_message_in_manager_mode(message)
        return
      end

      # Track dialog start for first message of the day
      if first_message_today?(chat_id)
        AnalyticsService.track(
          AnalyticsService::Events::DIALOG_STARTED,
          tenant: current_tenant,
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
          tenant: current_tenant,
          chat_id: chat_id,
          operation: 'telegram_message_processing',
          model_used: ApplicationConfig.llm_model
        ) do
          setup_chat_tools
          process_message(message['text'])
        end

        send_response_to_user(ai_response)

      rescue => e
        AnalyticsService.track_error(e, tenant: current_tenant, context: {
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
      llm_chat
        .with_tool(BookingTool.new(chat: llm_chat))
        .with_temperature(ApplicationConfig.llm_temperature)
        .with_instructions(SystemPromptService.new(current_tenant).system_prompt, replace: true)
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
      cleaned_content = MarkdownCleanerService.clean_with_line_breaks(content)
      respond_with :message, text: cleaned_content, parse_mode: 'Markdown'
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
      # Проверяем настроенность tenant только для приватных чатов
      if private_chat?
        return unless tenant_configured_for_private_chat?
      end

      WelcomeService.new(current_tenant).send_welcome_message(telegram_user, self)
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

    # Обработчик добавления новых участников в чат
    #
    # Проверяет, что добавлен именно наш бот по ID, и отправляет
    # уведомление с chat_id для настройки бота в группе.
    #
    # @param message [Hash] данные сообщения о добавлении участников
    # @return [void] запускает ChatIdNotificationJob для отправки уведомления
    # @see ApplicationConfig#bot_id для получения ID бота из токена
    # @see ChatIdNotificationJob для отправки уведомления
    # @example При добавлении бота в группу
    #   new_chat_members(message)
    #   #=> Владелец получит сообщение с chat_id группы
    def new_chat_members(message)
      chat_id = message.dig('chat', 'id')
      new_members = message['new_chat_members']

      # Проверяем что добавлен ИМЕННО НАШ бот по ID
      bot_added = new_members&.any? do |member|
        member['is_bot'] && member['id'] == current_tenant.bot_id
      end

      ChatIdNotificationJob.perform_later(chat_id) if bot_added
    end

    # Обработчик миграции группы в супергруппу
    #
    # Когда группа мигрирует в супергруппу, меняется chat_id.
    # Отправляет уведомление с новым chat_id для обновления настроек.
    #
    # @param message [Hash] данные сообщения о миграции
    # @return [void] запускает ChatIdNotificationJob для отправки уведомления
    # @see ChatIdNotificationJob для отправки уведомления
    # @example При миграции группы в супергруппу
    #   migrate_to_supergroup(message)
    #   #=> Владелец получит сообщение с новым chat_id
    def migrate_to_supergroup(message)
      new_chat_id = message.dig('chat', 'id')
      ChatIdNotificationJob.perform_later(new_chat_id)
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
    # @note Временная реализация до полной интеграции multi-tenancy (FIP-004b)
    def llm_chat
      @llm_chat ||= Chat.find_or_create_by!(tenant: current_tenant, client: current_client)
    end

    # Находит или создает клиента для текущего telegram_user и tenant
    #
    # @return [Client] найденный или созданный клиент
    # @api private
    # @note Временная реализация до полной интеграции multi-tenancy (FIP-004b)
    def current_client
      @current_client ||= Client.find_or_create_by!(
        tenant: current_tenant,
        telegram_user: telegram_user
      )
    end

    # Возвращает текущий tenant
    #
    # Current.tenant устанавливается в MultiTenantWebhookController
    # перед вызовом dispatch.
    #
    # @return [Tenant] текущий tenant
    # @raise [RuntimeError] если tenant не установлен
    # @api private
    def current_tenant
      @current_tenant ||= Current.tenant or raise('Current.tenant is not set')
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

      !AnalyticsEvent
        .where(tenant: current_tenant)
        .by_chat(chat_id)
        .by_event(AnalyticsService::Events::DIALOG_STARTED)
        .where('occurred_at >= ?', Date.current)
        .exists?
    end

    # Проверяет, является ли текущий чат приватным
    #
    # @param message [Hash, nil] данные сообщения (опционально, для message handler)
    # @return [Boolean] true если чат приватный
    # @api private
    def private_chat?(message = nil)
      chat_type = if message
                    message.dig('chat', 'type')
      else
                    chat&.dig('type') || chat&.try(:type)
      end
      chat_type == 'private'
    end

    # Проверяет, что tenant настроен для работы в приватном чате
    #
    # Возвращает true если можно продолжать обработку, false если tenant не настроен.
    # При false автоматически отправляет пользователю сообщение об ошибке.
    #
    # @return [Boolean] true если можно продолжать, false если не настроен
    # @api private
    def tenant_configured_for_private_chat?
      return true if current_tenant.admin_chat_id.present?

      Rails.logger.warn { "[WebhookController] Tenant #{current_tenant.key} has no admin_chat_id configured" }
      respond_with :message, text: I18n.t('telegram.bot_not_configured')
      false
    end

    # Обрабатывает сообщение клиента когда чат в режиме менеджера
    #
    # Сохраняет сообщение в истории и уведомляет менеджера через dashboard.
    # AI не вызывается - менеджер отвечает напрямую.
    #
    # @param message [Hash] данные сообщения от Telegram
    # @return [void]
    # @api private
    def handle_message_in_manager_mode(message)
      text = extract_message_content(message)

      # Сохраняем сообщение клиента в историю чата
      # last_message_at обновляется автоматически через acts_as_message touch_chat:
      # Broadcast в dashboard происходит через after_create_commit в модели Message
      llm_chat.messages.create!(role: 'user', content: text)

      AnalyticsService.track(
        AnalyticsService::Events::MESSAGE_RECEIVED_IN_MANAGER_MODE,
        tenant: current_tenant,
        chat_id: llm_chat.id,
        properties: { taken_by_id: llm_chat.taken_by_id, platform: 'telegram' }
      )
    end

    # Извлекает текстовое содержимое из Telegram сообщения
    #
    # Обрабатывает разные типы контента: текст, фото, документы, голос и т.д.
    # Для нетекстовых сообщений возвращает описание типа контента.
    #
    # @param message [Hash] данные сообщения от Telegram
    # @return [String] текст сообщения или описание типа контента
    # @api private
    def extract_message_content(message)
      # Приоритет: text > caption > тип медиа
      return message['text'] if message['text'].present?
      return message['caption'] if message['caption'].present?

      "[#{detect_media_type(message)}]"
    end

    # Определяет тип медиа-контента в сообщении
    #
    # @param message [Hash] данные сообщения от Telegram
    # @return [String, nil] название типа медиа или nil
    # @api private
    def detect_media_type(message)
      case
      when message['photo'] then 'Фото'
      when message['document'] then 'Документ'
      when message['video'] then 'Видео'
      when message['voice'] then 'Голосовое сообщение'
      when message['audio'] then 'Аудио'
      when message['sticker'] then 'Стикер'
      when message['location'] then 'Геолокация'
      when message['contact'] then 'Контакт'
      else 'Неизвестный тип'
      end
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
