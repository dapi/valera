# frozen_string_literal: true
class BookingTool < RubyLLM::Tool
  description "Определяет является ли сообщение клиента заявкой на услугу и отправляет ее в административный чат"

  param :message_text, desc: "Текст сообщения от клиента"
  param :name, desc: "Имя пользователя", required: false
  param :conversation_context, desc: "Контекст диалога (последние сообщения)", required: false
  param :car_info, desc: "Информация об автомобиле (марка, модель, класс, пробег)", required: false
  param :required_services, desc: "Перечень необходимых работ", required: false
  param :cost_calculation, desc: "Расчет стоимости услуг", required: false
  param :dialog_context, desc: "Контекст диалога для понимания ситуации", required: false
  param :total_cost_to_user, desc: "Последняя названная пользователю общая стоимость услуг", required: false
  param :conversation_summary, desc: "Краткая выжимка из истории переписки между ботом и клиентом", required: false

  def initialize
    @enriched_data = {}
    @user_data = {}
  end

  # Метод для установки обогащенных данных извне
  def enrich_with(car_info:, required_services:, cost_calculation:, dialog_context:, total_cost_to_user: nil, conversation_summary: nil)
    @enriched_data = {
      car_info: car_info,
      required_services: required_services,
      cost_calculation: cost_calculation,
      dialog_context: dialog_context,
      total_cost_to_user: total_cost_to_user,
      conversation_summary: conversation_summary
    }
    Application.instance.logger.debug "RequestDetector enriched with data: #{@enriched_data.keys}"
  end

  # Метод для получения обогащенных данных
  def enriched_data
    @enriched_data
  end

  def execute(message_text:, name: nil, conversation_context: nil,
              car_info: nil, required_services: nil, cost_calculation: nil, dialog_context: nil,
              total_cost_to_user: nil, conversation_summary: nil)

    begin
      Application.instance.logger.info "Request detected: #{message_text[0..50]}..."
      Application.instance.logger.debug "Request data - name: #{name}"

      # Валидация конфигурации
      admin_chat_id = AppConfig.admin_chat_id
      unless admin_chat_id
        Application.instance.logger.error "Admin chat ID not configured"
        return { error: "Сервис заявок не настроен" }
      end

      # LLM уже определил(а), что это заявка на услугу, поэтому сразу обрабатываем её
      Application.instance.logger.info "Processing service request - confirmed by LLM"

      # Обогащенные данные имеют приоритет над переданными параметрами
      final_car_info = @enriched_data[:car_info] || car_info
      final_required_services = @enriched_data[:required_services] || required_services
      final_cost_calculation = @enriched_data[:cost_calculation] || cost_calculation
      final_dialog_context = @enriched_data[:dialog_context] || dialog_context

      # Валидация основных данных
      unless message_text && !message_text.strip.empty?
        Application.instance.logger.error "Empty message_text"
        return { error: "Пустой текст сообщения" }
      end

      # Создаем безопасную структуру данных для заявки
      request_info = {
        confidence: 1.0, # максимальная уверенность, т.к. вызвано LLM
        original_text: message_text || '',
        car_info: final_car_info || {},
        required_services: final_required_services || [],
        cost_calculation: final_cost_calculation || {},
        dialog_context: final_dialog_context || ''
      }

      result = send_to_admin_chat(request_info, nil, name, admin_chat_id)

      if result[:success]
        return "Заявка отправлена администратору"
      else
        Application.instance.logger.error "Admin notification failed: #{result[:error]}"
        return { error: result[:error] }
      end

    rescue StandardError => e
      Application.instance.logger.error "❌ REQUEST ERROR: #{e.class}: #{e.message}"
      Application.instance.logger.error "Full backtrace:"
      e.backtrace&.each { |line| Application.instance.logger.error "  #{line}" }
      { error: "Ошибка при обработке заявки: #{e.message}" }
    end
  end

  private

  def send_to_admin_chat(request_info, username, name, admin_chat_id)
    # Создаем уведомление для админского чата с защитой от ошибок
    notification = format_admin_notification_safe(request_info, username, name)

    # Очищаем текст для безопасного Markdown
    notification = sanitize_markdown(notification)

    # Используем Telegram bot API для отправки с таймаутом
    bot = Telegram::Bot::Client.new(bot_token)

    bot.api.send_message(
      chat_id: admin_chat_id,
      text: notification.presence || 'Ошибка! Нет уведомления',
      parse_mode: 'Markdown'
    )

    Application.instance.logger.info "Request notification sent to admin chat #{admin_chat_id}"
    { success: true }
  rescue Telegram::Bot::Exceptions::ResponseError => e
    log_telegram_api_error(e, request_info, username, name)
    { error: "Ошибка API Telegram: #{e.message}" }
  rescue Telegram::Bot::Exceptions::Base => e
    Application.instance.logger.error "Telegram bot error: #{e.class}: #{e.message}"
    { error: "Ошибка бота Telegram: #{e.message}" }
  rescue Net::TimeoutError, Net::OpenTimeout => e
    Application.instance.logger.error "Network timeout sending admin notification: #{e.message}"
    { error: "Таймаут сети при отправке уведомления" }
  rescue StandardError => e
    Application.instance.logger.error "❌ REQUEST ERROR: Unexpected error sending admin notification: #{e.class}: #{e.message}"
    Application.instance.logger.error "Full backtrace:"
    e.backtrace&.each { |line| Application.instance.logger.error "  #{line}" }
    { error: "Непредвиденная ошибка: #{e.message}" }
  end

  def format_admin_notification(request_info, username, name)
    # Базовая информация
    notification = format_basic_info(request_info, username, name)

    # Обогащенная информация
    notification += format_car_info(request_info[:car_info])
    notification += format_required_services(request_info[:required_services])
    notification += format_total_cost_to_user
    notification += format_conversation_summary
    notification += format_dialog_context(request_info[:dialog_context])
    notification += format_action_buttons

    notification
  end

  def format_admin_notification_safe(request_info, username, name)
    begin
      notification = ""

      # Базовая информация с защитой
      notification += format_basic_info_safe(request_info, username, name)

      # Обогащенная информация с защитой
      notification += format_car_info_safe(request_info[:car_info])
      notification += format_required_services_safe(request_info[:required_services])
      notification += format_total_cost_to_user_safe
      notification += format_conversation_summary_safe
      notification += format_dialog_context_safe(request_info[:dialog_context])
      notification += format_action_buttons_safe

      notification
    rescue StandardError => e
      Application.instance.logger.error "Error formatting admin notification: #{e.message}"
      # Возвращаем базовое уведомление в случае ошибки форматирования
      basic_name = name.to_s.strip.empty? ? "Клиент" : name.to_s.strip
      "🔔 **НОВАЯ ЗАЯВКА**\n\n👤 **Клиент:** #{basic_name}\n\n💬 **Сообщение:**\n```\n#{request_info[:original_text].to_s.strip[0..200]}\n```\n\n⚠️ *Произошла ошибка форматирования уведомления*"
    end
  end

  def format_basic_info(request_info, username, name)
    user_display = name || "Анонимный пользователь"

    notification = "🔔 **НОВАЯ ЗАЯВКА**\n\n"
    notification += "👤 **Клиент:** #{user_display}\n"

    # Добавляем дополнительную информацию если она есть
    if name
      notification += "📝 **Имя:** #{name}\n"
    end

    notification += "\n"

    # Сохраняем обратную совместимость с старым форматом
    if request_info[:matched_patterns] && !request_info[:matched_patterns].empty?
      notification += "🔍 **Распознанные паттерны:**\n"
      Array(request_info[:matched_patterns]).first(3).each do |pattern|
        # Ensure pattern is a string before splitting
        pattern_str = pattern.to_s
        type, pattern_text = pattern_str.split(':', 2)
        notification += "• #{type}: `#{pattern_text}`\n"
      end
      notification += "\n"
    end

    notification += "💬 **Сообщение:**\n"
    notification += "```\n#{request_info[:original_text]}\n```\n\n"

    notification
  end

  def format_car_info(car_info)
    return "" unless car_info && !car_info.empty?

    info = "\n🚗 **Информация об автомобиле:**\n"

    # Проверяем наличие данных
    has_data = false

    if car_info[:make_model]
      info += "• **Марка и модель:** #{car_info[:make_model]}\n"
      has_data = true
    end

    if car_info[:year]
      info += "• **Год выпуска:** #{car_info[:year]}\n"
      has_data = true
    end

    if car_info[:class]
      class_desc = car_info[:class_description] || car_info[:class]
      info += "• **Класс автомобиля:** #{class_desc}\n"
      has_data = true
    else
      info += "• **Класс автомобиля:** требуется уточнение\n"
      has_data = true
    end

    if car_info[:mileage]
      info += "• **Пробег:** #{car_info[:mileage]}\n"
      has_data = true
    end

    info += "\n" if has_data
    info
  end

  def format_required_services(services)
    return "" unless services && !services.empty?

    info = "\n🔧 **Необходимые работы:**\n"
    Array(services).each_with_index do |service, index|
      # Ensure service is convertible to string
      service_str = service.to_s
      info += "#{index + 1}. #{service_str}\n"
    end
    info += "\n"
  end

  def format_cost_calculation(cost_data)
    return "" unless cost_data && !cost_data.empty?

    info = "\n💰 **Расчет стоимости:**\n"
    has_data = false

    if cost_data[:services] && !cost_data[:services].empty?
      Array(cost_data[:services]).each do |service|
        # Ensure service is a hash with expected keys
        if service.is_a?(Hash)
          service_name = service[:name] || service['name'] || 'Неизвестная услуга'
          service_price = service[:price] || service['price'] || 'по запросу'
          info += "• #{service_name}: #{service_price}\n"
        else
          info += "• #{service.to_s}\n"
        end
      end
      has_data = true
    end

    if cost_data[:total]
      info += "• **Итого базовая стоимость:** #{cost_data[:total]}\n"
      has_data = true
    end

    note = cost_data[:note] || 'Окончательная стоимость определяется после диагностики'
    info += "• *#{note}*\n"
    has_data = true

    info += "\n" if has_data
    info
  end

  def format_dialog_context(context)
    return "" unless context && !context.to_s.strip.empty?

    info = "\n💬 **Контекст диалога:**\n"
    info += "#{context}\n\n"
    info
  end

  def format_total_cost_to_user
    total_cost = @enriched_data[:total_cost_to_user]
    return "" unless total_cost && !total_cost.to_s.strip.empty?

    info = "\n💰 **Общая стоимость названная клиенту:**\n"
    info += "• **#{total_cost}**\n"
    info += "• *Окончательная стоимость определяется после диагностики*\n\n"
    info
  end

  def format_conversation_summary
    summary = @enriched_data[:conversation_summary]
    return "" unless summary && !summary.to_s.strip.empty?

    info = "\n📝 **Выжимка из переписки:**\n"
    info += "#{summary}\n\n"
    info
  end

  def format_action_buttons(user_id = nil)
    "" # "\n🔗 **Действия:**\n/answer_#{user_id} - Ответить клиенту\n/close_#{user_id} - Закрыть заявку\n"
  end

  # Безопасные версии методов форматирования (уровень C защиты)

  def format_basic_info_safe(request_info, username, name)
    begin
      user_display = name.to_s.strip.empty? ? "Анонимный пользователь" : name.to_s.strip

      notification = "🔔 **НОВАЯ ЗАЯВКА**\n\n"
      notification += "👤 **Клиент:** #{user_display}\n"

      # Добавляем дополнительную информацию если она есть
      if name && !name.to_s.strip.empty?
        notification += "📝 **Имя:** #{name}\n"
      end

      notification += "\n"

      # Сохраняем обратную совместимость со старым форматом (с защитой)
      if request_info[:matched_patterns] && !request_info[:matched_patterns].empty?
        notification += "🔍 **Распознанные паттерны:**\n"
        patterns = Array(request_info[:matched_patterns]).first(3)
        patterns.each do |pattern|
          pattern_str = pattern.to_s
          type, pattern_text = pattern_str.split(':', 2)
          notification += "• #{type}: `#{pattern_text}`\n"
        end
        notification += "\n"
      end

      # Защита от отсутствия original_text
      original_text = request_info[:original_text].to_s.strip
      original_text = "[текст отсутствует]" if original_text.empty?

      notification += "💬 **Сообщение:**\n"
      notification += "```\n#{original_text}\n```\n\n"

      notification
    rescue StandardError => e
      Application.instance.logger.error "Error in format_basic_info_safe: #{e.message}"
      "🔔 **НОВАЯ ЗАЯВКА**\n\n👤 **Клиент:** [ошибка форматирования]\n\n💬 **Сообщение:** [не удалось отформатировать]\n\n"
    end
  end

  def format_car_info_safe(car_info)
    return "" unless car_info && !car_info.to_s.strip.empty? && car_info.respond_to?(:empty?)

    begin
      info = "\n🚗 **Информация об автомобиле:**\n"
      has_data = false

      if car_info[:make_model]
        info += "• **Марка и модель:** #{car_info[:make_model]}\n"
        has_data = true
      end

      if car_info[:year]
        info += "• **Год выпуска:** #{car_info[:year]}\n"
        has_data = true
      end

      if car_info[:car_class]
        class_desc = car_info[:class_description] || car_info[:car_class]
        info += "• **Класс автомобиля:** #{class_desc}\n"
        has_data = true
      else
        info += "• **Класс автомобиля:** требуется уточнение\n"
        has_data = true
      end

      if car_info[:mileage]
        info += "• **Пробег:** #{car_info[:mileage]}\n"
        has_data = true
      end

      info += "\n" if has_data
      info
    rescue StandardError => e
      Application.instance.logger.error "Error in format_car_info_safe: #{e.message}"
      "\n🚗 **Информация об автомобиле:** [ошибка форматирования]\n\n"
    end
  end

  def format_required_services_safe(services)
    return "" unless services && !services.to_s.strip.empty?

    begin
      info = "\n🔧 **Необходимые работы:**\n"
      Array(services).each_with_index do |service, index|
        service_str = service.to_s.strip
        next if service_str.empty?
        info += "#{index + 1}. #{service_str}\n"
      end
      info += "\n"
      info
    rescue StandardError => e
      Application.instance.logger.error "Error in format_required_services_safe: #{e.message}"
      "\n🔧 **Необходимые работы:** [ошибка форматирования]\n\n"
    end
  end

  def format_total_cost_to_user_safe
    total_cost = @enriched_data[:total_cost_to_user]
    return "" unless total_cost && !total_cost.to_s.strip.empty?

    begin
      info = "\n💰 **Общая стоимость названная клиенту:**\n"
      info += "• **#{total_cost}**\n"
      info += "• *Окончательная стоимость определяется после диагностики*\n\n"
      info
    rescue StandardError => e
      Application.instance.logger.error "Error in format_total_cost_to_user_safe: #{e.message}"
      "\n💰 **Общая стоимость названная клиенту:** [ошибка форматирования]\n\n"
    end
  end

  def format_conversation_summary_safe
    summary = @enriched_data[:conversation_summary]
    return "" unless summary && !summary.to_s.strip.empty?

    begin
      info = "\n📝 **Выжимка из переписки:**\n"
      info += "#{summary}\n\n"
      info
    rescue StandardError => e
      Application.instance.logger.error "Error in format_conversation_summary_safe: #{e.message}"
      "\n📝 **Выжимка из переписки:** [ошибка форматирования]\n\n"
    end
  end

  def format_dialog_context_safe(context)
    return "" unless context && !context.to_s.strip.empty?

    begin
      info = "\n💬 **Контекст диалога:**\n"
      info += "#{context}\n\n"
      info
    rescue StandardError => e
      Application.instance.logger.error "Error in format_dialog_context_safe: #{e.message}"
      "\n💬 **Контекст диалога:** [ошибка форматирования]\n\n"
    end
  end

  def format_action_buttons_safe
    begin
      "" # "\n🔗 **Действия:**\n/answer_#{user_id} - Ответить клиенту\n/close_#{user_id} - Закрыть заявку\n"
    rescue StandardError => e
      Application.instance.logger.error "Error in format_action_buttons_safe: #{e.message}"
      ""
    end
  end

  def sanitize_markdown(text)
    return text unless text && !text.empty?

    begin
      # Используем CommonMarker для валидации и исправления Markdown
      Application.instance.logger.debug "🔍 SANITIZING MARKDOWN: Input length #{text.length} chars"

      # Парсим и рендерим через CommonMarker для исправления структуры
      doc = Commonmarker.parse(text)
      sanitized = doc.to_commonmark

      # Дополнительная очистка для Telegram API
      sanitized = sanitize_for_telegram(sanitized)

      Application.instance.logger.debug "🔍 SANITIZED MARKDOWN: Output length #{sanitized.length} chars"
      sanitized

    rescue StandardError => e
      Application.instance.logger.error "Commonmarker sanitization failed: #{e.message}, using fallback"
      # Fallback к базовой очистке
      sanitize_for_telegram(text)
    end
  end

  def sanitize_for_telegram(text)
    return text unless text && !text.empty?

    sanitized = text.dup

    # Удаляем управляющие символы которые могут сломать Telegram API
    sanitized.gsub!(/[\u0000-\u001F\u007F-\u009F]/, '')   # Управляющие символы
    sanitized.gsub!(/[\u2028\u2029]/, ' ')                # Line separator и paragraph separator
    sanitized.gsub!(/[\uFFFE\uFFFF]/, '')                 # Invalid Unicode

    # Удаляем пустые строки в конце
    sanitized.rstrip!

    sanitized
  rescue StandardError => e
    Application.instance.logger.error "Error in telegram sanitization: #{e.message}"
    text
  end

  def log_telegram_api_error(error, request_info, username, name)
    # Детальное trace логирование при ошибке Telegram API
    Application.instance.logger.error "🔍 TELEGRAM API ERROR TRACE:"
    Application.instance.logger.error "  Error: #{error.message}"
    Application.instance.logger.error "  Error code: #{error.instance_variable_get(:@error_code) if error.instance_variable_defined?(:@error_code)}"
    Application.instance.logger.error "  Description: #{error.instance_variable_get(:@description) if error.instance_variable_defined?(:@description)}"

    # Логируем вызова из стека
    Application.instance.logger.error "  Call stack:"
    caller_locations(0, 5).each do |loc|
      Application.instance.logger.error "    #{loc.path}:#{loc.lineno} in #{loc.label}"
    end

    # Если ошибка парсинга Markdown, логируем текст
    if error.message.include?("can't parse entities")
      notification = format_admin_notification_safe(request_info, username, name)
      Application.instance.logger.error "  Failed text length: #{notification&.bytesize} bytes"
      Application.instance.logger.error "  Failed text preview (first 500 chars):"
      Application.instance.logger.error "    #{notification&.truncate(500).inspect}"

      # Ищем проблемные символы в районе указанного offset
      if match = error.message.match(/byte offset (\d+)/)
        offset = match[1].to_i
        Application.instance.logger.error "  Problem area around byte offset #{offset}:"
        notification&.chars.each_with_index do |char, i|
          if i >= [offset - 50, 0].max && i <= offset + 50
            byte_pos = notification.byteslice(0, i).bytesize
            indicator = (byte_pos == offset) ? "👉" : "  "
            Application.instance.logger.error "    #{indicator} [#{i}] #{char.inspect} (byte pos: #{byte_pos})"
          end
        end
      end
    end
  end
end
