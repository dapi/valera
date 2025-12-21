# frozen_string_literal: true

require 'test_helper'

module Telegram
  class MultiTenantMiddlewareTest < ActionDispatch::IntegrationTest
    setup do
      @tenant = tenants(:one)
      @bot_stub = Telegram.bot
      @valid_headers = {
        'Content-Type' => 'application/json',
        'X-Telegram-Bot-Api-Secret-Token' => @tenant.webhook_secret
      }
      @telegram_update = {
        update_id: 123_456_789,
        message: {
          message_id: 1,
          date: Time.current.to_i,
          chat: { id: 12_345, type: 'private' },
          from: { id: 67_890, is_bot: false, first_name: 'Test', username: 'testuser' },
          text: 'Hello'
        }
      }
      # Стабим bot_client на всех тенантах, чтобы использовать тестовый бот
      Tenant.any_instance.stubs(:bot_client).returns(@bot_stub)
    end

    test 'returns 404 for non-existent tenant' do
      host! 'nonexistent.lvh.me'
      post '/telegram/webhook',
           params: @telegram_update.to_json,
           headers: @valid_headers

      assert_response :not_found
    end

    test 'returns 401 for invalid secret token' do
      host! "#{@tenant.key}.lvh.me"
      invalid_headers = @valid_headers.merge('X-Telegram-Bot-Api-Secret-Token' => 'wrong_secret')

      post '/telegram/webhook',
           params: @telegram_update.to_json,
           headers: invalid_headers

      assert_response :unauthorized
      assert_equal 'Unauthorized', response.body
    end

    test 'returns 401 for missing secret token' do
      host! "#{@tenant.key}.lvh.me"
      headers_without_secret = { 'Content-Type' => 'application/json' }

      post '/telegram/webhook',
           params: @telegram_update.to_json,
           headers: headers_without_secret

      assert_response :unauthorized
      assert_equal 'Unauthorized', response.body
    end

    test 'sets Current.tenant for valid request' do
      host! "#{@tenant.key}.lvh.me"
      WebhookController.expects(:dispatch).once.with do |bot, update, _request|
        Current.tenant == @tenant &&
          bot.is_a?(::Telegram::Bot::Client) &&
          update['message']['text'] == 'Hello'
      end

      post '/telegram/webhook',
           params: @telegram_update.to_json,
           headers: @valid_headers

      assert_response :ok
    end

    test 'passes bot client to dispatch' do
      host! "#{@tenant.key}.lvh.me"
      WebhookController.expects(:dispatch).once.with do |bot, _update, _request|
        # Проверяем что передается tenant.bot_client (застабленный в setup)
        bot == @bot_stub
      end

      post '/telegram/webhook',
           params: @telegram_update.to_json,
           headers: @valid_headers

      assert_response :ok
    end

    test 'works with different tenants and sets correct Current.tenant' do
      tenant_two = tenants(:two)
      host! "#{tenant_two.key}.lvh.me"
      headers_for_two = {
        'Content-Type' => 'application/json',
        'X-Telegram-Bot-Api-Secret-Token' => tenant_two.webhook_secret
      }

      WebhookController.expects(:dispatch).once.with do |_bot, _update, _request|
        Current.tenant == tenant_two
      end

      post '/telegram/webhook',
           params: @telegram_update.to_json,
           headers: headers_for_two

      assert_response :ok
    end

    test 'protects against timing attacks with secure_compare' do
      host! "#{@tenant.key}.lvh.me"
      # Ensure we use secure_compare for secret verification
      # This test verifies the implementation doesn't use simple == comparison
      ActiveSupport::SecurityUtils.expects(:secure_compare).at_least_once.returns(true)

      WebhookController.stubs(:dispatch)

      post '/telegram/webhook',
           params: @telegram_update.to_json,
           headers: @valid_headers

      assert_response :ok
    end

    test 'middleware has correct inspect representation' do
      middleware = Telegram::MultiTenantMiddleware.new(Telegram::WebhookController)
      assert_equal '#<Telegram::MultiTenantMiddleware(Telegram::WebhookController)>', middleware.inspect
    end

    test 'middleware handles nil controller gracefully in inspect' do
      middleware = Telegram::MultiTenantMiddleware.new(nil)
      assert_equal '#<Telegram::MultiTenantMiddleware()>', middleware.inspect
    end
  end
end
