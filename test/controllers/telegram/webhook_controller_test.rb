# frozen_string_literal: true

require "test_helper"

class Telegram::WebhookControllerTest < ActionDispatch::IntegrationTest
  def setup
    # Создаем тестовые данные пользователя Telegram
    @telegram_user_data = {
      'id' => 12345,
      'first_name' => 'Иван',
      'last_name' => 'Петров',
      'username' => 'ivan_petrov'
    }

    # Создаем TelegramUser запись
    @telegram_user = TelegramUser.create!(@telegram_user_data)
  end

  test "TelegramUser model creates users correctly" do
    # Проверяем, что существующий пользователь найден
    found_user = TelegramUser.find(@telegram_user.id)
    assert_equal @telegram_user.id, found_user.id
    assert_equal @telegram_user.first_name, found_user.first_name
    assert_equal @telegram_user.username, found_user.username
  end

  test "TelegramUser can create new users" do
    new_user_data = {
      id: 67890,
      first_name: 'Анна',
      username: 'anna_user'
    }

    new_user = TelegramUser.create!(new_user_data)

    assert_equal 67890, new_user.id
    assert_equal 'Анна', new_user.first_name
    assert_equal 'anna_user', new_user.username
  end

  test "Chat model can be created for telegram user" do
    # Используем fixture модели deepseek
    chat = Chat.create!(telegram_user: @telegram_user)

    assert_not_nil chat
    assert_equal @telegram_user.id, chat.telegram_user_id
  end

  test "WelcomeService can be instantiated" do
    service = WelcomeService.new
    assert_not_nil service
    assert_instance_of WelcomeService, service
  end

  test "message method exists" do
    controller = Telegram::WebhookController.new
    assert_respond_to controller, :message
  end

  test "start! method exists" do
    controller = Telegram::WebhookController.new
    assert_respond_to controller, :start!
  end
end