# frozen_string_literal: true

# Durable inbox. Keep identifiers after payload retention for replay protection.
class TelegramUpdate < ApplicationRecord
  belongs_to :tenant

  def self.accept!(tenant:, payload:)
    id = payload['update_id']
    raise ArgumentError, 'Missing Telegram update_id' unless id.is_a?(Integer)

    transaction do
      record = create_or_find_by!(tenant: tenant, update_id: id) do |update|
        update.payload = payload
        update.conversation_key = (payload.dig('message', 'chat', 'id') ||
          payload.dig('callback_query', 'message', 'chat', 'id') ||
          payload.dig('callback_query', 'from', 'id') || "update:#{id}").to_s
      end
      if record.previously_new_record?
        job = TelegramUpdateJob.perform_later(record.id)
        raise ActiveJob::EnqueueError, 'Telegram processing was not enqueued' unless job
        tenant.touch(:last_message_at) if payload.dig('message', 'text').present?
      end
      record
    end
  end

  def earlier_pending?
    self.class.where(tenant_id: tenant_id, conversation_key: conversation_key, processed_at: nil, failed_at: nil)
        .where('id < ?', id).exists?
  end

  def conversation_lock_key
    Digest::SHA256.hexdigest("telegram:#{tenant_id}:#{conversation_key}").first(15).to_i(16)
  end
end
