# frozen_string_literal: true

require 'administrate/field/base'

# Custom field for displaying Telegram invite links
# Shows shortened URL in index, full URL in show
class TelegramLinkField < Administrate::Field::Base
  def truncated_url
    return nil if data.blank?

    # Extract token from URL (e.g., MBR_xxx from https://t.me/bot?start=MBR_xxx)
    if data =~ /start=(\w+)/
      "t.me/...#{::Regexp.last_match(1)[-6..]}"
    else
      data.truncate(25)
    end
  end

  def full_url
    data
  end
end
