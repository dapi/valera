class Booking < ApplicationRecord
  belongs_to :telegram_user
  belongs_to :chat

  scope :recent, -> { order(created_at: :desc) }

  after_commit on: :create do
    BookingNotificationJob.perform_later(self)
  end
end
