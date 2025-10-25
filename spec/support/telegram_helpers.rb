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