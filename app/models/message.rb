# frozen_string_literal: true

# Represents a single message within a chat conversation
class Message < ApplicationRecord
  # Valid roles for LLM messages.
  # Mirrors RubyLLM::Message::ROLES (symbols) as strings for DB validation.
  VALID_ROLES = %w[system user assistant tool].freeze

  acts_as_message touch_chat: :last_message_at
  has_many_attached :attachments

  validates :role, presence: true, inclusion: { in: VALID_ROLES }
end
