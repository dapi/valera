# frozen_string_literal: true

require 'test_helper'

class ChatTakeoverServiceTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @tenant = tenants(:one)
    @chat = chats(:one)
    @user = users(:one)
    @service = ChatTakeoverService.new(@chat)

    # Mock bot_client for Telegram API calls
    @mock_bot_client = mock('bot_client')
    @mock_bot_client.stubs(:send_message).returns(true)
    @tenant.stubs(:bot_client).returns(@mock_bot_client)
    @chat.stubs(:tenant).returns(@tenant)
  end

  # === Takeover Tests ===

  test 'takeover changes chat mode to manager_mode' do
    @service.takeover!(@user)

    @chat.reload
    assert @chat.manager_mode?
    assert_equal @user.id, @chat.taken_by_id
    assert_not_nil @chat.taken_at
  end

  test 'takeover sends notification to client via Telegram' do
    telegram_user = @chat.telegram_user
    expected_text = format(ChatTakeoverService::NOTIFICATION_MESSAGES[:takeover], name: @user.display_name)

    @mock_bot_client.expects(:send_message).with(
      chat_id: telegram_user.telegram_id,
      text: expected_text
    ).returns(true)

    @service.takeover!(@user)
  end

  test 'takeover creates system message in chat' do
    assert_difference -> { @chat.messages.where(sender_type: :system).count }, 1 do
      @service.takeover!(@user)
    end
  end

  test 'takeover schedules timeout job' do
    assert_enqueued_with(job: ChatTakeoverTimeoutJob) do
      @service.takeover!(@user)
    end
  end

  test 'takeover raises AlreadyTakenError if chat already in manager mode' do
    @chat.update!(mode: :manager_mode, taken_by: @user, taken_at: Time.current)

    assert_raises(ChatTakeoverService::AlreadyTakenError) do
      @service.takeover!(@user)
    end
  end

  test 'takeover raises UnauthorizedError if user has no access to tenant' do
    unauthorized_user = users(:two)
    unauthorized_user.stubs(:has_access_to?).returns(false)

    assert_raises(ChatTakeoverService::UnauthorizedError) do
      @service.takeover!(unauthorized_user)
    end
  end

  # === Release Tests ===

  test 'release changes chat mode back to ai_mode' do
    @chat.update!(mode: :manager_mode, taken_by: @user, taken_at: Time.current)

    @service.release!

    @chat.reload
    assert @chat.ai_mode?
    assert_nil @chat.taken_by_id
    assert_nil @chat.taken_at
  end

  test 'release sends notification to client via Telegram' do
    @chat.update!(mode: :manager_mode, taken_by: @user, taken_at: Time.current)
    telegram_user = @chat.telegram_user

    @mock_bot_client.expects(:send_message).with(
      chat_id: telegram_user.telegram_id,
      text: ChatTakeoverService::NOTIFICATION_MESSAGES[:release]
    ).returns(true)

    @service.release!
  end

  test 'release with timeout sends timeout notification' do
    @chat.update!(mode: :manager_mode, taken_by: @user, taken_at: Time.current)
    telegram_user = @chat.telegram_user

    @mock_bot_client.expects(:send_message).with(
      chat_id: telegram_user.telegram_id,
      text: ChatTakeoverService::NOTIFICATION_MESSAGES[:timeout]
    ).returns(true)

    @service.release!(timeout: true)
  end

  test 'release raises NotTakenError if chat not in manager mode' do
    assert_raises(ChatTakeoverService::NotTakenError) do
      @service.release!
    end
  end

  test 'release raises UnauthorizedError if wrong user tries to release' do
    @chat.update!(mode: :manager_mode, taken_by: @user, taken_at: Time.current)
    other_user = users(:two)
    # Ensure other_user has no admin access to the tenant
    TenantMembership.where(tenant: @tenant, user: other_user).destroy_all
    TenantMembership.create!(tenant: @tenant, user: other_user, role: :operator)

    assert_raises(ChatTakeoverService::UnauthorizedError) do
      @service.release!(user: other_user)
    end
  end

  test 'release allows same user who took over' do
    @chat.update!(mode: :manager_mode, taken_by: @user, taken_at: Time.current)

    @service.release!(user: @user)

    @chat.reload
    assert @chat.ai_mode?
  end

  test 'release allows admin to release any chat' do
    @chat.update!(mode: :manager_mode, taken_by: @user, taken_at: Time.current)
    admin_user = users(:two)
    # Give admin_user admin role in the tenant
    TenantMembership.where(tenant: @tenant, user: admin_user).destroy_all
    TenantMembership.create!(tenant: @tenant, user: admin_user, role: :admin)

    @service.release!(user: admin_user)

    @chat.reload
    assert @chat.ai_mode?
  end

  test 'release without user (timeout) bypasses authorization' do
    @chat.update!(mode: :manager_mode, taken_by: @user, taken_at: Time.current)

    # Should not raise even without user
    @service.release!(timeout: true)

    @chat.reload
    assert @chat.ai_mode?
  end

  # === Extend Timeout Tests ===

  test 'extend_timeout updates taken_at' do
    original_taken_at = 10.minutes.ago
    @chat.update!(mode: :manager_mode, taken_by: @user, taken_at: original_taken_at)

    @service.extend_timeout!

    @chat.reload
    assert @chat.taken_at > original_taken_at
  end

  test 'extend_timeout does nothing if not in manager mode' do
    @service.extend_timeout!

    @chat.reload
    assert @chat.ai_mode?
    assert_nil @chat.taken_at
  end

  # === Timeout Duration ===

  test 'TIMEOUT_DURATION is 30 minutes' do
    assert_equal 30.minutes, ChatTakeoverService::TIMEOUT_DURATION
  end

  # === Edge Cases ===

  test 'takeover handles Telegram API errors gracefully' do
    @mock_bot_client.stubs(:send_message).raises(Telegram::Bot::Error.new('Telegram API error'))

    # Should not raise - operation continues
    @service.takeover!(@user)

    @chat.reload
    assert @chat.manager_mode?
  end

  test 'takeover handles network errors gracefully' do
    @mock_bot_client.stubs(:send_message).raises(Faraday::ConnectionFailed.new('Network error'))

    # Should not raise - operation continues
    @service.takeover!(@user)

    @chat.reload
    assert @chat.manager_mode?
  end

  test 'release handles Telegram API errors gracefully' do
    @chat.update!(mode: :manager_mode, taken_by: @user, taken_at: Time.current)
    @mock_bot_client.stubs(:send_message).raises(Telegram::Bot::Error.new('Telegram API error'))

    # Should not raise - operation continues
    @service.release!

    @chat.reload
    assert @chat.ai_mode?
  end

  test 'release handles network errors gracefully' do
    @chat.update!(mode: :manager_mode, taken_by: @user, taken_at: Time.current)
    @mock_bot_client.stubs(:send_message).raises(Faraday::ConnectionFailed.new('Network error'))

    # Should not raise - operation continues
    @service.release!

    @chat.reload
    assert @chat.ai_mode?
  end
end
