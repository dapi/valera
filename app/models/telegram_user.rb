class TelegramUser < ApplicationRecord
  has_one :chat

  # Returns user's name for welcome message interpolation
  def name
    full_name = [first_name, last_name].compact.join(' ').strip
    full_name.presence || ("@#{username}" if username).to_s
  end
end
