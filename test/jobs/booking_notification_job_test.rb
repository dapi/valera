# frozen_string_literal: true

require 'test_helper'

class BookingNotificationJobTest < ActiveJob::TestCase
  setup do
    @booking = bookings(:one)
    @bot = mock('bot')
    Tenant.any_instance.stubs(:bot_client).returns(@bot)
  end

  def api_error(status, retry_after: nil)
    response = Struct.new(:status, :body, :reason).new(status,
      { 'description' => 'Synthetic error', 'parameters' => { 'retry_after' => retry_after } }.to_json, 'Error')
    Telegram::Bot::Client.error_for_response(response)
  end

  test 'temporary Telegram failure retries and subsequently delivers once' do
    @bot.expects(:send_message).twice.raises(api_error(502)).then.returns({})
    assert_enqueued_with(job: BookingNotificationJob) { BookingNotificationJob.perform_now(@booking) }
    assert_nil @booking.reload.notification_failed_at
    2.times { BookingNotificationJob.perform_now(@booking) }
    assert @booking.reload.notified_at?
  end

  test '429 honors server retry_after' do
    @bot.expects(:send_message).raises(api_error(429, retry_after: 90))
    freeze_time do
      assert_enqueued_with(job: BookingNotificationJob, at: 90.seconds.from_now) do
        BookingNotificationJob.perform_now(@booking)
      end
    end
  end

  test 'permanent error marks delivery failed without retry' do
    @bot.expects(:send_message).raises(api_error(403))
    assert_no_enqueued_jobs { BookingNotificationJob.perform_now(@booking) }
    assert @booking.reload.notification_failed_at?
    assert_nil @booking.notified_at
  end

  test 'exhausted transient failure remains visible' do
    ApplicationConfig.stubs(:telegram_delivery_attempts).returns(1)
    @bot.expects(:send_message).raises(api_error(503))
    assert_raises(Telegram::TransientApiError) { BookingNotificationJob.perform_now(@booking) }
    assert @booking.reload.notification_failed_at?
  end
end
