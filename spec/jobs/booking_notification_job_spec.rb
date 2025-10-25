require 'rails_helper'

RSpec.describe BookingNotificationJob, type: :job do
  let(:telegram_user) { TelegramUser.new(id: 1, first_name: 'Test', username: 'testuser') }
  let(:chat) { Chat.new(id: 1, telegram_user: telegram_user) }
  let(:booking) { Booking.new(id: 1, telegram_user: telegram_user, chat: chat, meta: {}) }

  describe '#perform' do
    context 'when booking and telegram_user exist' do
      before do
        allow(ApplicationConfig).to receive(:admin_chat_id).and_return(-123456789)
        allow(booking).to receive(:customer_name).and_return('Иван Петров')
        allow(booking).to receive(:customer_phone).and_return('+7(916)123-45-67')
        allow(booking).to receive(:car_info).and_return({ 'brand' => 'Toyota', 'model' => 'Camry', 'year' => 2018 })
        allow(booking).to receive(:preferred_date).and_return('2025-10-27')
        allow(booking).to receive(:preferred_time).and_return('10:00')
      end

      it 'sends notification to admin chat' do
        bot = double('Telegram::Bot::Client')
        api = double('Telegram::Bot::Api')

        allow(Telegram::Bot::Client).to receive(:new).and_return(bot)
        allow(bot).to receive(:api).and_return(api)

        expect(api).to receive(:send_message) do |params|
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
        bot = double('Telegram::Bot::Client')
        api = double('Telegram::Bot::Api')

        allow(Telegram::Bot::Client).to receive(:new).and_return(bot)
        allow(bot).to receive(:api).and_return(api)

        expect(api).not_to receive(:send_message)

        BookingNotificationJob.perform_now(nil)
      end
    end

    context 'when telegram_user is nil' do
      let(:booking_without_user) { build_stubbed(:booking, telegram_user: nil) }

      it 'does not send notification' do
        bot = double('Telegram::Bot::Client')
        api = double('Telegram::Bot::Api')

        allow(Telegram::Bot::Client).to receive(:new).and_return(bot)
        allow(bot).to receive(:api).and_return(api)

        expect(api).not_to receive(:send_message)

        BookingNotificationJob.perform_now(booking_without_user)
      end
    end

    context 'when admin_chat_id is not configured' do
      before do
        allow(ApplicationConfig).to receive(:admin_chat_id).and_return(nil)
      end

      it 'does not send notification' do
        bot = double('Telegram::Bot::Client')
        api = double('Telegram::Bot::Api')

        allow(Telegram::Bot::Client).to receive(:new).and_return(bot)
        allow(bot).to receive(:api).and_return(api)

        expect(api).not_to receive(:send_message)

        BookingNotificationJob.perform_now(booking)
      end
    end

    context 'when Telegram API fails' do
      before do
        allow(ApplicationConfig).to receive(:admin_chat_id).and_return(-123456789)
        allow(Rails.logger).to receive(:error)
        allow(Bugsnag).to receive(:notify)

        bot = double('Telegram::Bot::Client')
        api = double('Telegram::Bot::Api')

        allow(Telegram::Bot::Client).to receive(:new).and_return(bot)
        allow(bot).to receive(:api).and_return(api)
        allow(api).to receive(:send_message).and_raise(StandardError, 'Telegram API error')
      end

      it 'logs error and notifies Bugsnag' do
        expect(Rails.logger).to receive(:error).with(/BookingNotificationJob failed for booking/)
        expect(Bugsnag).to receive(:notify)

        expect {
          BookingNotificationJob.perform_now(booking)
        }.to raise_error(StandardError, 'Telegram API error')
      end
    end
  end

  describe 'message formatting' do
    before do
      allow(booking).to receive(:customer_name).and_return('Иван Петров')
      allow(booking).to receive(:customer_phone).and_return('+7(916)123-45-67')
      allow(booking).to receive(:preferred_date).and_return('2025-10-27')
      allow(booking).to receive(:preferred_time).and_return('10:00')
    end

    describe '#format_manager_notification' do
      it 'formats complete notification' do
        allow(booking).to receive(:car_info).and_return({ 'brand' => 'Toyota', 'model' => 'Camry', 'year' => 2018 })
        allow(booking).to receive(:id).and_return(42)

        job = BookingNotificationJob.new
        message = job.send(:format_manager_notification, booking)

        expect(message).to include('<b>НОВАЯ ЗАЯВКА НА ОСМОТР</b>')
        expect(message).to include('<b>Клиент:</b> Иван Петров')
        expect(message).to include('<b>Телефон:</b> +7(916)123-45-67')
        expect(message).to include('<b>Автомобиль:</b> Toyota Camry, 2018')
        expect(message).to include('<b>Время записи:</b> 2025-10-27 в 10:00')
        expect(message).to include('<b>Адрес:</b> г. Чебоксары, Ядринское ш., 3')
        expect(message).to include('<b>ID заявки:</b> #42')
        expect(message).to include('<b>СРОЧНО:</b> Перезвонить клиенту в течение часа')
      end

      context 'when chat has dialogue history' do
        let(:message1) { double('Message', role: 'user', content: 'Здравствуйте, хочу записаться на ремонт') }
        let(:message2) { double('Message', role: 'assistant', content: 'Здравствуйте! Чем могу помочь?') }
        let(:message3) { double('Message', role: 'user', content: 'У меня Toyota Camry 2018 года') }

        before do
          allow(booking).to receive(:chat).and_return(chat)
          allow(chat).to receive(:messages).and_return(double('ActiveRecord::Relation'))
          allow(chat.messages).to receive(:order).and_return([message1, message2, message3])
          allow(message1).to receive(:truncate).with(100).and_return('Здравствуйте, хочу записаться на ремонт')
          allow(message2).to receive(:truncate).with(100).and_return('Здравствуйте! Чем могу помочь?')
          allow(message3).to receive(:truncate).with(100).and_return('У меня Toyota Camry 2018 года')
        end

        it 'includes dialogue context' do
          allow(booking).to receive(:car_info).and_return({ 'brand' => 'Toyota', 'model' => 'Camry', 'year' => 2018 })
          allow(booking).to receive(:id).and_return(42)

          job = BookingNotificationJob.new
          message = job.send(:format_manager_notification, booking)

          expect(message).to include('<b>История диалога:</b>')
          expect(message).to include('Клиент: Здравствуйте, хочу записаться на ремонт')
          expect(message).to include('Бот: Здравствуйте! Чем могу помочь?')
          expect(message).to include('Клиент: У меня Toyota Camry 2018 года')
        end
      end

      context 'when there is no chat or messages' do
        before do
          allow(booking).to receive(:chat).and_return(nil)
        end

        it 'shows context unavailable' do
          allow(booking).to receive(:car_info).and_return({ 'brand' => 'Toyota', 'model' => 'Camry', 'year' => 2018 })
          allow(booking).to receive(:id).and_return(42)

          job = BookingNotificationJob.new
          message = job.send(:format_manager_notification, booking)

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
        allow(booking).to receive(:preferred_date).and_return('2025-10-27')
        allow(booking).to receive(:preferred_time).and_return('10:00')

        job = BookingNotificationJob.new
        result = job.send(:format_preferred_time, booking)
        expect(result).to eq('2025-10-27 в 10:00')
      end

      it 'handles missing date' do
        allow(booking).to receive(:preferred_date).and_return(nil)
        allow(booking).to receive(:preferred_time).and_return('10:00')

        job = BookingNotificationJob.new
        result = job.send(:format_preferred_time, booking)
        expect(result).to eq('Как можно скорее в 10:00')
      end

      it 'handles missing time' do
        allow(booking).to receive(:preferred_date).and_return('2025-10-27')
        allow(booking).to receive(:preferred_time).and_return(nil)

        job = BookingNotificationJob.new
        result = job.send(:format_preferred_time, booking)
        expect(result).to eq('2025-10-27 в Любое время')
      end

      it 'handles both missing' do
        allow(booking).to receive(:preferred_date).and_return(nil)
        allow(booking).to receive(:preferred_time).and_return(nil)

        job = BookingNotificationJob.new
        result = job.send(:format_preferred_time, booking)
        expect(result).to eq('Как можно скорее в Любое время')
      end
    end
  end
end