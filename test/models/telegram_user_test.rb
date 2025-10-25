require "test_helper"

class TelegramUserTest < ActiveSupport::TestCase
  test "fixture is valid and persisted" do
    telegram_user = telegram_users(:one)
    assert telegram_user.valid?
    assert telegram_user.persisted?
  end
end