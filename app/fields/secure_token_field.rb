# frozen_string_literal: true

require 'administrate/field/base'

# Custom Administrate field for secure token display and editing
# Shows masked token (e.g., "123456789:ab...xy") and allows setting new value
class SecureTokenField < Administrate::Field::Base
  def to_s
    masked_value
  end

  # Returns masked version of the token for display
  # Format: "123456789:ab...xy" (bot_id:first2...last2)
  def masked_value
    return nil if data.blank?

    parts = data.split(':')
    return data if parts.length < 2 || parts[1].length < 4

    bot_id = parts[0]
    secret = parts[1]
    "#{bot_id}:#{secret[0..1]}...#{secret[-2..]}"
  end

  # Field name for new token input
  def new_token_attribute
    :"new_#{attribute}"
  end

  # Check if token is already set
  def token_set?
    data.present?
  end
end
