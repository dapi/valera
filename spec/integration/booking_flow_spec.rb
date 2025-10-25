require 'rails_helper'

RSpec.describe 'Booking Flow Integration', type: :integration do
  fixtures :telegram_users, :chats

  let(:telegram_user) { telegram_users(:one) }
  let(:chat) { chats(:one) }

  describe 'Complete booking flow' do
    let(:booking_parameters) do
      {
        customer_name: 'Иван Петров',
        customer_phone: '+79161234567',
        car_info: { brand: 'Toyota', model: 'Camry', year: 2018 },
        preferred_date: '2025-10-27',
        preferred_time: '10:00'
      }
    end

    it 'creates booking through real BookingCreatorTool integration' do
      # Мокируем только внешние зависимости
      allow(BookingNotificationJob).to receive(:perform_later)

      # Вызываем реальный BookingCreatorTool напрямую
      result = BookingCreatorTool.call(
        parameters: booking_parameters,
        context: {
          telegram_user: telegram_user,
          chat: chat
        }
      )

      # Проверяем успешный результат
      expect(result[:success]).to be true
      expect(result[:booking_id]).to be_present

      # Проверяем, что запись создана с правильными данными
      booking = Booking.find(result[:booking_id])
      expect(booking.telegram_user).to eq(telegram_user)
      expect(booking.chat).to eq(chat)
      expect(booking.meta['customer_name']).to eq('Иван Петров')
      expect(booking.meta['customer_phone']).to eq('+7(916)123-45-67') # проверка нормализации
      expect(booking.meta['car_info']).to include('brand' => 'Toyota', 'model' => 'Camry', 'year' => 2018)

      # Проверяем, что job был запланирован
      expect(BookingNotificationJob).to have_received(:perform_later).with(booking)
    end

    it 'handles booking creation with invalid parameters' do
      initial_count = Booking.count

      invalid_parameters = {
        customer_name: '',  # Пустое имя
        customer_phone: '123',  # Невалидный телефон
        car_info: nil  # Отсутствует информация об авто
      }

      result = BookingCreatorTool.call(
        parameters: invalid_parameters,
        context: {
          telegram_user: telegram_user,
          chat: chat
        }
      )

      # Проверяем, что результат содержит ошибку
      expect(result[:success]).to be false
      expect(result[:message]).to include('Не удалось создать запись')

      # Проверяем, что количество записей не изменилось
      expect(Booking.count).to eq(initial_count)
    end

    it 'normalizes phone numbers correctly' do
      phone_formats = [
        '+79161234567',
        '79161234567',
        '8(916)123-45-67',
        '9161234567'
      ]

      phone_formats.each do |phone_format|
        initial_count = Booking.count

        parameters = booking_parameters.merge(customer_phone: phone_format)

        result = BookingCreatorTool.call(
          parameters: parameters,
          context: {
            telegram_user: telegram_user,
            chat: chat
          }
        )

        # Проверяем, что была создана новая запись
        expect(Booking.count).to eq(initial_count + 1)

        # Находим последнюю созданную запись
        booking = Booking.last
        expect(booking.meta['customer_phone']).to match(/\+7\(\d{3}\)\d{3}-\d{2}-\d{2}/)
      end
    end
  end

  describe 'Tool registration in Chat model' do
    it 'registers booking_creator tool with correct schema' do
      tools = Chat.booking_tools
      booking_tool = tools.find { |t| t[:name] == 'booking_creator' }

      expect(booking_tool).not_to be_nil
      expect(booking_tool[:description]).to eq('Создает запись клиента на осмотр в автосервис через естественный диалог')
      expect(booking_tool[:input_schema][:type]).to eq('object')
      expect(booking_tool[:input_schema][:properties]).to have_key(:customer_name)
      expect(booking_tool[:input_schema][:properties]).to have_key(:customer_phone)
      expect(booking_tool[:input_schema][:properties]).to have_key(:car_info)
      expect(booking_tool[:input_schema][:properties]).to have_key(:preferred_date)
      expect(booking_tool[:input_schema][:properties]).to have_key(:preferred_time)
      expect(booking_tool[:input_schema][:required]).to include("customer_name", "customer_phone", "car_info")
    end

    it 'includes car_info schema with brand, model, year properties' do
      tools = Chat.booking_tools
      booking_tool = tools.find { |t| t[:name] == 'booking_creator' }
      car_info_schema = booking_tool[:input_schema][:properties][:car_info]

      expect(car_info_schema[:type]).to eq('object')
      expect(car_info_schema[:properties]).to have_key(:brand)
      expect(car_info_schema[:properties]).to have_key(:model)
      expect(car_info_schema[:properties]).to have_key(:year)
      expect(car_info_schema[:required]).to include("brand", "model", "year")
    end
  end

  describe 'System prompt integration' do
    it 'contains booking creator instructions' do
      system_prompt = File.read(Rails.root.join('data', 'system-prompt.md'))

      expect(system_prompt).to include('Создание записи на осмотр через Booking Creator Tool')
      expect(system_prompt).to include('Когда использовать booking_creator tool')
      expect(system_prompt).to include('Алгоритм работы')
      expect(system_prompt).to include('Временные слота')
      expect(system_prompt).to include('Параметры для booking_creator')
    end

    it 'specifies correct time slots' do
      system_prompt = File.read(Rails.root.join('data', 'system-prompt.md'))

      expect(system_prompt).to include('**Утро:** 10:00-11:00')
      expect(system_prompt).to include('**День:** 14:00-15:00')
      expect(system_prompt).to include('**Вечер:** 16:00-17:00')
      expect(system_prompt).to include('**Будни:** 9:00-20:00')
      expect(system_prompt).to include('**Суббота:** 9:00-18:00')
      expect(system_prompt).to include('**Воскресенье:** выходной')
    end
  end

  describe 'Database relationships and constraints' do
      let(:booking_parameters) do
        {
          customer_name: 'Иван Петров',
          customer_phone: '+79161234567',
          car_info: { brand: 'Toyota', model: 'Camry', year: 2018 },
          preferred_date: '2025-10-27',
          preferred_time: '10:00'
        }
      end

      it 'maintains proper relationships between booking, user and chat' do
        allow(BookingNotificationJob).to receive(:perform_later)

        initial_count = Booking.count
        initial_user_bookings = Booking.where(telegram_user: telegram_user).count

        # Create booking for first chat
        result1 = BookingCreatorTool.call(
          parameters: booking_parameters,
          context: {
            telegram_user: telegram_user,
            chat: chat
          }
        )

        # Create second booking for same user, different chat
        chat2 = chats(:two)
        result2 = BookingCreatorTool.call(
          parameters: booking_parameters.merge(customer_name: 'Петр Иванов'),
          context: {
            telegram_user: telegram_user,
            chat: chat2
          }
        )

        # Проверяем, что добавилось 2 записи
        expect(Booking.count).to eq(initial_count + 2)
        expect(Booking.where(telegram_user: telegram_user).count).to eq(initial_user_bookings + 2)

        # Verify specific relationships
        booking1 = Booking.joins(:chat).where(chats: { id: chat.id }).last
        booking2 = Booking.joins(:chat).where(chats: { id: chat2.id }).last

        expect(booking1.chat).to eq(chat)
        expect(booking2.chat).to eq(chat2)
        expect(booking1.telegram_user).to eq(booking2.telegram_user)
      end
  end

  describe 'Error handling and logging' do
      let(:booking_parameters) do
        {
          customer_name: 'Иван Петров',
          customer_phone: '+79161234567',
          car_info: { brand: 'Toyota', model: 'Camry', year: 2018 },
          preferred_date: '2025-10-27',
          preferred_time: '10:00'
        }
      end

      it 'handles errors gracefully and logs them' do
        allow(Rails.logger).to receive(:error)
        allow(Bugsnag).to receive(:notify)

        # Force an error by passing invalid context (nil telegram_user)
        result = BookingCreatorTool.call(
          parameters: booking_parameters,
          context: {
            telegram_user: nil,
            chat: chat
          }
        )

        # Verify error handling
        expect(result[:success]).to be false
        expect(result[:message]).to include('Не удалось создать запись')
      end
  end
end