require 'rails_helper'

RSpec.describe BookingNotificationJob, type: :job do
  fixtures :bookings

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
        expect(Telegram.bot).to receive(:send_message) do |params|
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
  end
end
