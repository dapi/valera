# frozen_string_literal: true

# Copyright © 2023 Danil Pismenny <danil@brandymint.ru>

module TelegramSupport
  extend ActiveSupport::Concern

  included do # rubocop:disable Metrics/BlockLength
    setup do
      @described_class = Telegram::WebhookController
      @test_tenant = tenants(:one)
      # Стабим bot_client на всех тенантах, чтобы использовать тестовый бот
      Tenant.any_instance.stubs(:bot_client).returns(Telegram.bot)
    end

    private

    def post_message(text)
      host! "#{@test_tenant.key}.#{ApplicationConfig.host}"
      post '/telegram/webhook',
           params: message(text).to_json,
           headers: {
             'X-Telegram-Bot-Api-Secret-Token' => @test_tenant.webhook_secret,
             'Content-Type' => 'application/json'
           }
    end

    def latest_reply_text
      Telegram.bot.requests.fetch(:sendMessage).last.fetch(:text)
    end

    # Matcher to check response. Make sure to define `let(:chat_id)`.
    def respond_with_message(expected = Regexp.new(''))
      raise 'Define chat_id to use respond_with_message' unless defined?(chat_id)

      send_telegram_message(bot, expected, chat_id:)
    end

    def dispatch(update)
      @response = @described_class.dispatch Telegram.bot, ActiveSupport::HashWithIndifferentAccess.new(update)
    end

    def dispatch_message(text, options = {})
      default_message_options = {
        from: { id: @from_id || 123 },
        chat: { id: @chat_id || 456 }
      }
      dispatch message: default_message_options.merge(options).merge(text:)
    end

    # Dispatch command message.
    def dispatch_command(cmd, *args)
      options = args.last.is_a?(Hash) ? args.pop : {}
      args.unshift("/#{cmd}")
      dispatch_message(args.join(' '), options)
    end
  end
end
