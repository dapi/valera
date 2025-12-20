# frozen_string_literal: true

# Client represents a TelegramUser in the context of a specific Tenant (auto service).
# One TelegramUser can be a client of multiple auto services.
class Client < ApplicationRecord
  belongs_to :tenant
  belongs_to :telegram_user

  has_many :vehicles, dependent: :destroy
  has_many :chats, dependent: :destroy
  has_many :bookings, dependent: :destroy

  validates :telegram_user_id, uniqueness: { scope: :tenant_id }

  delegate :telegram_id, :username, :first_name, :last_name, to: :telegram_user, prefix: true, allow_nil: true

  # Returns display name: client's name or telegram user's name
  def display_name
    name.presence || telegram_user&.first_name || "Client ##{id}"
  end
end
