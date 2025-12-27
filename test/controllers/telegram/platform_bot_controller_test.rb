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
      return_url = 'https://example.com/'
      token = 'test_token_123'

      url = @controller.send(:build_confirm_url, return_url, token)

      assert_equal 'https://example.com/auth/telegram/confirm?token=test_token_123', url
    end

    test 'build_confirm_url escapes token' do
      return_url = 'https://example.com/'
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

    # Тесты метода message

    test 'message in private chat responds with unknown command' do
      message = { 'chat' => { 'id' => 12345, 'type' => 'private' }, 'text' => 'привет' }

      @controller.expects(:respond_with).with(:message, has_entry(:text, includes('Неизвестная команда')))
      @controller.message(message)
    end

    test 'message in group without admin_chat_id responds with not configured' do
      message = { 'chat' => { 'id' => 99999, 'type' => 'group' }, 'text' => 'test' }

      ApplicationConfig.stubs(:platform_admin_chat_id).returns(nil)
      @controller.expects(:respond_with).with(:message, has_entry(:text, 'Бот не настроен: не указан канал администратора.'))
      @controller.message(message)
    end

    test 'message in admin group with reply to bot responds' do
      admin_chat_id = '12345'
      bot_id = ApplicationConfig.platform_bot_id
      message = {
        'chat' => { 'id' => admin_chat_id.to_i, 'type' => 'group' },
        'text' => 'как дела?',
        'reply_to_message' => { 'from' => { 'is_bot' => true, 'id' => bot_id } }
      }

      ApplicationConfig.stubs(:platform_admin_chat_id).returns(admin_chat_id)
      @controller.expects(:respond_with).with(:message, has_entry(:text, includes('не умею отвечать')))
      @controller.message(message)
    end

    test 'message in admin group with mention responds' do
      admin_chat_id = '12345'
      bot_username = 'test_bot'
      message = {
        'chat' => { 'id' => admin_chat_id.to_i, 'type' => 'group' },
        'text' => "@#{bot_username} что умеешь?"
      }

      ApplicationConfig.stubs(:platform_admin_chat_id).returns(admin_chat_id)
      ApplicationConfig.stubs(:platform_bot_username).returns(bot_username)
      @controller.expects(:respond_with).with(:message, has_entry(:text, includes('не умею отвечать')))
      @controller.message(message)
    end

    test 'message in admin group without reply or mention stays silent' do
      admin_chat_id = '12345'
      message = {
        'chat' => { 'id' => admin_chat_id.to_i, 'type' => 'group' },
        'text' => 'просто сообщение в группе'
      }

      ApplicationConfig.stubs(:platform_admin_chat_id).returns(admin_chat_id)
      ApplicationConfig.stubs(:platform_bot_username).returns('test_bot')
      @controller.expects(:respond_with).never
      @controller.message(message)
    end

    test 'message in non-admin group stays silent but logs warning' do
      admin_chat_id = '12345'
      non_admin_chat_id = 99999
      message = {
        'chat' => { 'id' => non_admin_chat_id, 'type' => 'group' },
        'text' => 'сообщение в другой группе'
      }

      ApplicationConfig.stubs(:platform_admin_chat_id).returns(admin_chat_id)
      @controller.expects(:respond_with).never
      @controller.message(message)
    end

    # Тесты вспомогательного метода message_addressed_to_bot?

    test 'message_addressed_to_bot? returns true for reply to bot' do
      bot_id = ApplicationConfig.platform_bot_id
      message = {
        'text' => 'ответ',
        'reply_to_message' => { 'from' => { 'is_bot' => true, 'id' => bot_id } }
      }

      result = @controller.send(:message_addressed_to_bot?, message)
      assert result
    end

    test 'message_addressed_to_bot? returns true for mention' do
      message = { 'text' => '@test_bot привет' }

      ApplicationConfig.stubs(:platform_bot_username).returns('test_bot')
      result = @controller.send(:message_addressed_to_bot?, message)
      assert result
    end

    test 'message_addressed_to_bot? returns false for regular message' do
      message = { 'text' => 'обычное сообщение' }

      ApplicationConfig.stubs(:platform_bot_username).returns('test_bot')
      result = @controller.send(:message_addressed_to_bot?, message)
      assert_not result
    end

    test 'message_addressed_to_bot? returns false for reply to non-bot' do
      message = {
        'text' => 'ответ',
        'reply_to_message' => { 'from' => { 'is_bot' => false, 'id' => 999 } }
      }

      result = @controller.send(:message_addressed_to_bot?, message)
      assert_not result
    end

    # Тесты для handle_member_invite - назначение владельца

    test 'handle_member_invite assigns user as owner when tenant has no owner' do
      tenant = tenants(:no_owner)
      invite = tenant_invites(:no_owner_invite)
      new_user = users(:viewer_user)
      telegram_user = telegram_users(:two)

      assert_nil tenant.owner_id, 'Tenant должен быть без владельца'

      # Мокаем методы контроллера
      @controller.stubs(:find_or_create_telegram_user).returns(telegram_user)
      @controller.stubs(:find_or_create_user_by_telegram).returns(new_user)
      @controller.expects(:respond_with).with(:message, has_entry(:text, includes('Поздравляем')))

      @controller.send(:handle_member_invite, invite.token)

      tenant.reload
      assert_equal new_user.id, tenant.owner_id, 'Пользователь должен стать владельцем'
    end

    test 'handle_member_invite does not change owner when tenant already has owner' do
      tenant = tenants(:one)
      invite = tenant_invites(:pending_invite)
      original_owner = tenant.owner
      new_user = users(:viewer_user)
      telegram_user = telegram_users(:two)

      assert_not_nil tenant.owner_id, 'Tenant должен иметь владельца'

      @controller.stubs(:find_or_create_telegram_user).returns(telegram_user)
      @controller.stubs(:find_or_create_user_by_telegram).returns(new_user)
      @controller.expects(:respond_with).with(:message, has_entry(:text, includes('добавлены в команду')))

      @controller.send(:handle_member_invite, invite.token)

      tenant.reload
      assert_equal original_owner.id, tenant.owner_id, 'Владелец не должен измениться'
    end

    test 'handle_member_invite creates membership for new owner' do
      tenant = tenants(:no_owner)
      invite = tenant_invites(:no_owner_invite)
      new_user = users(:viewer_user)
      telegram_user = telegram_users(:two)

      @controller.stubs(:find_or_create_telegram_user).returns(telegram_user)
      @controller.stubs(:find_or_create_user_by_telegram).returns(new_user)
      @controller.stubs(:respond_with)

      assert_difference 'TenantMembership.count', 1 do
        @controller.send(:handle_member_invite, invite.token)
      end

      membership = TenantMembership.find_by(tenant: tenant, user: new_user)
      assert_not_nil membership
      assert_equal invite.role, membership.role
    end
  end
end
