# frozen_string_literal: true

# BookingTool - LLM инструмент для создания заявок на автосервис
#
# Назначение: Определяет является ли сообщение клиента заявкой на услугу и создает запись в системе
# Реализовано в рамках: US-002b, TDD-002b - Telegram Recording + Booking
class BookingTool < RubyLLM::Tool
  include ErrorLogger

  description "Определяет является ли сообщение клиента заявкой на услугу и отправляет ее в административный чат"

  param :user_name, desc: "Имя пользователя", required: false
  param :phone, desc: "Телефон пользователя", required: false
  param :car_brand, desc: "Марка автомобиля", required: false
  param :car_model, desc: "Модель автомобиля", required: false
  param :car_class, desc: "Класс автомаобиля", required: false
  param :car_mileage, desc: "Пробег автомобиля", required: false
  param :required_services, desc: "Перечень необходимых работ", required: false
  #param :total_cost_to_user, desc: "Последняя названная пользователю общая стоимость услуг", required: false
  param :cost_calculation, desc: "Последний названный пользователю расчет стоимости услуг (общая стоимость услуг)", required: false
  param :dialog_context, desc: "Контекст диалога для понимания ситуации (включает данные о клиете, дате и времени записи и об услуге которые пользователь запрашивал и получал от ассистента)", required: true
  param :details, desc: 'Детали записи в формате Markdown включающие все необходимые данные о пользователе, услуге, стоимости, автомобиле, последние сообщения пользователя и суммаризованную переписку, номер заявки', required: true

  def initialize(telegram_user:, chat:)
    @telegram_user = telegram_user
    @chat = chat
  end

  def execute(**meta)
    booking = Booking.
      create!(
        meta:,
        telegram_user: @telegram_user,
        chat: @chat,
        details: meta[:details],
        context: meta[:dialog_context]
      )

    RubyLLM::Content.new( "Заявка под номером #{booking.id} отправлена администратору" )
  rescue StandardError => e
    debugger
    log_error e
    { error: "Ошибка при обработке заявки: #{e.message}" }
  end

  private

  def send_to_admin_chat(request_info, username, name, admin_chat_id)
    # TODO perform BookingNotificationJob
  end
end
