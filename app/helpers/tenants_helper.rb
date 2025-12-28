# frozen_string_literal: true

# Helper methods for tenant dashboard views
module TenantsHelper
  # Masks bot token for secure display
  # Shows bot_id and first/last 2 characters of secret
  #
  # @param token [String] Telegram bot token (e.g., "123456789:ABCdefGHI...")
  # @return [String, nil] Masked token (e.g., "123456789:AB...HI") or nil if blank
  #
  # @example
  #   masked_bot_token("123456789:ABCdefGHIjklMNO")
  #   # => "123456789:AB...NO"
  #
  def masked_bot_token(token)
    return nil if token.blank?

    parts = token.split(':')
    return token if parts.length < 2 || parts[1].length < 4

    bot_id = parts[0]
    secret = parts[1]
    "#{bot_id}:#{secret[0..1]}...#{secret[-2..]}"
  end
end
