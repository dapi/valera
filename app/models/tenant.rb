# frozen_string_literal: true

class Tenant < ApplicationRecord
  KEY_LENGTH = 8
  WEBHOOK_SECRET_LENGTH = 32

  belongs_to :owner, class_name: 'User', optional: true

  has_many :clients, dependent: :destroy
  has_many :chats, dependent: :destroy
  has_many :bookings, dependent: :destroy
  has_many :analytics_events, dependent: :destroy

  validates :name, presence: true
  validates :bot_token, presence: true, uniqueness: true
  validates :bot_username, presence: true
  validates :key, presence: true, uniqueness: true, length: { is: KEY_LENGTH }
  validates :webhook_secret, presence: true

  before_validation :generate_key, on: :create, if: -> { key.blank? }
  before_validation :generate_webhook_secret, on: :create, if: -> { webhook_secret.blank? }

  private

  def generate_key
    self.key = Nanoid.generate(size: KEY_LENGTH)
  end

  def generate_webhook_secret
    self.webhook_secret = SecureRandom.hex(WEBHOOK_SECRET_LENGTH)
  end
end
