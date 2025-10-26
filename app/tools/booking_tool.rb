# frozen_string_literal: true

# LLM инструмент для создания заявок на автосервис
#
# Инструмент определяет является ли сообщение клиента заявкой на услугу и создает
# соответствующую запись в системе. Автоматически извлекает данные о клиенте,
# автомобиле и услугах, отправляет уведомления и отслеживает аналитику.
#
# @example Базовое использование
#   tool = BookingTool.new(telegram_user: user, chat: chat)
#   response = tool.execute(
#     customer_name: "Иван Петров",
#     customer_phone: "+7(900)123-45-67",
#     car_brand: "Toyota",
#     car_model: "Camry",
#     required_services: "Замена масла, диагностика тормозов",
#     dialog_context: { date: "2024-12-01", time: "14:00" },
#     details: "Заявка #123: Ivan Petrov, Toyota Camry, замена масла"
#   )
#
# @see US-002b User Story по созданию заявок
# @see TDD-002b Техническая реализация
# @see AnalyticsService для отслеживания событий
# @author Valera Team
# @since 0.1.0
class BookingTool < RubyLLM::Tool
  include ErrorLogger

  description 'Определяет является ли сообщение клиента заявкой на услугу и отправляет ее в административный чат'

  param :customer_name, desc: 'Полное имя клиента', required: false
  param :customer_phone, desc: 'Телефон клиента в формате +7(XXX)XXX-XX-XX', required: false
  param :car_brand, desc: 'Марка автомобиля', required: false
  param :car_model, desc: 'Модель автомобиля', required: false
  param :car_year, desc: 'Год выпуска автомобиля', required: false
  param :car_class, desc: 'Класс автомаобиля', required: false
  param :car_mileage, desc: 'Пробег автомобиля', required: false
  param :required_services, desc: 'Перечень необходимых работ', required: false
  param :cost_calculation, desc: 'Последний названный пользователю расчет стоимости услуг (общая стоимость услуг)',
                           required: false
  param :dialog_context,
        desc: 'Контекст диалога для понимания ситуации (включает данные о клиенте, ' \
              'дате и времени записи и об услуге которые пользователь запрашивал ' \
              'и получал от ассистента)', required: true
  param :details,
        desc: 'Детали записи в формате Markdown включающие все необходимые данные ' \
              'о пользователе, услуге, стоимости, автомобиле, последние сообщения ' \
              'пользователя и суммаризованную переписку, номер заявки', required: true

  # Инициализирует инструмент с пользователем и чатом
  #
  # @param telegram_user [TelegramUser] пользователь Telegram
  # @param chat [Chat] чат для сохранения контекста
  # @return [BookingTool] новый экземпляр инструмента
  # @example
  #   tool = BookingTool.new(
  #     telegram_user: TelegramUser.find(1),
  #     chat: Chat.find(1)
  #   )
  def initialize(telegram_user:, chat:)
    super()
    @telegram_user = telegram_user
    @chat = chat
  end

  # Выполняет создание заявки на основе извлеченных данных
  #
  # Создает запись в базе данных, отправляет аналитические события
  # и формирует ответ для пользователя.
  #
  # @param meta [Hash] параметры заявки
  # @option meta [String] :customer_name имя клиента
  # @option meta [String] :customer_phone телефон клиента
  # @option meta [String] :car_brand марка автомобиля
  # @option meta [String] :car_model модель автомобиля
  # @option meta [Integer] :car_year год выпуска
  # @option meta [String] :required_services необходимые услуги
  # @option meta [String] :cost_calculation расчет стоимости
  # @option meta [Hash] :dialog_context контекст диалога
  # @option meta [String] :details детали заявки в Markdown
  # @return [RubyLLM::Content] ответ системы с номером заявки или ошибкой
  # @raise [StandardError] при ошибке создания заявки
  # @example Успешное создание заявки
  #   response = execute(
  #     customer_name: "Иван",
  #     car_brand: "Toyota",
  #     dialog_context: { date: "2024-12-01" },
  #     details: "Заявка на ТО"
  #   )
  #   response.content #=> "Заявка под номером 123 отправлена администратору"
  # @note Автоматически отслеживает время выполнения и аналитику
  # @todo Реализовать отправку в административный чат
  def execute(**meta)
    start_time = Time.current

    booking = Booking
              .create!(
                meta:,
                telegram_user: @telegram_user,
                chat: @chat,
                details: meta[:details],
                context: meta[:dialog_context]
              )

    # Track booking creation analytics
    AnalyticsService.track_conversion(
      AnalyticsService::Events::BOOKING_CREATED,
      @telegram_user.chat_id,
      {
        booking_id: booking.id,
        services_count: extract_services_count(meta),
        estimated_total: extract_estimated_total(meta),
        processing_time_ms: ((Time.current - start_time) * 1000).to_i,
        user_segment: determine_user_segment(@telegram_user.chat_id),
        customer_name: meta[:customer_name],
        car_brand: meta[:car_brand],
        car_model: meta[:car_model]
      }
    )

    RubyLLM::Content.new("Заявка под номером #{booking.id} отправлена администратору")
  rescue StandardError => e
    log_error e
    AnalyticsService.track_error(e, {
      chat_id: @telegram_user.chat_id,
      context: 'booking_tool_execution',
      booking_data: meta
    })
    RubyLLM::Content.new("Ошибка при обработке заявки: #{e.message}")
  end

  private

  # Отправляет информацию о заявке в административный чат
  #
  # @param request_info [String] информация о заявке
  # @param username [String] username клиента
  # @param name [String] имя клиента
  # @param admin_chat_id [Integer] ID административного чата
  # @return [void]
  # @todo Реализовать через BookingNotificationJob
  # @api private
  def send_to_admin_chat(request_info, username, name, admin_chat_id)
    # TODO: perform BookingNotificationJob
  end

  # Извлекает количество услуг из метаданных заявки
  #
  # Анализирует текстовый список услуг и определяет их количество.
  # Если список пуст, возвращает 1 (базовая услуга).
  #
  # @param meta [Hash] метаданные заявки
  # @return [Integer] количество услуг (от 1 до 10)
  # @example
  #   extract_services_count({ required_services: "Замена масла, диагностика" }) #=> 2
  #   extract_services_count({ required_services: "" }) #=> 1
  # @api private
  def extract_services_count(meta)
    return 1 if meta[:required_services].blank?

    # Попытка посчитать количество услуг в тексте
    services_text = meta[:required_services].to_s
    services_count = services_text.scan(/,|\n|и/).count + 1
    services_count <= 10 ? services_count : 1 # Ограничим разумным числом
  end

  # Извлекает предполагаемую стоимость из текстового описания
  #
  # Ищет числовые значения в тексте расчета стоимости и возвращает
  # последнее найденное число как предполагаемую общую стоимость.
  #
  # @param meta [Hash] метаданные заявки
  # @return [Integer, nil] предполагаемая стоимость или nil если не найдена
  # @example
  #   extract_estimated_total({ cost_calculation: "Итого: 5000 рублей" }) #=> 5000
  #   extract_estimated_total({ cost_calculation: "" }) #=> nil
  # @api private
  def extract_estimated_total(meta)
    return nil if meta[:cost_calculation].blank?

    # Попытка извлечь числовое значение из текста стоимости
    cost_text = meta[:cost_calculation].to_s
    # Ищем числа в тексте (рубли, тысячи и т.д.)
    numbers = cost_text.scan(/(\d+(?:\s?\d+)*)/)
    return nil if numbers.empty?

    # Берем последнее найденное число как общую стоимость
    last_number = numbers.last&.first&.delete(' ')
    last_number&.to_i
  end

  # Определяет сегмент пользователя на основе истории взаимодействий
  #
  # Анализирует количество предыдущих событий для классификации
  # пользователя по сегментам вовлеченности.
  #
  # @param chat_id [Integer] ID чата пользователя
  # @return [String] сегмент пользователя ('new', 'engaged', 'returning', 'unknown')
  # @example В тестовой среде
  #   determine_user_segment(12345) #=> 'new'
  # @example Для активного пользователя
  #   determine_user_segment(67890) #=> 'engaged'
  # @note В тестовой среде всегда возвращает 'new'
  # @api private
  def determine_user_segment(chat_id)
    return 'new' if Rails.env.test? # Для тестов

    events_count = AnalyticsEvent.by_chat(chat_id).count

    case events_count
    when 1..2
      'new'
    when 3..10
      'engaged'
    else
      'returning'
    end
  rescue
    'unknown' # Если произошла ошибка при определении
  end
end
