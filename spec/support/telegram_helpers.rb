require 'telegram/bot/rspec/integration/rails'

RSpec.configure do |config|
  # Configure Telegram client stubs for request tests
  config.around telegram_bot: :rails do |example|
    begin
      Telegram.reset_bots
      Telegram::Bot::ClientStub.stub_all!
      example.run
    ensure
      Telegram.reset_bots
      Telegram::Bot::ClientStub.stub_all!(false)
    end
  end

  # Note: Telegram client is already stubbed in config/initializers for test mode
end

# Helper method for stubbing Telegram bot client in job specs
def stub_telegram_bot_client
  client = double('Telegram::Bot::Client')
  api = double('Telegram::Bot::Api')

  allow(Telegram::Bot::Client).to receive(:new).and_return(client)
  allow(client).to receive(:api).and_return(api)

  api
end