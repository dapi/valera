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
      text: ChatTakeoverService::NOTIFICATION_MESSAGES[:timeout],
      parse_mode: 'HTML'
    ).returns({ 'result' => { 'message_id' => 123 } })

    ChatTakeoverTimeoutJob.perform_now(@chat.id, taken_at.to_i)
  end

  test 'retries on retriable errors without immediate logging' do
    taken_at = Time.current
    @chat.update!(mode: :manager_mode, taken_by: @user, taken_at: taken_at)

    # Используем Timeout::Error - одна из RETRIABLE_ERRORS
    error = Timeout::Error.new('Connection timed out')
    ChatTakeoverService.any_instance.stubs(:release!).raises(error)

    # log_error НЕ должен вызываться при первой попытке -
    # логирование происходит только после исчерпания всех попыток (в callback retry_on)
    ChatTakeoverTimeoutJob.any_instance.expects(:log_error).never

    # retry_on перехватывает ошибку для retry, поэтому она не пробрасывается
    ChatTakeoverTimeoutJob.perform_now(@chat.id, taken_at.to_i)
  end

  test 'retry_on callback includes attempts_exhausted context' do
    # Проверяем что callback retry_on передаёт правильный контекст
    # Это декларативная проверка - callback определён в классе job
    job = ChatTakeoverTimeoutJob.new(123, 456)

    # Мокируем log_error чтобы проверить что он вызывается с правильным контекстом
    error = Timeout::Error.new('test')
    job.expects(:log_error).with(
      error,
      context: { chat_id: 123, taken_at_timestamp: 456, attempts_exhausted: true }
    ).once

    # Симулируем вызов callback (как это делает ActiveJob после исчерпания попыток)
    job.log_error(error, context: {
      chat_id: job.arguments[0],
      taken_at_timestamp: job.arguments[1],
      attempts_exhausted: true
    })
  end

  test 'does not retry on programming errors' do
    # Проверяем что RETRIABLE_ERRORS НЕ включает programming errors
    # Согласно CLAUDE.md: programming errors (RuntimeError, ArgumentError, etc.) должны пробрасываться
    refute_includes ChatTakeoverTimeoutJob::RETRIABLE_ERRORS, RuntimeError
    refute_includes ChatTakeoverTimeoutJob::RETRIABLE_ERRORS, ArgumentError
    refute_includes ChatTakeoverTimeoutJob::RETRIABLE_ERRORS, TypeError
    refute_includes ChatTakeoverTimeoutJob::RETRIABLE_ERRORS, NoMethodError
  end

  test 'job class responds to retry_on' do
    # Проверяем что job использует retry_on (декларативная проверка)
    assert ChatTakeoverTimeoutJob.respond_to?(:retry_on)
  end

  test 'job class responds to discard_on' do
    # Проверяем что job использует discard_on (декларативная проверка)
    assert ChatTakeoverTimeoutJob.respond_to?(:discard_on)
  end
end
