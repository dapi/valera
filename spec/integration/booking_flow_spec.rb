require 'rails_helper'

RSpec.describe 'Booking Flow Integration', type: :integration, telegram_bot: :rails do
  fixtures :telegram_users, :chats

  let(:telegram_user) { telegram_users(:one) }
  let(:chat) { chats(:one) }

  describe 'Complete booking flow' do
    it 'creates booking through real BookingCreatorTool integration' do
      expect(BookingNotificationJob).to have_received(:perform_later) #.with(booking)

      dispatch_message "Запиши меня на сервис"
      expect(response).to have_http_status(:ok)
      # Пользователь отправляет message в telegram-контроллер
    end
  end
end
