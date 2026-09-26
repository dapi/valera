# frozen_string_literal: true

# LLM инструмент для создания заявок на автосервис
#
# Инструмент определяет является ли сообщение клиента заявкой на услугу и создает
# соответствующую запись в системе. Автоматически извлекает данные о клиенте,
# автомобиле и услугах, отправляет уведомления и отслеживает аналитику.
#
# @example Базовое использование
#   tool = BookingTool.new(chat: chat)
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
# @author Danil Pismenny
# @since 0.1.0
class BookingTool < RubyLLM::Tool
  include ErrorLogger
  include DevelopmentWarning

  description 'Определяет является ли сообщение клиента заявкой на услугу и отправляет ее в административный чат'

  parameter :customer_name, description: 'Полное имя клиента', required: false
  parameter :customer_phone, description: 'Телефон клиента в формате +7(XXX)XXX-XX-XX', required: false
  parameter :car_brand, description: 'Марка автомобиля', required: false
  parameter :car_model, description: 'Модель автомобиля', required: false
  parameter :car_year, description: 'Год выпуска автомобиля', required: false
  parameter :car_class, description: 'Класс автомаобиля', required: false
  parameter :car_mileage, description: 'Пробег автомобиля', required: false
  parameter :required_services, description: 'Перечень необходимых работ', required: false
  parameter :cost_calculation, description: 'Последний названный пользователю расчет стоимости услуг (общая стоимость услуг)',
                               required: false
  parameter :dialog_context,
            description: 'Контекст диалога для понимания ситуации (включает данные о клиенте, ' \
                         'дате и времени записи и об услуге которые пользователь запрашивал ' \
                         'и получал от ассистента)', required: true
  parameter :details,
            description: 'Детали записи в формате Markdown включающие все необходимые данные ' \
                         'о пользователе, услуге, стоимости, автомобиле, последние сообщения ' \
                         'пользователя и суммаризованную переписку, номер заявки', required: true

  # Инициализирует инструмент с чатом
  #
  # @param chat [Chat] чат для сохранения контекста (содержит client и tenant)
  # @return [BookingTool] новый экземпляр инструмента
  # @example
  #   tool = BookingTool.new(chat: Chat.find(1))
  def initialize(chat:)
    super()
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
  # @return [String] ответ системы с номером заявки или ошибкой
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
                tenant: @chat.tenant,
                client: @chat.client,
                chat: @chat,
                details: meta[:details],
                context: meta[:dialog_context]
              )

    # Track booking creation analytics
    AnalyticsService.track_conversion(
      AnalyticsService::Events::BOOKING_CREATED,
      tenant: @chat.tenant,
      chat_id: telegram_user.chat_id,
      conversion_data: {
        booking_id: booking.id,
        processing_time_ms: ((Time.current - start_time) * 1000).to_i,
        user_segment: UserSegmentationService.determine_segment_for_chat(@chat)
      }
    )

    response_text = "Заявка под номером #{booking.public_number} отправлена администратору"

    # Добавляем предупреждение о development режиме
    if development_warnings_enabled?
      response_text += "\n\n#{I18n.t('development_warning.booking_suffix')}"
    end

    response_text
  rescue StandardError => e
    log_error e
    AnalyticsService.track_error(e, tenant: @chat.tenant, context: {
      chat_id: @chat.id,
      context: 'booking_tool_execution',
      booking_data: meta
    })
    "Ошибка при обработке заявки: #{e.message}"
  end

  private

  # Возвращает telegram_user через chat.client
  #
  # @return [TelegramUser, nil] пользователь Telegram или nil
  def telegram_user
    @chat.telegram_user
  end
end
