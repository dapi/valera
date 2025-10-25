class TelegramUser < ApplicationRecord
  has_one :chat
end
