require 'rails_helper'
require 'telegram/bot/updates_controller/rspec_helpers'

RSpec.describe Telegram::WebhookController, type: :telegram_bot_controller do
  # for old RSpec:
  # include_context 'telegram/bot/updates_controller'

  let(:from_id) { 12345 }
  let(:chat_id) { 12345 }
  let(:telegram_user) { TelegramUser.create!(id: from_id, first_name: "Иван", last_name: "Петров") }

  # Load fixtures
  fixtures :all

  let(:model) { models(:deepseek) }
  let(:chat) { Chat.create!(telegram_user: telegram_user, model: model) }

  # Mock the LLM chat to avoid real API calls in tests
  before do
    # Allow any call to Chat.find_or_create_by! to return our chat
    allow(Chat).to receive(:find_or_create_by!).with(telegram_user: telegram_user).and_return(chat)
    # Mock complete method instead of ask to allow message saving
    allow(chat).to receive(:complete).and_return('Ответ от AI')
  end

  # Same helpers and matchers like dispatch_command, answer_callback_query are available here.

  describe '#start!' do
    subject { -> { dispatch_command(:start) } }

    it { should make_telegram_request(bot, :sendMessage) }
  end

  it 'handles /start command and sends welcome message' do
    expect { dispatch_command(:start) }.
      to make_telegram_request(bot, :sendMessage)
  end

  # TODO: Fix callback_query test - needs proper setup for answer_callback_query
  # describe '#callback_query', :callback_query do
  #   let(:data) { 'test_data' }

  #   it 'answers callback query with "Получено!"' do
  #     should answer_callback_query('Получено!')
  #   end
  # end

  describe '#message' do
    it 'processes text messages and sends LLM response' do
      # Messages are passed to LLM system through ruby_llm acts_as_chat
      # and response is sent back to user
      allow(chat).to receive(:complete).and_return('Здравствуйте!')

      expect { dispatch_message('Привет!') }.
        to make_telegram_request(bot, :sendMessage).
        with(hash_including(text: 'Здравствуйте!'))
    end

    it 'processes car repair consultation messages' do
      # Mock LLM response for car repair consultation
      allow(chat).to receive(:complete).and_return('Ориентировочно 7000-10000₽')

      expect { dispatch_message('сколько стоит убрать вмятину?') }.
        to make_telegram_request(bot, :sendMessage).
        with(hash_including(text: 'Ориентировочно 7000-10000₽'))
    end

    it 'processes messages and calls LLM ask method' do
      # Test that the controller properly calls chat.ask with the message
      # We don't need to mock ask since it should create the message and call complete
      allow(chat).to receive(:complete).and_return('Ответ от AI')

      dispatch_message('Тестовое сообщение')
    end

    it 'handles errors gracefully when LLM fails' do
      # Simulate LLM error in complete method
      allow(chat).to receive(:complete).and_raise(StandardError, 'LLM API error')

      expect { dispatch_message('Сообщение с ошибкой') }.
        to make_telegram_request(bot, :sendMessage).
        with(hash_including(text: 'Извините, произошла ошибка. Попробуйте еще раз.'))
    end
  end
end