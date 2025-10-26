# frozen_string_literal: true

# Represents a single message within a chat conversation
class Message < ApplicationRecord
  acts_as_message
  has_many_attached :attachments
end
