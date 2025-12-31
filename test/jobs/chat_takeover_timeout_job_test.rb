# frozen_string_literal: true

require 'test_helper'

class ChatTakeoverTimeoutJobTest < ActiveSupport::TestCase
  setup do
    @tenant = tenants(:one)
    @chat = chats(:one)
    @user = users(:one)

    # Mock bot_client for Telegram API calls
    @mock_bot_client = mock('bot_client')
    @mock_bot_client.stubs(:send_message).returns(true)
    Tenant.any_instance.stubs(:bot_client).returns(@mock_bot_client)
  end

  test 'uses default queue' do
    assert_equal 'default', ChatTakeoverTimeoutJob.queue_name
  end

  test 'releases chat when timestamps match' do
    taken_at = Time.current
    @chat.update!(mode: :manager_mode, taken_by: @user, taken_at: taken_at)

    ChatTakeoverTimeoutJob.perform_now(@chat.id, taken_at.to_i)

    @chat.reload
    assert @chat.ai_mode?
  end

  test 'does nothing when chat not found' do
    assert_nothing_raised do
      ChatTakeoverTimeoutJob.perform_now(999999, Time.current.to_i)
    end
  end

  test 'does nothing when chat not in manager mode' do
    @chat.update!(mode: :ai_mode)
    taken_at = Time.current

    ChatTakeoverTimeoutJob.perform_now(@chat.id, taken_at.to_i)

    @chat.reload
    assert @chat.ai_mode?
  end

  test 'does nothing when timestamps do not match' do
    old_taken_at = 1.hour.ago
    new_taken_at = Time.current
    @chat.update!(mode: :manager_mode, taken_by: @user, taken_at: new_taken_at)

    # Job was scheduled with old timestamp, but chat has new timestamp (takeover was extended)
    ChatTakeoverTimeoutJob.perform_now(@chat.id, old_taken_at.to_i)

    @chat.reload
    # Should still be in manager mode because timestamps don't match
    assert @chat.manager_mode?
  end

  test 'sends timeout notification when releasing' do
    taken_at = Time.current
    @chat.update!(mode: :manager_mode, taken_by: @user, taken_at: taken_at)
    telegram_user = @chat.telegram_user

    @mock_bot_client.expects(:send_message).with(
      chat_id: telegram_user.telegram_id,
      text: ChatTakeoverService::NOTIFICATION_MESSAGES[:timeout]
    ).returns(true)

    ChatTakeoverTimeoutJob.perform_now(@chat.id, taken_at.to_i)
  end

  test 'defines ReleaseFailedError for retry mechanism' do
    # Проверяем что класс ReleaseFailedError определён для механизма retry
    assert_kind_of Class, ChatTakeoverTimeoutJob::ReleaseFailedError
    assert ChatTakeoverTimeoutJob::ReleaseFailedError < StandardError
  end
end
