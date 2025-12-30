# frozen_string_literal: true

require 'test_helper'

class ManagerMessageServiceTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @tenant = tenants(:one)
    @chat = chats(:one)
    @user = users(:one)
    @service = ManagerMessageService.new(@chat)

    # Put chat in manager mode
    @chat.update!(mode: :manager_mode, taken_by: @user, taken_at: Time.current)

    # Mock bot_client for Telegram API calls
    @mock_bot_client = mock('bot_client')
    @mock_bot_client.stubs(:send_message).returns(true)
    @tenant.stubs(:bot_client).returns(@mock_bot_client)
    @chat.stubs(:tenant).returns(@tenant)
  end

  # === Send Tests ===

  test 'send creates message in chat' do
    assert_difference -> { @chat.messages.count }, 1 do
      @service.send!(@user, 'Hello client!')
    end
  end

  test 'send creates message with correct attributes' do
    message = @service.send!(@user, 'Hello client!')

    assert_equal 'assistant', message.role
    assert_equal 'Hello client!', message.content
    assert_equal 'manager', message.sender_type
    assert_equal @user, message.sender
  end

  test 'send sends message to Telegram' do
    telegram_user = @chat.telegram_user

    @mock_bot_client.expects(:send_message).with(
      chat_id: telegram_user.telegram_id,
      text: 'Hello client!'
    ).returns(true)

    @service.send!(@user, 'Hello client!')
  end

  test 'send extends takeover timeout' do
    original_taken_at = @chat.taken_at

    travel 5.minutes do
      @service.send!(@user, 'Hello client!')
      @chat.reload
      assert @chat.taken_at > original_taken_at
    end
  end

  # === Validation Tests ===

  test 'send raises NotInManagerModeError if chat not in manager mode' do
    @chat.update!(mode: :ai_mode, taken_by: nil, taken_at: nil)

    assert_raises(ManagerMessageService::NotInManagerModeError) do
      @service.send!(@user, 'Hello!')
    end
  end

  test 'send raises NotTakenByUserError if chat taken by different user' do
    other_user = users(:two)

    assert_raises(ManagerMessageService::NotTakenByUserError) do
      @service.send!(other_user, 'Hello!')
    end
  end

  test 'send raises RateLimitExceededError when limit exceeded' do
    # Create 60 messages in last hour (all within the hour window)
    60.times do |i|
      @chat.messages.create!(
        role: :assistant,
        content: "Message #{i}",
        sender_type: :manager,
        sender: @user,
        created_at: (59 - i).minutes.ago # 0-59 minutes ago, all within hour
      )
    end

    assert_raises(ManagerMessageService::RateLimitExceededError) do
      @service.send!(@user, 'One more!')
    end
  end

  test 'send allows messages if old messages are outside hour window' do
    # Create 60 messages 2 hours ago (outside window)
    60.times do |i|
      @chat.messages.create!(
        role: :assistant,
        content: "Old message #{i}",
        sender_type: :manager,
        sender: @user,
        created_at: 2.hours.ago
      )
    end

    # Should not raise - old messages don't count
    assert_nothing_raised do
      @service.send!(@user, 'New message!')
    end
  end

  # === MAX_MESSAGES_PER_HOUR constant ===

  test 'MAX_MESSAGES_PER_HOUR is 60' do
    assert_equal 60, ManagerMessageService::MAX_MESSAGES_PER_HOUR
  end

  # === Edge Cases ===

  test 'send handles Telegram API errors by re-raising' do
    @mock_bot_client.stubs(:send_message).raises(StandardError.new('Network error'))

    assert_raises(StandardError) do
      @service.send!(@user, 'Hello!')
    end
  end

  test 'message not saved if Telegram send fails' do
    @mock_bot_client.stubs(:send_message).raises(StandardError.new('Network error'))

    assert_no_difference -> { @chat.messages.count } do
      assert_raises(StandardError) do
        @service.send!(@user, 'Hello!')
      end
    end
  end
end
