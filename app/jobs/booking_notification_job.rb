# frozen_string_literal: true

# Job для асинхронной отправки уведомлений о новых заявках в менеджерский чат
class BookingNotificationJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform(booking)
    return unless ApplicationConfig.admin_chat_id.present?

    send_notification_to_managers(booking)
  rescue => e
    Rails.logger.error "BookingNotificationJob failed for booking #{booking.id}: #{e.message}"
    Bugsnag.notify(e)
    raise
  end

  private

  def send_notification_to_managers(booking)
    message = format_manager_notification(booking)

    # Используем Telegram API для отправки сообщения в менеджерский чат
    Telegram.bot.send_message(
      chat_id: ApplicationConfig.admin_chat_id,
      text: message,
      parse_mode: 'HTML'
    )
  end

  def format_manager_notification(booking)
    <<~MESSAGE
      🚗 <b>НОВАЯ ЗАЯВКА НА ОСМОТР</b>

      👤 <b>Клиент:</b> #{booking.customer_name}
      📞 <b>Телефон:</b> #{booking.customer_phone}

      🚗 <b>Автомобиль:</b> #{format_car_info(booking.car_info)}
      ⏰ <b>Время записи:</b> #{format_preferred_time(booking)}

      📝 <b>История диалога:</b>
      #{extract_dialogue_context(booking)}

      🔗 <b>ID заявки:</b> ##{booking.id}
    MESSAGE
  end

  def format_car_info(car_info)
    return "Не указано" unless car_info.is_a?(Hash)

    brand = car_info['brand'] || 'Неизвестно'
    model = car_info['model'] || 'Неизвестно'
    year = car_info['year'] || 'Неизвестно'

    "#{brand} #{model}, #{year}"
  end

  def format_preferred_time(booking)
    date = booking.preferred_date || "Как можно скорее"
    time = booking.preferred_time || "Любое время"

    "#{date} в #{time}"
  end

  def extract_dialogue_context(booking)
    # Извлекаем контекст из сообщений в чате
    return "Контекст недоступен" unless booking.chat

    messages = booking.chat.messages.order(:created_at).last(5)
    return "Нет истории сообщений" if messages.empty?

    context = messages.map do |msg|
      sender = msg.role == 'user' ? 'Клиент' : 'Бот'
      "#{sender}: #{msg.content.truncate(100)}"
    end.join("\n")

    context.truncate(300)
  end
end
