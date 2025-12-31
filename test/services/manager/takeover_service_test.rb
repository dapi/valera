# frozen_string_literal: true

require 'test_helper'

class Manager::TakeoverServiceTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @chat = chats(:one)
    @user = users(:one)
    @mock_bot_client = mock('bot_client')
    @chat.tenant.stubs(:bot_client).returns(@mock_bot_client)
  end

  test 'takes over chat successfully with notification' do
    @mock_bot_client.expects(:send_message).returns({ 'result' => { 'message_id' => 123 } })

    result = Manager::TakeoverService.call(chat: @chat, user: @user)

    assert result.success?
    assert @chat.reload.manager_mode?
    assert_equal @user, @chat.taken_by
    assert_not_nil result.active_until
  end

  test 'takes over chat without notification' do
    @mock_bot_client.expects(:send_message).never

    result = Manager::TakeoverService.call(chat: @chat, user: @user, notify_client: false)

    assert result.success?
    assert @chat.reload.manager_mode?
  end

  test 'uses custom timeout' do
    @mock_bot_client.stubs(:send_message).returns({ 'result' => { 'message_id' => 123 } })

    freeze_time do
      result = Manager::TakeoverService.call(chat: @chat, user: @user, timeout_minutes: 60)

      assert result.success?
      assert_equal 60.minutes.from_now, @chat.reload.manager_active_until
    end
  end

  test 'uses default timeout from config' do
    @mock_bot_client.stubs(:send_message).returns({ 'result' => { 'message_id' => 123 } })

    freeze_time do
      result = Manager::TakeoverService.call(chat: @chat, user: @user)

      expected_timeout = ApplicationConfig.manager_takeover_timeout_minutes.minutes.from_now
      assert result.success?
      assert_equal expected_timeout, @chat.reload.manager_active_until
    end
  end

  test 'returns error when chat is nil' do
    result = Manager::TakeoverService.call(chat: nil, user: @user)

    assert_not result.success?
    assert_equal 'Chat is required', result.error
  end

  test 'returns error when user is nil' do
    result = Manager::TakeoverService.call(chat: @chat, user: nil)

    assert_not result.success?
    assert_equal 'User is required', result.error
  end

  test 'returns error when chat is already in manager mode' do
    @chat.takeover_by_manager!(@user)

    result = Manager::TakeoverService.call(chat: @chat, user: @user)

    assert_not result.success?
    assert_equal 'Chat is already in manager mode', result.error
  end

  test 'handles telegram send failure gracefully' do
    @mock_bot_client.expects(:send_message).raises(Faraday::Error.new('Network error'))

    # Takeover should still succeed even if notification fails
    # because we catch telegram errors in TelegramMessageSender
    result = Manager::TakeoverService.call(chat: @chat, user: @user)

    assert result.success?
    assert @chat.reload.manager_mode?
    assert_equal false, result.notification_sent
  end

  test 'returns notification_sent true when notification succeeds' do
    @mock_bot_client.expects(:send_message).returns({ 'result' => { 'message_id' => 123 } })

    result = Manager::TakeoverService.call(chat: @chat, user: @user)

    assert result.success?
    assert_equal true, result.notification_sent
  end

  test 'returns notification_sent nil when notifications disabled' do
    @mock_bot_client.expects(:send_message).never

    result = Manager::TakeoverService.call(chat: @chat, user: @user, notify_client: false)

    assert result.success?
    assert_nil result.notification_sent
  end

  test 'schedules timeout job on takeover' do
    @mock_bot_client.stubs(:send_message).returns({ 'result' => { 'message_id' => 123 } })

    assert_enqueued_with(job: ChatTakeoverTimeoutJob) do
      Manager::TakeoverService.call(chat: @chat, user: @user)
    end
  end

  test 'tracks analytics event on takeover' do
    @mock_bot_client.stubs(:send_message).returns({ 'result' => { 'message_id' => 123 } })

    assert_enqueued_with(job: AnalyticsJob) do
      Manager::TakeoverService.call(chat: @chat, user: @user)
    end
  end

  test 'prevents concurrent takeover by second manager' do
    @mock_bot_client.stubs(:send_message).returns({ 'result' => { 'message_id' => 123 } })
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
