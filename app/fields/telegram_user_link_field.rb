# frozen_string_literal: true

require 'administrate/field/base'

# Custom Administrate field for displaying Telegram username as link
class TelegramUserLinkField < Administrate::Field::Base
  def to_s
    data
  end

  def telegram_url
    "https://t.me/#{data}" if data.present?
  end

  def display_text
    "@#{data} ↗" if data.present?
  end
end
