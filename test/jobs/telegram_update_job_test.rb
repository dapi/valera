# frozen_string_literal: true

require 'test_helper'

class TelegramUpdateJobTest < ActiveJob::TestCase
  setup do
    @tenant = tenants(:one)
    Tenant.any_instance.stubs(:bot_client).returns(Telegram.bot)
    @update = TelegramUpdate.accept!(tenant: @tenant, payload: {
      'update_id' => 101, 'message' => { 'chat' => { 'id' => 123 }, 'text' => 'Synthetic' }
    })
  end

  test 'dispatches once with tenant context and skips completed replay' do
    Telegram::WebhookController.expects(:dispatch).once.with do |bot, payload|
      bot == Telegram.bot && payload == @update.payload && Current.tenant == @tenant && Current.telegram_update == @update
    end
    2.times { TelegramUpdateJob.perform_now(@update.id) }
    assert @update.reload.processed_at?
    assert_nil Current.telegram_update
  end

  test 'does not process later update until earlier update completed' do
    later = TelegramUpdate.accept!(tenant: @tenant, payload: @update.payload.merge('update_id' => 102))
    Telegram::WebhookController.expects(:dispatch).never
    assert_enqueued_with(job: TelegramUpdateJob, args: [ later.id ]) do
      TelegramUpdateJob.perform_now(later.id)
    end
    assert_nil later.reload.processed_at
    assert_nil later.failed_at
  end

  test 'failed dispatch rolls back business writes and schedules retry' do
    Telegram::WebhookController.stubs(:dispatch).raises(IOError, 'Synthetic network failure')
    assert_enqueued_with(job: TelegramUpdateJob, args: [ @update.id ]) do
      TelegramUpdateJob.perform_now(@update.id)
    end
    assert_nil @update.reload.processed_at
    assert_nil Current.telegram_update
  end

  test 'enqueue failure rolls back inbox acceptance' do
    TelegramUpdateJob.stubs(:perform_later).raises(ActiveJob::EnqueueError, 'Synthetic queue failure')
    assert_no_difference 'TelegramUpdate.count' do
      assert_raises(ActiveJob::EnqueueError) do
        TelegramUpdate.accept!(tenant: @tenant, payload: @update.payload.merge('update_id' => 103))
      end
    end
  end

  test 'payload cleanup preserves deduplication identifiers and pending payloads' do
    @update.update!(processed_at: 8.days.ago)
    pending = TelegramUpdate.accept!(tenant: @tenant, payload: @update.payload.merge('update_id' => 103))
    CleanupTelegramPayloadsJob.perform_now
    assert_equal({}, @update.reload.payload)
    assert pending.reload.payload.present?
    assert_no_difference 'TelegramUpdate.count' do
      TelegramUpdate.accept!(tenant: @tenant, payload: pending.payload.merge('update_id' => 101))
    end
  end
end
