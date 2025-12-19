# frozen_string_literal: true

require 'test_helper'

module Telegram
  class MultiTenantWebhookControllerTest < ActionDispatch::IntegrationTest
    setup do
      @tenant = tenants(:one)
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
    end

    test 'returns 404 for non-existent tenant' do
      post tenant_telegram_webhook_path(tenant_key: 'nonexistent'),
           params: @telegram_update.to_json,
           headers: @valid_headers

      assert_response :not_found
    end

    test 'returns 401 for invalid secret token' do
      invalid_headers = @valid_headers.merge('X-Telegram-Bot-Api-Secret-Token' => 'wrong_secret')

      post tenant_telegram_webhook_path(tenant_key: @tenant.key),
           params: @telegram_update.to_json,
           headers: invalid_headers

      assert_response :unauthorized
    end

    test 'returns 401 for missing secret token' do
      headers_without_secret = { 'Content-Type' => 'application/json' }

      post tenant_telegram_webhook_path(tenant_key: @tenant.key),
           params: @telegram_update.to_json,
           headers: headers_without_secret

      assert_response :unauthorized
    end

    test 'sets Current.tenant for valid request' do
      WebhookController.expects(:dispatch).once.with do |bot, update, _request|
        Current.tenant == @tenant &&
          bot.is_a?(::Telegram::Bot::Client) &&
          update['message']['text'] == 'Hello'
      end

      post tenant_telegram_webhook_path(tenant_key: @tenant.key),
           params: @telegram_update.to_json,
           headers: @valid_headers

      assert_response :ok
    end

    test 'creates bot client with tenant token' do
      WebhookController.expects(:dispatch).once.with do |bot, _update, _request|
        bot.is_a?(::Telegram::Bot::Client) &&
          bot.token == @tenant.bot_token
      end

      post tenant_telegram_webhook_path(tenant_key: @tenant.key),
           params: @telegram_update.to_json,
           headers: @valid_headers

      assert_response :ok
    end

    test 'works with different tenants' do
      tenant_two = tenants(:two)
      headers_for_two = {
        'Content-Type' => 'application/json',
        'X-Telegram-Bot-Api-Secret-Token' => tenant_two.webhook_secret
      }

      WebhookController.expects(:dispatch).once.with do |bot, _update, _request|
        Current.tenant == tenant_two &&
          bot.token == tenant_two.bot_token
      end

      post tenant_telegram_webhook_path(tenant_key: tenant_two.key),
           params: @telegram_update.to_json,
           headers: headers_for_two

      assert_response :ok
    end

    test 'protects against timing attacks with secure_compare' do
      # Ensure we use secure_compare for secret verification
      # This test verifies the implementation doesn't use simple == comparison
      ActiveSupport::SecurityUtils.expects(:secure_compare).at_least_once.returns(true)

      WebhookController.stubs(:dispatch)

      post tenant_telegram_webhook_path(tenant_key: @tenant.key),
           params: @telegram_update.to_json,
           headers: @valid_headers

      assert_response :ok
    end
  end
end
