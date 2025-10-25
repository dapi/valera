require 'rails_helper'
require 'telegram/bot/updates_controller/rspec_helpers'

RSpec.describe Telegram::WebhookController, type: :telegram_bot_controller do
  # for old RSpec:
  # include_context 'telegram/bot/updates_controller'

  let(:from_id) { 12345 }
  let(:chat_id) { 12345 }

  # Same helpers and matchers like dispatch_command, answer_callback_query are available here.

  describe '#start!' do
    subject { -> { dispatch_command(:start) } }

    it { should respond_with_message(/Здравствуйте/) }
  end

  it 'handles /start command and sends welcome message' do
    expect { dispatch_command(:start) }.
      to make_telegram_request(bot, :sendMessage).
      with(hash_including(text: /Здравствуйте/))
  end

  # TODO: Fix callback_query test - needs proper setup for answer_callback_query
  # describe '#callback_query', :callback_query do
  #   let(:data) { 'test_data' }

  #   it 'answers callback query with "Получено!"' do
  #     should answer_callback_query('Получено!')
  #   end
  # end

  describe '#message' do
    it 'processes regular text messages without immediate response' do
      # Messages are passed to LLM system through ruby_llm acts_as_chat
      expect { dispatch_message('Привет!') }.
        not_to make_telegram_request(bot, :sendMessage)
    end

    it 'processes messages without automatic reply' do
      # LLM handles responses, controller just creates Chat records
      expect { dispatch_message('Какая стоимость покраски?') }.
        not_to make_telegram_request(bot, :sendMessage)
    end
  end
end