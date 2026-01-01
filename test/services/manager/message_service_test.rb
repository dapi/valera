# frozen_string_literal: true

require 'test_helper'

class Manager::MessageServiceTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @chat = chats(:one)
    @user = users(:one)
    @mock_bot_client = mock('bot_client')
    @chat.tenant.stubs(:bot_client).returns(@mock_bot_client)

    # Put chat in manager mode
    @chat.takeover_by_manager!(@user)
  end

  test 'sends message successfully' do
    @mock_bot_client.expects(:send_message).returns({ 'result' => { 'message_id' => 123 } })

    result = Manager::MessageService.call(
      chat: @chat,
      user: @user,
      content: 'Hello from manager!'
    )

    assert result.success?
    assert result.message.persisted?
    assert_equal 'manager', result.message.role
    assert_equal 'Hello from manager!', result.message.content
    assert_equal @user, result.message.sent_by_user
    assert result.telegram_sent
  end

  test 'extends timeout after sending message' do
    @mock_bot_client.stubs(:send_message).returns({ 'result' => { 'message_id' => 123 } })
    original_until = @chat.manager_active_until

    travel 5.minutes

    Manager::MessageService.call(
      chat: @chat,
      user: @user,
      content: 'Hello!'
    )

    assert @chat.reload.manager_active_until > original_until

    travel_back
  end

  test 'does not extend timeout when extend_timeout is false' do
    @mock_bot_client.stubs(:send_message).returns({ 'result' => { 'message_id' => 123 } })
    original_until = @chat.manager_active_until

    travel 5.minutes

    Manager::MessageService.call(
      chat: @chat,
      user: @user,
      content: 'Hello!',
      extend_timeout: false
    )

    assert_equal original_until, @chat.reload.manager_active_until

    travel_back
  end

  test 'raises error when chat is nil' do
    error = assert_raises(RuntimeError) do
      Manager::MessageService.call(chat: nil, user: @user, content: 'Hello!')
    end
    assert_equal 'No chat', error.message
  end

  test 'raises error when user is nil' do
    error = assert_raises(RuntimeError) do
      Manager::MessageService.call(chat: @chat, user: nil, content: 'Hello!')
    end
    assert_equal 'No user', error.message
  end

  test 'raises error when content is blank' do
    error = assert_raises(RuntimeError) do
      Manager::MessageService.call(chat: @chat, user: @user, content: '')
    end
    assert_equal 'No content', error.message
  end

  test 'returns error when content is too long' do
    long_content = 'a' * 4097

    result = Manager::MessageService.call(chat: @chat, user: @user, content: long_content)

    assert_not result.success?
    assert_equal 'Content is too long', result.error
  end

  test 'accepts content at max length' do
    @mock_bot_client.stubs(:send_message).returns({ 'result' => { 'message_id' => 123 } })
    max_content = 'a' * 4096

    result = Manager::MessageService.call(chat: @chat, user: @user, content: max_content)

    assert result.success?
  end

  test 'returns error when chat is not in manager mode' do
    @chat.release_to_bot!

    result = Manager::MessageService.call(chat: @chat, user: @user, content: 'Hello!')

    assert_not result.success?
    assert_equal 'Chat is not in manager mode', result.error
  end

  test 'returns error when manager session has expired' do
    # Set manager_active_until to past time
    @chat.update!(manager_active_until: 1.minute.ago)

    result = Manager::MessageService.call(chat: @chat, user: @user, content: 'Hello!')

    assert_not result.success?
    assert_equal 'Manager session has expired', result.error
  end

  test 'returns error when user is not the active manager' do
    other_user = users(:two)

    result = Manager::MessageService.call(chat: @chat, user: other_user, content: 'Hello!')

    assert_not result.success?
    assert_equal 'User is not the active manager', result.error
  end

  test 'message is NOT saved if telegram fails' do
    @mock_bot_client.expects(:send_message).raises(Faraday::Error.new('Network error'))

    initial_message_count = @chat.messages.count

    result = Manager::MessageService.call(
      chat: @chat,
      user: @user,
      content: 'Hello!'
    )

    # Message should NOT be saved if Telegram delivery fails
    # This ensures the manager sees only messages that were actually delivered
    assert_not result.success?
    assert_includes result.error, I18n.t('manager.message.telegram_delivery_failed')
    assert_equal initial_message_count, @chat.messages.reload.count
  end

  test 'tracks analytics event on message sent' do
    @mock_bot_client.stubs(:send_message).returns({ 'result' => { 'message_id' => 123 } })

    assert_enqueued_with(job: AnalyticsJob) do
      Manager::MessageService.call(
        chat: @chat,
        user: @user,
        content: 'Hello from manager!'
      )
    end
  end
end
