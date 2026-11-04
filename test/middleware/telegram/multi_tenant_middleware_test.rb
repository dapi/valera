# frozen_string_literal: true

require 'test_helper'

module Telegram
  class MultiTenantMiddlewareTest < ActionDispatch::IntegrationTest
    include ActiveJob::TestHelper

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
      host! "nonexistent.#{ApplicationConfig.host}"
      post '/telegram/webhook',
           params: @telegram_update.to_json,
           headers: @valid_headers

      assert_response :not_found
    end

    test 'returns 401 for invalid secret token' do
      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      invalid_headers = @valid_headers.merge('X-Telegram-Bot-Api-Secret-Token' => 'wrong_secret')

      post '/telegram/webhook',
           params: @telegram_update.to_json,
           headers: invalid_headers

      assert_response :unauthorized
      assert_equal 'Unauthorized', response.body
    end

    test 'returns 401 for missing secret token' do
      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      headers_without_secret = { 'Content-Type' => 'application/json' }

      post '/telegram/webhook',
           params: @telegram_update.to_json,
           headers: headers_without_secret

      assert_response :unauthorized
      assert_equal 'Unauthorized', response.body
    end

    test 'persists and enqueues update without dispatching in request' do
      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      WebhookController.expects(:dispatch).never
      assert_difference 'TelegramUpdate.count', 1 do
        assert_enqueued_jobs 1, only: TelegramUpdateJob do
          post '/telegram/webhook', params: @telegram_update.to_json, headers: @valid_headers
        end
      end
      assert_response :ok
      assert_equal @tenant, TelegramUpdate.last.tenant
      assert_equal 'Hello', TelegramUpdate.last.payload.dig('message', 'text')
    end

    test 'replayed webhook is acknowledged without enqueueing another job' do
      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      post '/telegram/webhook', params: @telegram_update.to_json, headers: @valid_headers
      assert_no_difference 'TelegramUpdate.count' do
        assert_no_enqueued_jobs only: TelegramUpdateJob do
          post '/telegram/webhook', params: @telegram_update.to_json, headers: @valid_headers
        end
      end
      assert_response :ok
    end

    test 'same update id is independent across tenants' do
      [ @tenant, tenants(:two) ].each do |tenant|
        host! "#{tenant.key}.#{ApplicationConfig.host}"
        post '/telegram/webhook', params: @telegram_update.to_json,
             headers: @valid_headers.merge('X-Telegram-Bot-Api-Secret-Token' => tenant.webhook_secret)
        assert_response :ok
      end
      assert_equal 2, TelegramUpdate.where(update_id: @telegram_update[:update_id]).count
    end

    test 'protects against timing attacks with secure_compare' do
      host! "#{@tenant.key}.#{ApplicationConfig.host}"
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
