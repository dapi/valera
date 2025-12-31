# frozen_string_literal: true

# Represents a single message within a chat conversation
#
# Roles:
# - user: message from client (via Telegram)
# - assistant: message from AI bot
# - manager: message from human manager (via dashboard)
# - system: system instructions
# - tool: tool call result
class Message < ApplicationRecord
  ROLES = %w[user assistant manager system tool].freeze
  BROADCASTABLE_ROLES = %w[user assistant manager].freeze

  acts_as_message touch_chat: :last_message_at
  has_many_attached :attachments

  # Manager who sent the message (only for role: 'manager')
  belongs_to :sent_by_user, class_name: 'User', optional: true

  validates :role, inclusion: { in: ROLES }
  validates :sent_by_user, presence: true, if: -> { role == 'manager' }

  # Broadcast new messages to dashboard for real-time updates
  after_create_commit :broadcast_to_dashboard, if: :broadcastable?

  scope :from_manager, -> { where(role: 'manager') }
  scope :from_bot, -> { where(role: 'assistant') }
  scope :from_client, -> { where(role: 'user') }

  def from_manager?
    role == 'manager'
  end

  def from_bot?
    role == 'assistant'
  end

  def from_client?
    role == 'user'
  end

  private

  def broadcastable?
    BROADCASTABLE_ROLES.include?(role)
  end

  def broadcast_to_dashboard
    broadcast_append_to(
      chat,
      target: 'chat-messages',
      partial: 'tenants/chats/message',
      locals: { message: self }
    )
  end
end
