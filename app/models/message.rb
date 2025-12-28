# frozen_string_literal: true

# Represents a single message within a chat conversation
class Message < ApplicationRecord
  acts_as_message touch_chat: :last_message_at
  has_many_attached :attachments
end
