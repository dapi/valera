# frozen_string_literal: true

require 'test_helper'

class Manager::TakeoverServiceTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @chat = chats(:one)
    @user = users(:one)
    @success_result = Manager::TelegramMessageSender::Result.new(success?: true, telegram_message_id: 123)
  end

  test 'takes over chat successfully with notification' do
    Manager::TelegramMessageSender.stubs(:call).returns(@success_result)

    result = Manager::TakeoverService.call(chat: @chat, user: @user)

    assert result.success?
    assert @chat.reload.manager_mode?
    assert_equal @user, @chat.taken_by
    assert_not_nil result.active_until
  end

  test 'takes over chat without notification' do
    Manager::TelegramMessageSender.expects(:call).never

    result = Manager::TakeoverService.call(chat: @chat, user: @user, notify_client: false)

    assert result.success?
    assert @chat.reload.manager_mode?
  end

  test 'uses custom timeout' do
    Manager::TelegramMessageSender.stubs(:call).returns(@success_result)
    custom_timeout = 60 # Отличается от дефолта (30 минут)

    freeze_time do
      result = Manager::TakeoverService.call(chat: @chat, user: @user, timeout_minutes: custom_timeout)

      assert result.success?
      assert_equal custom_timeout.minutes.from_now, @chat.reload.manager_active_until
    end
  end

  test 'uses default timeout from config' do
    Manager::TelegramMessageSender.stubs(:call).returns(@success_result)

    freeze_time do
      result = Manager::TakeoverService.call(chat: @chat, user: @user)

      expected_timeout = ApplicationConfig.manager_takeover_timeout_minutes.minutes.from_now
      assert result.success?
      assert_equal expected_timeout, @chat.reload.manager_active_until
    end
  end

  test 'raises error when chat is nil' do
    error = assert_raises(RuntimeError) do
      Manager::TakeoverService.call(chat: nil, user: @user)
    end
    assert_equal 'No chat', error.message
  end

  test 'raises error when user is nil' do
    error = assert_raises(RuntimeError) do
      Manager::TakeoverService.call(chat: @chat, user: nil)
    end
    assert_equal 'No user', error.message
  end

  test 'returns error when chat is already in manager mode' do
    @chat.takeover_by_manager!(@user)

    result = Manager::TakeoverService.call(chat: @chat, user: @user)

    assert_not result.success?
    assert_equal 'Chat is already in manager mode', result.error
  end

  test 'handles telegram send failure gracefully' do
    failure_result = Manager::TelegramMessageSender::Result.new(success?: false, error: 'Network error')
    Manager::TelegramMessageSender.stubs(:call).returns(failure_result)

    # Takeover should still succeed even if notification fails
    result = Manager::TakeoverService.call(chat: @chat, user: @user)

    assert result.success?
    assert @chat.reload.manager_mode?
    assert_equal false, result.notification_sent
  end

  test 'returns notification_sent true when notification succeeds' do
    Manager::TelegramMessageSender.stubs(:call).returns(@success_result)

    result = Manager::TakeoverService.call(chat: @chat, user: @user)

    assert result.success?
    assert_equal true, result.notification_sent
  end

  test 'returns notification_sent nil when notifications disabled' do
    Manager::TelegramMessageSender.expects(:call).never

    result = Manager::TakeoverService.call(chat: @chat, user: @user, notify_client: false)

    assert result.success?
    assert_nil result.notification_sent
  end

  test 'schedules timeout job on takeover' do
    Manager::TelegramMessageSender.stubs(:call).returns(@success_result)

    assert_enqueued_with(job: ChatTakeoverTimeoutJob) do
      Manager::TakeoverService.call(chat: @chat, user: @user)
    end
  end

  test 'tracks analytics event on takeover' do
    Manager::TelegramMessageSender.stubs(:call).returns(@success_result)

    assert_enqueued_with(job: AnalyticsJob) do
      Manager::TakeoverService.call(chat: @chat, user: @user)
    end
  end

  test 'prevents concurrent takeover by second manager' do
    Manager::TelegramMessageSender.stubs(:call).returns(@success_result)
    other_user = users(:two)

    # Первый менеджер успешно перехватывает чат
    first_result = Manager::TakeoverService.call(chat: @chat, user: @user)
    assert first_result.success?

    # Второй менеджер не может перехватить уже занятый чат
    second_result = Manager::TakeoverService.call(chat: @chat.reload, user: other_user)
    assert_not second_result.success?
    assert_equal 'Chat is already in manager mode', second_result.error

    # Чат остаётся за первым менеджером
    assert_equal @user, @chat.reload.taken_by
  end
end
