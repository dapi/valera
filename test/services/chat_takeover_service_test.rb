# frozen_string_literal: true

require 'test_helper'

class ChatTakeoverServiceTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @chat = chats(:one)
    @user = users(:one)
    @tenant = tenants(:one)

    # Ensure chat starts in AI mode
    @chat.update!(mode: :ai_mode, taken_by: nil, taken_at: nil, manager_active_until: nil)

    # Mock Telegram API calls
    @success_result = Manager::TelegramMessageSender::Result.new(success?: true, telegram_message_id: 123)
    Manager::TelegramMessageSender.stubs(:call).returns(@success_result)
  end

  # ============================================
  # takeover! tests
  # ============================================

  test 'takeover! switches chat to manager mode' do
    service = ChatTakeoverService.new(@chat)

    result = service.takeover!(@user)

    assert @chat.reload.manager_mode?
    assert_equal @user, @chat.taken_by
    assert_not_nil @chat.taken_at
    assert_not_nil @chat.manager_active_until
    assert_instance_of ChatTakeoverService::TakeoverResult, result
  end

  test 'takeover! sets manager_active_until using default timeout' do
    service = ChatTakeoverService.new(@chat)
    expected_timeout = ApplicationConfig.manager_takeover_timeout_minutes.minutes

    freeze_time do
      service.takeover!(@user)

      assert_equal Time.current + expected_timeout, @chat.reload.manager_active_until
    end
  end

  test 'takeover! uses custom timeout_minutes when provided' do
    service = ChatTakeoverService.new(@chat)
    custom_timeout = 60

    freeze_time do
      service.takeover!(@user, timeout_minutes: custom_timeout)

      assert_equal Time.current + custom_timeout.minutes, @chat.reload.manager_active_until
    end
  end

  test 'takeover! raises AlreadyTakenError when chat already in manager mode' do
    @chat.update!(mode: :manager_mode, taken_by: @user, taken_at: Time.current, manager_active_until: 30.minutes.from_now)
    service = ChatTakeoverService.new(@chat)

    error = assert_raises(ChatTakeoverService::AlreadyTakenError) do
      service.takeover!(@user)
    end

    assert_equal 'Chat is already in manager mode', error.message
  end

  test 'takeover! sends notification to client by default' do
    Manager::TelegramMessageSender.expects(:call).with(
      chat: @chat,
      text: ChatTakeoverService::NOTIFICATION_MESSAGES[:takeover]
    ).returns(@success_result)

    service = ChatTakeoverService.new(@chat)
    result = service.takeover!(@user)

    assert_equal true, result.notification_sent
  end

  test 'takeover! skips notification when notify_client is false' do
    Manager::TelegramMessageSender.expects(:call).never

    service = ChatTakeoverService.new(@chat)
    result = service.takeover!(@user, notify_client: false)

    assert_nil result.notification_sent
  end

  test 'takeover! returns notification_sent false when notification fails' do
    failure_result = Manager::TelegramMessageSender::Result.new(success?: false, error: 'Network error')
    Manager::TelegramMessageSender.stubs(:call).returns(failure_result)

    service = ChatTakeoverService.new(@chat)
    result = service.takeover!(@user)

    assert_equal false, result.notification_sent
    # Takeover should still succeed even if notification fails
    assert @chat.reload.manager_mode?
  end

  test 'takeover! schedules ChatTakeoverTimeoutJob' do
    service = ChatTakeoverService.new(@chat)

    assert_enqueued_with(job: ChatTakeoverTimeoutJob) do
      service.takeover!(@user)
    end
  end

  test 'takeover! schedules timeout job with correct timestamp' do
    service = ChatTakeoverService.new(@chat)

    freeze_time do
      service.takeover!(@user)
      @chat.reload

      # Verify the job was enqueued with the correct arguments
      assert_enqueued_jobs 1, only: ChatTakeoverTimeoutJob
      enqueued_job = enqueued_jobs.find { |j| j['job_class'] == 'ChatTakeoverTimeoutJob' }
      assert_equal @chat.id, enqueued_job['arguments'][0]
      assert_equal @chat.taken_at.to_i, enqueued_job['arguments'][1]
    end
  end

  test 'takeover! tracks analytics event' do
    service = ChatTakeoverService.new(@chat)

    assert_enqueued_with(job: AnalyticsJob) do
      service.takeover!(@user)
    end
  end

  test 'takeover! uses database lock for atomicity' do
    service = ChatTakeoverService.new(@chat)

    # Verify with_lock is called on chat
    @chat.expects(:with_lock).yields
    service.takeover!(@user)
  end

  test 'takeover! raises error when chat is nil' do
    error = assert_raises(RuntimeError) do
      ChatTakeoverService.new(nil)
    end

    assert_equal 'No chat', error.message
  end

  # ============================================
  # release! tests
  # ============================================

  test 'release! switches chat back to ai mode' do
    @chat.update!(mode: :manager_mode, taken_by: @user, taken_at: Time.current, manager_active_until: 30.minutes.from_now)
    service = ChatTakeoverService.new(@chat)

    result = service.release!

    assert @chat.reload.ai_mode?
    assert_nil @chat.taken_by
    assert_nil @chat.taken_at
    assert_nil @chat.manager_active_until
  end

  test 'release! raises NotTakenError when chat not in manager mode' do
    service = ChatTakeoverService.new(@chat)

    error = assert_raises(ChatTakeoverService::NotTakenError) do
      service.release!
    end

    assert_equal 'Chat is not in manager mode', error.message
  end

  test 'release! sends release notification by default' do
    @chat.update!(mode: :manager_mode, taken_by: @user, taken_at: Time.current, manager_active_until: 30.minutes.from_now)

    Manager::TelegramMessageSender.expects(:call).with(
      chat: @chat,
      text: ChatTakeoverService::NOTIFICATION_MESSAGES[:release]
    ).returns(@success_result)

    service = ChatTakeoverService.new(@chat)
    service.release!
  end

  test 'release! sends timeout notification when timeout is true' do
    @chat.update!(mode: :manager_mode, taken_by: @user, taken_at: Time.current, manager_active_until: 30.minutes.from_now)

    Manager::TelegramMessageSender.expects(:call).with(
      chat: @chat,
      text: ChatTakeoverService::NOTIFICATION_MESSAGES[:timeout]
    ).returns(@success_result)

    service = ChatTakeoverService.new(@chat)
    service.release!(timeout: true)
  end

  test 'release! tracks analytics event' do
    @chat.update!(mode: :manager_mode, taken_by: @user, taken_at: Time.current, manager_active_until: 30.minutes.from_now)
    service = ChatTakeoverService.new(@chat)

    assert_enqueued_with(job: AnalyticsJob) do
      service.release!
    end
  end

  test 'release! tracks analytics with timeout reason' do
    @chat.update!(mode: :manager_mode, taken_by: @user, taken_at: 10.minutes.ago, manager_active_until: 30.minutes.from_now)
    service = ChatTakeoverService.new(@chat)

    AnalyticsService.expects(:track).with(
      AnalyticsService::Events::CHAT_TAKEOVER_ENDED,
      tenant: @chat.tenant,
      chat_id: @chat.id,
      properties: has_entries(reason: 'timeout', released_by_id: nil)
    )

    service.release!(timeout: true)
  end

  test 'release! tracks analytics with manual reason' do
    @chat.update!(mode: :manager_mode, taken_by: @user, taken_at: 10.minutes.ago, manager_active_until: 30.minutes.from_now)
    service = ChatTakeoverService.new(@chat)

    AnalyticsService.expects(:track).with(
      AnalyticsService::Events::CHAT_TAKEOVER_ENDED,
      tenant: @chat.tenant,
      chat_id: @chat.id,
      properties: has_entries(reason: 'manual', released_by_id: @user.id)
    )

    service.release!
  end

  test 'release! calculates duration in minutes' do
    taken_at = 15.minutes.ago
    @chat.update!(mode: :manager_mode, taken_by: @user, taken_at: taken_at, manager_active_until: 30.minutes.from_now)
    service = ChatTakeoverService.new(@chat)

    expected_duration_minutes = ((Time.current - taken_at) / 60.0).round(1)

    AnalyticsService.expects(:track).with(
      AnalyticsService::Events::CHAT_TAKEOVER_ENDED,
      tenant: @chat.tenant,
      chat_id: @chat.id,
      properties: has_entries(duration_minutes: expected_duration_minutes)
    )

    service.release!
  end

  test 'release! uses database lock for atomicity' do
    @chat.update!(mode: :manager_mode, taken_by: @user, taken_at: Time.current, manager_active_until: 30.minutes.from_now)
    service = ChatTakeoverService.new(@chat)

    @chat.expects(:with_lock).yields
    service.release!
  end

  test 'release! continues even when notification fails' do
    @chat.update!(mode: :manager_mode, taken_by: @user, taken_at: Time.current, manager_active_until: 30.minutes.from_now)
    failure_result = Manager::TelegramMessageSender::Result.new(success?: false, error: 'Network error')
    Manager::TelegramMessageSender.stubs(:call).returns(failure_result)

    service = ChatTakeoverService.new(@chat)
    result = service.release!

    # Release should still succeed even if notification fails
    assert @chat.reload.ai_mode?
    assert_equal @chat, result
  end

  # ============================================
  # Error classes tests
  # ============================================

  test 'AlreadyTakenError is defined with default message' do
    error = ChatTakeoverService::AlreadyTakenError.new
    assert_equal 'Chat is already in manager mode', error.message
  end

  test 'NotTakenError is defined with default message' do
    error = ChatTakeoverService::NotTakenError.new
    assert_equal 'Chat is not in manager mode', error.message
  end

  test 'ValidationError is defined' do
    assert_kind_of Class, ChatTakeoverService::ValidationError
    assert ChatTakeoverService::ValidationError < StandardError
  end

  # ============================================
  # TakeoverResult struct tests
  # ============================================

  test 'TakeoverResult contains chat and notification_sent' do
    service = ChatTakeoverService.new(@chat)
    result = service.takeover!(@user)

    assert_respond_to result, :chat
    assert_respond_to result, :notification_sent
    assert_equal @chat, result.chat
  end

  # ============================================
  # Concurrency tests
  # ============================================

  test 'prevents double takeover due to race condition' do
    # Simulate two concurrent takeover attempts
    # First takeover should succeed, second should fail
    service1 = ChatTakeoverService.new(@chat)
    service2 = ChatTakeoverService.new(@chat.reload)

    result1 = service1.takeover!(@user)
    assert @chat.reload.manager_mode?

    # Second attempt should fail because chat is already taken
    error = assert_raises(ChatTakeoverService::AlreadyTakenError) do
      service2.takeover!(users(:two))
    end

    assert_equal 'Chat is already in manager mode', error.message
    # Chat should still belong to first user
    assert_equal @user, @chat.reload.taken_by
  end
end
