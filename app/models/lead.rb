# frozen_string_literal: true

class Lead < ApplicationRecord
  belongs_to :manager, class_name: 'AdminUser', optional: true

  scope :without_manager, -> { where(manager_id: nil) }

  validates :name, presence: true
  validates :phone, presence: true

  after_commit :notify_platform_bot, on: :create

  private

  def notify_platform_bot
    if ApplicationConfig.platform_admin_chat_id.present?
      LeadNotificationJob.perform_later(id)
    else
      Rails.logger.warn("[Lead##{id}] PLATFORM_ADMIN_CHAT_ID not configured, skipping notification")
    end
  end
end
