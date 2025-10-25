require 'rails_helper'

RSpec.describe BookingNotificationJob, type: :job do
  let(:telegram_user) { telegram_users(:one) }
  let(:chat) { chats(:one) }
  let(:booking) { bookings(:one) }

  describe '#perform' do
    context 'when booking and telegram_user exist' do
      before do
        allow(ApplicationConfig).to receive(:admin_chat_id).and_return(-123456789)
      end

      it 'sends notification to admin chat' do
        # Используем встроенные stubs из telegram-bot gem
        client = stub_telegram_bot_client
        expect(client).to receive(:send_message) do |params|
          expect(params[:chat_id]).to eq(-123456789)
          expect(params[:text]).to include('НОВАЯ ЗАЯВКА НА ОСМОТР')
          expect(params[:text]).to include('Иван Петров')
          expect(params[:text]).to include('+7(916)123-45-67')
          expect(params[:text]).to include('Toyota Camry, 2018')
          expect(params[:text]).to include('2025-10-27 в 10:00')
          expect(params[:parse_mode]).to eq('HTML')
        end

        BookingNotificationJob.perform_now(booking)
      end
    end

    context 'when booking is nil' do
      it 'does not send notification' do
        client = stub_telegram_bot_client
        expect(client).not_to receive(:send_message)

        BookingNotificationJob.perform_now(nil)
      end
    end

    context 'when telegram_user is nil' do
      let(:booking_without_user) { Booking.new(telegram_user: nil, chat: nil, meta: {}) }

      it 'does not send notification' do
        client = stub_telegram_bot_client
        expect(client).not_to receive(:send_message)

        BookingNotificationJob.perform_now(booking_without_user)
      end
    end

    context 'when admin_chat_id is not configured' do
      before do
        allow(ApplicationConfig).to receive(:admin_chat_id).and_return(nil)
      end

      it 'does not send notification' do
        client = stub_telegram_bot_client
        expect(client).not_to receive(:send_message)

        BookingNotificationJob.perform_now(booking)
      end
    end

    context 'when Telegram API fails' do
      before do
        allow(ApplicationConfig).to receive(:admin_chat_id).and_return(-123456789)
        allow(Rails.logger).to receive(:error)
        allow(Bugsnag).to receive(:notify)

        client = stub_telegram_bot_client
        allow(client).to receive(:send_message).and_raise(StandardError, 'Telegram API error')
      end

      it 'logs error and notifies Bugsnag' do
        expect(Rails.logger).to receive(:error).with(/BookingNotificationJob failed for booking/)
        expect(Bugsnag).to receive(:notify)

        # Тестируем напрямую метод send_notification_to_managers чтобы обойти retry_on
        job = BookingNotificationJob.new
        expect {
          job.send(:send_notification_to_managers, booking)
        }.to raise_error(StandardError, 'Telegram API error')
      end
    end
  end

  describe 'message formatting' do

    describe '#format_manager_notification' do
      it 'formats complete notification' do
        job = BookingNotificationJob.new
        message = job.send(:format_manager_notification, booking)

        expect(message).to include('<b>НОВАЯ ЗАЯВКА НА ОСМОТР</b>')
        expect(message).to include('<b>Клиент:</b> Иван Петров')
        expect(message).to include('<b>Телефон:</b> +7(916)123-45-67')
        expect(message).to include('<b>Автомобиль:</b> Toyota Camry, 2018')
        expect(message).to include('<b>Время записи:</b> 2025-10-27 в 10:00')
        expect(message).to include('<b>Адрес:</b> г. Чебоксары, Ядринское ш., 3')
        expect(message).to include('<b>ID заявки:</b> #1')
        expect(message).to include('<b>СРОЧНО:</b> Перезвонить клиенту в течение часа для подтверждения!')
      end

      context 'when chat has dialogue history' do
        before do
          # Создаем сообщения в чате
          Message.create!(chat: chat, role: 'user', content: 'Здравствуйте, хочу записаться на ремонт')
          Message.create!(chat: chat, role: 'assistant', content: 'Здравствуйте! Чем могу помочь?')
          Message.create!(chat: chat, role: 'user', content: 'У меня Toyota Camry 2018 года')
        end

        it 'includes dialogue context' do
          job = BookingNotificationJob.new
          message = job.send(:format_manager_notification, booking)

          expect(message).to include('<b>История диалога:</b>')
          expect(message).to include('Клиент: Здравствуйте, хочу записаться на ремонт')
          expect(message).to include('Бот: Здравствуйте! Чем могу помочь?')
          expect(message).to include('Клиент: У меня Toyota Camry 2018 года')
        end
      end

      context 'when there is no chat or messages' do
        let(:booking_without_chat) { Booking.new(id: 999, telegram_user: telegram_user, chat: nil, meta: booking.meta) }

        it 'shows context unavailable' do
          job = BookingNotificationJob.new
          message = job.send(:format_manager_notification, booking_without_chat)

          expect(message).to include('<b>История диалога:</b>')
          expect(message).to include('Контекст недоступен')
        end
      end
    end

    describe '#format_car_info' do
      it 'formats complete car info' do
        car_info = { 'brand' => 'Toyota', 'model' => 'Camry', 'year' => 2018 }
        job = BookingNotificationJob.new
        result = job.send(:format_car_info, car_info)
        expect(result).to eq('Toyota Camry, 2018')
      end

      it 'handles missing brand' do
        car_info = { 'model' => 'Camry', 'year' => 2018 }
        job = BookingNotificationJob.new
        result = job.send(:format_car_info, car_info)
        expect(result).to eq('Неизвестно Camry, 2018')
      end

      it 'handles missing model' do
        car_info = { 'brand' => 'Toyota', 'year' => 2018 }
        job = BookingNotificationJob.new
        result = job.send(:format_car_info, car_info)
        expect(result).to eq('Toyota Неизвестно, 2018')
      end

      it 'handles missing year' do
        car_info = { 'brand' => 'Toyota', 'model' => 'Camry' }
        job = BookingNotificationJob.new
        result = job.send(:format_car_info, car_info)
        expect(result).to eq('Toyota Camry, Неизвестно')
      end

      it 'handles non-hash car_info' do
        job = BookingNotificationJob.new
        result = job.send(:format_car_info, 'invalid')
        expect(result).to eq('Не указано')
      end
    end

    describe '#format_preferred_time' do
      it 'formats complete date and time' do
        job = BookingNotificationJob.new
        result = job.send(:format_preferred_time, booking)
        expect(result).to eq('2025-10-27 в 10:00')
      end

      it 'handles missing date' do
        booking_without_date = Booking.new(meta: booking.meta.merge('preferred_date' => nil, 'preferred_time' => '10:00'))
        job = BookingNotificationJob.new
        result = job.send(:format_preferred_time, booking_without_date)
        expect(result).to eq('Как можно скорее в 10:00')
      end

      it 'handles missing time' do
        booking_without_time = Booking.new(meta: booking.meta.merge('preferred_date' => '2025-10-27', 'preferred_time' => nil))
        job = BookingNotificationJob.new
        result = job.send(:format_preferred_time, booking_without_time)
        expect(result).to eq('2025-10-27 в Любое время')
      end

      it 'handles both missing' do
        booking_without_both = Booking.new(meta: booking.meta.merge('preferred_date' => nil, 'preferred_time' => nil))
        job = BookingNotificationJob.new
        result = job.send(:format_preferred_time, booking_without_both)
        expect(result).to eq('Как можно скорее в Любое время')
      end
    end
  end
end