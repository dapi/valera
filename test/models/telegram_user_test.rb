require "test_helper"

class TelegramUserTest < ActiveSupport::TestCase
  test "fixture is valid and persisted" do
    telegram_user = telegram_users(:one)
    assert telegram_user.valid?
    assert telegram_user.persisted?
  end

  test "name returns first_name and last_name when both present" do
    user = TelegramUser.new(
      first_name: "Иван",
      last_name: "Петров",
      username: "ivan_user"
    )

    assert_equal "Иван Петров", user.name
  end

  test "name returns first_name when last_name is nil" do
    user = TelegramUser.new(
      first_name: "Иван",
      last_name: nil,
      username: "ivan_user"
    )

    assert_equal "Иван", user.name
  end

  test "name returns username when first_name and last_name are nil" do
    user = TelegramUser.new(
      first_name: nil,
      last_name: nil,
      username: "ivan_user"
    )

    assert_equal "@ivan_user", user.name
  end

  test "name returns empty string when all name fields are nil" do
    user = TelegramUser.new(
      first_name: nil,
      last_name: nil,
      username: nil
    )

    assert_equal "", user.name
  end

  test "name handles blank last_name correctly" do
    user = TelegramUser.new(
      first_name: "Иван",
      last_name: "",
      username: "ivan_user"
    )

    assert_equal "Иван", user.name
  end
end
