# frozen_string_literal: true

require 'test_helper'

class TelegramTransactionalEnqueueTest < ActiveSupport::TestCase
  test 'GoodJob and inbox roll back together on primary database' do
    original = TelegramUpdateJob.queue_adapter
    TelegramUpdateJob.queue_adapter = GoodJob::Adapter.new(execution_mode: :external)
    before = GoodJob::Job.count
    assert_no_difference 'TelegramUpdate.count' do
      TelegramUpdate.transaction do
        TelegramUpdate.accept!(tenant: tenants(:one), payload: { 'update_id' => 20261104 })
        assert_equal before + 1, GoodJob::Job.count
        raise ActiveRecord::Rollback
      end
    end
    assert_equal before, GoodJob::Job.count
  ensure
    TelegramUpdateJob.queue_adapter = original
  end

  test 'GoodJob notification rolls back with failed booking transaction' do
    original = BookingNotificationJob.queue_adapter
    BookingNotificationJob.queue_adapter = GoodJob::Adapter.new(execution_mode: :external)
    TopicClassifierConfig.stubs(:enabled).returns(false)
    AnalyticsService.stubs(:track_conversion).raises(ActiveJob::EnqueueError, 'Synthetic analytics failure')
    before = GoodJob::Job.count
    assert_no_difference 'Booking.count' do
      assert_raises(ActiveJob::EnqueueError) do
        BookingTool.new(chat: chats(:one)).execute(details: 'Synthetic', dialog_context: {})
      end
    end
    assert_equal before, GoodJob::Job.count
  ensure
    BookingNotificationJob.queue_adapter = original
  end
end
