require 'rails_helper'

RSpec.describe TelegramController, type: :request, telegram: true do
  # Note: Telegram client is already stubbed in config/initializers for test mode

  describe 'POST #webhook' do
    context 'with regular text message' do
      let(:update_payload) do
        {
          "update_id": 123456789,
          "message": {
            "message_id": 123,
            "from": {
              "id": 12345,
              "is_bot": false,
              "first_name": "Test",
              "language_code": "en"
            },
            "chat": {
              "id": 12345,
              "first_name": "Test",
              "type": "private"
            },
            "date": 1634567890,
            "text": "Hello bot"
          }
        }.to_json
      end

      it 'processes message without errors' do
        post '/telegram/yX6FeY_EglY4lFePpoBMJ6YG43s', params: update_payload, headers: {'CONTENT_TYPE' => 'application/json'}
        expect(response).to have_http_status(:ok)
      end
    end

    context 'with callback query' do
      let(:callback_payload) do
        {
          "update_id": 123456789,
          "callback_query": {
            "id": "123",
            "from": {
              "id": 12345,
              "is_bot": false,
              "first_name": "Test",
              "language_code": "en"
            },
            "data": "test"
          }
        }.to_json
      end

      it 'processes callback query without errors' do
        post '/telegram/yX6FeY_EglY4lFePpoBMJ6YG43s', params: callback_payload, headers: {'CONTENT_TYPE' => 'application/json'}
        expect(response).to have_http_status(:ok)
      end
    end
  end
end