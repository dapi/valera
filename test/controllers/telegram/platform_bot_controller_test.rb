# frozen_string_literal: true

require 'test_helper'

module Telegram
  class PlatformBotControllerTest < ActiveSupport::TestCase
    setup do
      @controller = Telegram::PlatformBotController.new
      @tenant = tenants(:one)
      @telegram_user = telegram_users(:one)
      @user = @tenant.owner
      @auth_service = TelegramAuthService.new
    end

    test 'controller has start! method' do
      assert_respond_to @controller, :start!
    end

    test 'handle_empty_start is defined' do
      assert @controller.respond_to?(:handle_empty_start, true)
    end

    test 'handle_auth_request is defined' do
      assert @controller.respond_to?(:handle_auth_request, true)
    end

    test 'handle_invite is defined' do
      assert @controller.respond_to?(:handle_invite, true)
    end

    test 'find_or_create_telegram_user is defined' do
      assert @controller.respond_to?(:find_or_create_telegram_user, true)
    end

    test 'find_user_by_telegram is defined' do
      assert @controller.respond_to?(:find_user_by_telegram, true)
    end

    test 'build_confirm_url is defined' do
      assert @controller.respond_to?(:build_confirm_url, true)
    end

    test 'build_confirm_url builds correct URL' do
      return_url = 'https://example.lvh.me/'
      token = 'test_token_123'

      url = @controller.send(:build_confirm_url, return_url, token)

      assert_equal 'https://example.lvh.me/auth/telegram/confirm?token=test_token_123', url
    end

    test 'build_confirm_url escapes token' do
      return_url = 'https://example.lvh.me/'
      token = 'token+with/special=chars'

      url = @controller.send(:build_confirm_url, return_url, token)

      assert_includes url, CGI.escape(token)
    end

    # Тесты для обработки групп

    test 'new_chat_members is defined' do
      assert_respond_to @controller, :new_chat_members
    end

    test 'message is defined' do
      assert_respond_to @controller, :message
    end

    test 'ApplicationConfig.platform_bot_id extracts ID from token' do
      # Токен в тестах: '123:fake' (из config/initializers/telegram.rb)
      assert_equal 123, ApplicationConfig.platform_bot_id
    end
  end
end
