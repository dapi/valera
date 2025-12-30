# frozen_string_literal: true

require 'test_helper'

class Manager::ReleaseServiceTest < ActiveSupport::TestCase
  setup do
    @chat = chats(:one)
    @user = users(:one)
    @mock_bot_client = mock('bot_client')
    @chat.tenant.stubs(:bot_client).returns(@mock_bot_client)

    # Put chat in manager mode
    @chat.takeover_by_manager!(@user)
  end

  test 'releases chat to bot successfully with notification' do
    @mock_bot_client.expects(:send_message).returns({ 'result' => { 'message_id' => 123 } })

    result = Manager::ReleaseService.call(chat: @chat, user: @user)

    assert result.success?
    assert @chat.reload.bot_mode?
    assert_nil @chat.manager_user
    assert_nil @chat.manager_active_at
    assert_nil @chat.manager_active_until
  end

  test 'releases chat without notification' do
    @mock_bot_client.expects(:send_message).never

    result = Manager::ReleaseService.call(chat: @chat, user: @user, notify_client: false)

    assert result.success?
    assert @chat.reload.bot_mode?
  end

  test 'releases chat without user (system release)' do
    @mock_bot_client.stubs(:send_message).returns({ 'result' => { 'message_id' => 123 } })

    result = Manager::ReleaseService.call(chat: @chat)

    assert result.success?
    assert @chat.reload.bot_mode?
  end

  test 'returns error when chat is nil' do
    result = Manager::ReleaseService.call(chat: nil)

    assert_not result.success?
    assert_equal 'Chat is required', result.error
  end

  test 'returns error when user is not the active manager' do
    other_user = users(:two)

    result = Manager::ReleaseService.call(chat: @chat, user: other_user)

    assert_not result.success?
    assert_equal 'User is not authorized to release this chat', result.error
  end

  test 'fails when chat is already in bot mode' do
    @chat.release_to_bot!
    @mock_bot_client.expects(:send_message).never

    result = Manager::ReleaseService.call(chat: @chat)

    assert_not result.success?
    assert_equal 'Chat is not in manager mode', result.error
  end

  test 'does not notify when chat is already in bot mode' do
    @chat.release_to_bot!
    @mock_bot_client.expects(:send_message).never

    result = Manager::ReleaseService.call(chat: @chat, notify_client: true)

    assert_not result.success?
    assert_equal 'Chat is not in manager mode', result.error
  end

  test 'handles telegram send failure gracefully' do
    @mock_bot_client.expects(:send_message).raises(Faraday::Error.new('Network error'))

    # Release should still succeed even if notification fails
    result = Manager::ReleaseService.call(chat: @chat, user: @user)

    assert result.success?
    assert @chat.reload.bot_mode?
    assert_equal false, result.notification_sent
  end

  test 'returns notification_sent true when notification succeeds' do
    @mock_bot_client.expects(:send_message).returns({ 'result' => { 'message_id' => 123 } })

    result = Manager::ReleaseService.call(chat: @chat, user: @user)

    assert result.success?
    assert_equal true, result.notification_sent
  end

  test 'returns notification_sent nil when notifications disabled' do
    @mock_bot_client.expects(:send_message).never

    result = Manager::ReleaseService.call(chat: @chat, user: @user, notify_client: false)

    assert result.success?
    assert_nil result.notification_sent
  end

  test 'returns error when chat already in bot mode' do
    @chat.release_to_bot!
    @mock_bot_client.expects(:send_message).never

    result = Manager::ReleaseService.call(chat: @chat, notify_client: true)

    assert_not result.success?
    assert_equal 'Chat is not in manager mode', result.error
  end
end
