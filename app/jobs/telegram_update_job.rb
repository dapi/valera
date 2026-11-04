# frozen_string_literal: true

class TelegramUpdateJob < ApplicationJob
  include ErrorLogger

  class EarlierUpdatePending < StandardError; end

  queue_as :default
  self.enqueue_after_transaction_commit = false

  retry_on StandardError,
           wait: ->(attempt) { attempt**2 + ApplicationConfig.telegram_update_retry_seconds },
           attempts: ApplicationConfig.telegram_update_attempts do |job, error|
    TelegramUpdate.find(job.arguments.first).update!(failed_at: Time.current)
    job.log_error(error, job: job.class.name, telegram_update_id: job.arguments.first)
    raise error
  end

  # More specific handler must follow retry_on StandardError.
  rescue_from EarlierUpdatePending do
    retry_job wait: ApplicationConfig.telegram_update_retry_seconds.seconds
  end

  def perform(update_id)
    update = TelegramUpdate.find(update_id)
    TelegramUpdate.transaction do
      lock_key = ActiveRecord::Relation::QueryAttribute.new(
        'conversation_lock', update.conversation_lock_key, ActiveRecord::Type::Integer.new(limit: 8)
      )
      TelegramUpdate.connection.exec_query('SELECT pg_advisory_xact_lock($1::bigint)::text', 'Telegram conversation lock', [ lock_key ])
      update.lock!
      return if update.processed_at? || update.failed_at?
      raise EarlierUpdatePending if update.earlier_pending?

      Current.set(tenant: update.tenant, telegram_update: update) do
        Telegram::WebhookController.dispatch(update.tenant.bot_client, update.payload)
        update.update!(processed_at: Time.current)
      end
    end
  ensure
    RequestStore.clear!
  end
end
