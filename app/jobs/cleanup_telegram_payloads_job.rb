# frozen_string_literal: true

class CleanupTelegramPayloadsJob < ApplicationJob
  def perform
    cutoff = ApplicationConfig.telegram_payload_retention_days.days.ago
    TelegramUpdate.where('processed_at < ? OR failed_at < ?', cutoff, cutoff).update_all(payload: {})
  end
end
