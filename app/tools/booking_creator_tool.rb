# frozen_string_literal: true

# Tool для создания записи на осмотр через LLM tool calling mechanism
class BookingCreatorTool
  class << self
    def call(parameters:, context:)
      # Создание заявки согласно TDD-002b
      # LLM сама определяет все данные из контекста диалога (Product Constitution compliance)

      # Извлекаем telegram_user и chat из контекста
      telegram_user = context[:telegram_user]
      chat = context[:chat]

      # Формируем данные для записи
      booking_data = {
        customer_name: parameters[:customer_name],
        customer_phone: normalize_phone(parameters[:customer_phone]),
        car_info: parameters[:car_info],
        preferred_date: parameters[:preferred_date],
        preferred_time: parameters[:preferred_time],
        created_at: Time.current.iso8601,
        booking_id: "##{SecureRandom.hex(4).upcase}"
      }

      booking = Booking.new(
        meta: booking_data,
        telegram_user: telegram_user,
        chat: chat
      )

      if booking.save
        # Асинхронная отправка в менеджерский чат
        BookingNotificationJob.perform_later(booking)

        success_response(booking, booking_data)
      else
        error_response("Не удалось создать запись: #{booking.errors.full_messages.join(', ')}")
      end
    rescue => e
      Rails.logger.error "BookingCreatorTool error: #{e.message}"
      Bugsnag.notify(e)
      error_response("Произошла ошибка при создании записи. Попробуйте еще раз.")
    end

    private

    def normalize_phone(phone)
      # Приводим телефон к формату +7(XXX)XXX-XX-XX
      digits = phone.gsub(/\D/, '')
      if digits.length == 11
        formatted = "+7(#{digits[1..3]})#{digits[4..6]}-#{digits[7..8]}-#{digits[9..10]}"
      elsif digits.length == 10
        formatted = "+7(#{digits[0..2]})#{digits[3..5]}-#{digits[6..7]}-#{digits[8..9]}"
      else
        phone # Возвращаем как есть, если формат не распознан
      end
    end

    def success_response(booking, booking_data)
      {
        success: true,
        message: format_success_message(booking_data),
        booking_id: booking.id
      }
    end

    def format_success_message(data)
      <<~MESSAGE
        ✅ **Запись создана успешно!**

        📋 **Детали записи:**
        👤 Имя: #{data[:customer_name]}
        📞 Телефон: #{data[:customer_phone]}
        🚗 Автомобиль: #{format_car_info(data[:car_info])}
        ⏰ Время: #{data[:preferred_date]} #{data[:preferred_time]}

        📍 **Адрес:** г. Чебоксары, Ядринское ш., 3

        📞 **Менеджер перезвонит в течение часа для подтверждения записи!**

        Номер заявки: #{data[:booking_id]}
      MESSAGE
    end

    def format_car_info(car_info)
      return "Не указано" unless car_info.is_a?(Hash)

      brand = car_info['brand'] || car_info[:brand] || 'Неизвестно'
      model = car_info['model'] || car_info[:model] || 'Неизвестно'
      year = car_info['year'] || car_info[:year] || ''

      year_str = year.present? ? ", #{year}" : ""
      "#{brand} #{model}#{year_str}"
    end

    def error_response(message)
      {
        success: false,
        message: "❌ #{message}\n\nПожалуйста, проверьте данные и попробуйте снова или свяжитесь с менеджером напрямую."
      }
    end
  end
end