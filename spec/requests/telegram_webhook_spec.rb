require 'rails_helper'
require 'telegram/bot/rspec/integration/rails'

RSpec.describe Telegram::WebhookController, telegram_bot: :rails do
  # Note: Telegram client is already stubbed in config/initializers for test mode

  let(:from_id) { 12345 }
  let(:chat_id) { 12345 }

  describe '#start!' do
    subject { -> { dispatch_command(:start) } }

    it { should respond_with_message(/Здравствуйте/) }
  end

  it 'handles /start command and sends welcome message' do
    expect { dispatch_command(:start) }.
      to make_telegram_request(bot, :sendMessage).
      with(hash_including(text: /Здравствуйте/))
  end
end
