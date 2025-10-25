require 'rails_helper'

RSpec.describe BookingCreatorTool, type: :tool do
  let(:telegram_user) { TelegramUser.new(id: 1, first_name: 'Test', username: 'testuser') }
  let(:chat) { Chat.new(id: 1, telegram_user: telegram_user) }

  describe '.call' do
    context 'with valid parameters' do
      let(:valid_parameters) do
        {
          customer_name: 'Иван Петров',
          customer_phone: '+7(916)123-45-67',
          car_info: { brand: 'Toyota', model: 'Camry', year: 2018 },
          preferred_date: '2025-10-27',
          preferred_time: '10:00'
        }
      end

      let(:context) do
        {
          telegram_user: telegram_user,
          chat: chat
        }
      end

      before do
        allow(Booking).to receive(:new).and_return(double('booking', save: true, id: 1))
        allow(BookingNotificationJob).to receive(:perform_later)
      end

      it 'creates a booking with correct parameters' do
        expect(Booking).to receive(:new) do |args|
          expect(args[:meta][:customer_name]).to eq('Иван Петров')
          expect(args[:meta][:customer_phone]).to eq('+7(916)123-45-67')
          expect(args[:meta][:car_info]).to eq({ brand: 'Toyota', model: 'Camry', year: 2018 })
          expect(args[:meta][:preferred_date]).to eq('2025-10-27')
          expect(args[:meta][:preferred_time]).to eq('10:00')
          expect(args[:telegram_user]).to eq(telegram_user)
          expect(args[:chat]).to eq(chat)
        end.and_return(double('booking', save: true, id: 1))

        result = BookingCreatorTool.call(parameters: valid_parameters, context: context)
        expect(result[:success]).to be true
      end

      it 'enqueues BookingNotificationJob' do
        booking = double('booking', save: true, id: 1)
        allow(Booking).to receive(:new).and_return(booking)

        BookingCreatorTool.call(parameters: valid_parameters, context: context)
        expect(BookingNotificationJob).to have_received(:perform_later).with(booking)
      end

      it 'returns success response with booking details' do
        result = BookingCreatorTool.call(parameters: valid_parameters, context: context)

        expect(result[:success]).to be true
        expect(result[:message]).to include('Запись создана успешно')
        expect(result[:message]).to include('Иван Петров')
        expect(result[:message]).to include('Toyota Camry')
        expect(result[:booking_id]).to eq(1)
      end
    end

    context 'phone number normalization' do
      let(:context) { { telegram_user: telegram_user, chat: chat } }

      before do
        allow(Booking).to receive(:new).and_return(double('booking', save: true, id: 1))
        allow(BookingNotificationJob).to receive(:perform_later)
      end

      it 'normalizes 11-digit phone number starting with 7' do
        parameters = {
          customer_name: 'Иван',
          customer_phone: '79161234567',
          car_info: { brand: 'Toyota', model: 'Camry', year: 2018 }
        }

        expect(Booking).to receive(:new) do |args|
          expect(args[:meta][:customer_phone]).to eq('+7(916)123-45-67')
        end.and_return(double('booking', save: true, id: 1))

        BookingCreatorTool.call(parameters: parameters, context: context)
      end

      it 'normalizes 10-digit phone number' do
        parameters = {
          customer_name: 'Иван',
          customer_phone: '9161234567',
          car_info: { brand: 'Toyota', model: 'Camry', year: 2018 }
        }

        expect(Booking).to receive(:new) do |args|
          expect(args[:meta][:customer_phone]).to eq('+7(916)123-45-67')
        end.and_return(double('booking', save: true, id: 1))

        BookingCreatorTool.call(parameters: parameters, context: context)
      end

      it 'keeps phone as is if format is not recognized' do
        parameters = {
          customer_name: 'Иван',
          customer_phone: 'invalid-phone',
          car_info: { brand: 'Toyota', model: 'Camry', year: 2018 }
        }

        expect(Booking).to receive(:new) do |args|
          expect(args[:meta][:customer_phone]).to eq('invalid-phone')
        end.and_return(double('booking', save: true, id: 1))

        BookingCreatorTool.call(parameters: parameters, context: context)
      end
    end

    context 'when booking fails to save' do
      let(:context) { { telegram_user: telegram_user, chat: chat } }
      let(:booking) { double('booking', save: false, errors: double('errors', full_messages: ['Ошибка валидации'])) }

      before do
        allow(Booking).to receive(:new).and_return(booking)
      end

      it 'returns error response' do
        parameters = {
          customer_name: 'Иван',
          customer_phone: '+7(916)123-45-67',
          car_info: { brand: 'Toyota', model: 'Camry', year: 2018 }
        }

        result = BookingCreatorTool.call(parameters: parameters, context: context)

        expect(result[:success]).to be false
        expect(result[:message]).to include('Не удалось создать запись: Ошибка валидации')
      end
    end
  end

  describe 'success message formatting' do
    let(:booking_data) do
      {
        customer_name: 'Александр Иванов',
        customer_phone: '+7(916)123-45-67',
        car_info: { brand: 'Toyota', model: 'Camry', year: 2018 },
        preferred_date: '2025-10-27',
        preferred_time: '10:00',
        booking_id: '##AB12'
      }
    end

    it 'formats success message with all details' do
      # Проверяем форматирование сообщения через приватный метод
      message = described_class.send(:format_success_message, booking_data)

      expect(message).to include('Запись создана успешно')
      expect(message).to include('Александр Иванов')
      expect(message).to include('+7(916)123-45-67')
      expect(message).to include('Toyota Camry, 2018')
      expect(message).to include('2025-10-27 10:00')
      expect(message).to include('г. Чебоксары, Ядринское ш., 3')
      expect(message).to include('Менеджер перезвонит в течение часа')
      expect(message).to include('##AB12')
    end
  end

  describe 'car info formatting' do
    it 'formats complete car info' do
      car_info = { brand: 'Toyota', model: 'Camry', year: 2018 }
      result = described_class.send(:format_car_info, car_info)
      expect(result).to eq('Toyota Camry, 2018')
    end

    it 'handles missing year' do
      car_info = { brand: 'Toyota', model: 'Camry' }
      result = described_class.send(:format_car_info, car_info)
      expect(result).to eq('Toyota Camry')
    end

    it 'handles missing brand' do
      car_info = { model: 'Camry', year: 2018 }
      result = described_class.send(:format_car_info, car_info)
      expect(result).to eq('Неизвестно Camry, 2018')
    end

    it 'handles empty car info' do
      result = described_class.send(:format_car_info, nil)
      expect(result).to eq('Не указано')
    end
  end
end
