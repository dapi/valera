# frozen_string_literal: true

require "test_helper"

class WelcomeServiceTest < ActiveSupport::TestCase
  def setup
    @telegram_user = TelegramUser.new(
      id: 12345,
      first_name: "Иван",
      last_name: "Петров",
      username: "ivan_petrov"
    )

    @service = WelcomeService.new
  end

  test "interpolates name correctly in template" do
    template_content = "Здравствуйте, \#{name}! Я Валера - AI-ассистент."
    expected_message = "Здравствуйте, Иван Петров! Я Валера - AI-ассистент."

    # Проверяем приватный метод interpolate_template
    result = @service.send(:interpolate_template, template_content, @telegram_user)

    assert_equal expected_message, result
  end

  test "uses username when name is not available" do
    telegram_user = TelegramUser.new(
      id: 12345,
      first_name: nil,
      last_name: nil,
      username: "test_user"
    )

    template_content = "Здравствуйте, \#{name}! Я Валера."
    expected_message = "Здравствуйте, @test_user! Я Валера."

    result = @service.send(:interpolate_template, template_content, telegram_user)

    assert_equal expected_message, result
  end

  test "handles first_name only" do
    telegram_user = TelegramUser.new(
      id: 12345,
      first_name: "Анна",
      last_name: nil,
      username: "anna_user"
    )

    template_content = "Привет, \#{name}!"
    expected_message = "Привет, Анна!"

    result = @service.send(:interpolate_template, template_content, telegram_user)

    assert_equal expected_message, result
  end

  test "handles empty template gracefully" do
    empty_template = ""

    result = @service.send(:interpolate_template, empty_template, @telegram_user)

    assert_equal "", result
  end

  test "service can be instantiated" do
    assert_not_nil @service
    assert_instance_of WelcomeService, @service
  end
end