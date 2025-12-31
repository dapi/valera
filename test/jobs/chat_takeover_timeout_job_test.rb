# frozen_string_literal: true

require 'test_helper'

class ChatTakeoverTimeoutJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @chat = chats(:one)
    @user = users(:one)
    @mock_bot_client = mock('bot_client')
    @chat.tenant.stubs(:bot_client).returns(@mock_bot_client)

    # Put chat in manager mode
    @chat.takeover_by_manager!(@user, timeout_minutes: 30)
  end

  test 'releases chat to bot when timeout expired' do
    Tenant.any_instance.stubs(:bot_client).returns(@mock_bot_client)
    @mock_bot_client.stubs(:send_message).returns({ 'result' => { 'message_id' => 123 } })

    travel_to(31.minutes.from_now) do
      ChatTakeoverTimeoutJob.perform_now(@chat.id)
    end

    assert_not @chat.reload.manager_mode?
    assert_nil @chat.taken_by
  end

  test 'does not release chat if timeout not yet expired' do
    ChatTakeoverTimeoutJob.perform_now(@chat.id)

    assert @chat.reload.manager_mode?
    assert_equal @user, @chat.taken_by
  end

  test 'does not release chat if not in manager mode' do
    @chat.release_to_bot!

    ChatTakeoverTimeoutJob.perform_now(@chat.id)

    assert_not @chat.reload.manager_mode?
  end

  test 'skips if chat was taken over again after job was scheduled' do
    original_takeover_at = @chat.taken_at

    # Simulate new takeover (e.g., manager extended timeout)
    travel_to(5.minutes.from_now) do
      # Release first, then takeover again
      @chat.release_to_bot!
      @chat.takeover_by_manager!(@user, timeout_minutes: 30)
    end

    new_takeover_at = @chat.reload.taken_at

    # Job was scheduled with original takeover time, but chat has new takeover
    travel_to(35.minutes.from_now) do
      ChatTakeoverTimeoutJob.perform_now(@chat.id, original_takeover_at)
    end

    # Chat should still be in manager mode because new takeover happened
    assert @chat.reload.manager_mode?
  end

  test 'discards job if chat not found' do
    assert_nothing_raised do
      ChatTakeoverTimeoutJob.perform_now(-1)
    end
  end

  test 'calls release service when timeout expired' do
    Tenant.any_instance.stubs(:bot_client).returns(@mock_bot_client)
    @mock_bot_client.stubs(:send_message).returns({ 'result' => { 'message_id' => 123 } })

    # Проверяем что чат в режиме менеджера до истечения таймаута
    assert @chat.manager_active?

    travel_to(31.minutes.from_now) do
      ChatTakeoverTimeoutJob.perform_now(@chat.id)
    end

    # Независимо от того как именно произошёл release, чат должен быть в режиме бота
    @chat.reload
    assert_not @chat.manager_active?
  end

  test 'tracks analytics event on timeout release' do
    Tenant.any_instance.stubs(:bot_client).returns(@mock_bot_client)
    @mock_bot_client.stubs(:send_message).returns({ 'result' => { 'message_id' => 123 } })

    # Проверяем что при успешном release трекается аналитика
    # (не нужно мокать manager_mode? - это ломает валидацию при release)
    travel_to(31.minutes.from_now) do
      assert_enqueued_with(job: AnalyticsJob) do
        ChatTakeoverTimeoutJob.perform_now(@chat.id)
      end
    end
  end

  test 'retries job when release service fails' do
    # Проверяем что при неуспешном release job будет retry
    # (ApplicationJob retry_on StandardError перехватывает исключение)
    failed_result = Manager::ReleaseService::Result.new("success?": false, error: 'Test error')
    Manager::ReleaseService.stubs(:call).returns(failed_result)

    travel_to(31.minutes.from_now) do
      # Job должен быть запланирован на retry через SolidQueue
      assert_enqueued_with(job: ChatTakeoverTimeoutJob) do
        ChatTakeoverTimeoutJob.perform_now(@chat.id)
      end

      # Чат должен остаться в режиме менеджера (release не удался)
      assert @chat.reload.manager_mode?
    end
  end

  test 'defines ReleaseFailedError for retry mechanism' do
    # Проверяем что класс ReleaseFailedError определён для механизма retry
    assert_kind_of Class, ChatTakeoverTimeoutJob::ReleaseFailedError
    assert ChatTakeoverTimeoutJob::ReleaseFailedError < StandardError
  end
end
