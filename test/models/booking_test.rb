# frozen_string_literal: true

require "test_helper"

class BookingTest < ActiveSupport::TestCase
  def setup
    @telegram_user = TelegramUser.create!(
      id: 12_345,
      first_name: "Иван",
      last_name: "Петров"
    )

    @chat = Chat.create!(
      telegram_user: @telegram_user
    )
  end

  def teardown
    Booking.delete_all
    ToolCall.delete_all
    Message.delete_all
    Chat.delete_all
    TelegramUser.delete_all
  end

  # Test basic booking creation
  test "should create valid booking with required meta data" do
    booking_data = {
      customer_name: "Иван Петров",
      customer_phone: "+7(916)123-45-67",
      car_info: {
        "brand" => "Toyota",
        "model" => "Camry",
        "year" => 2018
      },
      preferred_date: "2025-10-26",
      preferred_time: "10:00"
    }

    booking = Booking.new(
      meta: booking_data,
      telegram_user: @telegram_user,
      chat: @chat
    )

    assert booking.valid?
    assert booking.save
    assert_equal booking_data[:customer_name], booking.customer_name
    assert_equal booking_data[:customer_phone], booking.customer_phone
    assert_equal booking_data[:car_info], booking.car_info
    assert_equal booking_data[:preferred_date], booking.preferred_date
    assert_equal booking_data[:preferred_time], booking.preferred_time
  end

  # Test validations
  test "should require telegram_user" do
    booking = Booking.new(
      meta: { customer_name: "Test", customer_phone: "+7(916)123-45-67", car_info: {} }
    )

    assert_not booking.valid?
    # Проверяем что есть ошибка валидации для telegram_user
    assert booking.errors[:telegram_user].any?
  end

  test "should validate presence of customer_name in meta" do
    booking = Booking.new(
      meta: { customer_phone: "+7(916)123-45-67", car_info: {} },
      telegram_user: @telegram_user
    )

    assert_not booking.valid?
    assert_includes booking.errors[:meta], "должно содержать имя клиента"
  end

  test "should validate presence of customer_phone in meta" do
    booking = Booking.new(
      meta: { customer_name: "Иван", car_info: {} },
      telegram_user: @telegram_user
    )

    assert_not booking.valid?
    assert_includes booking.errors[:meta], "должно содержать телефон клиента"
  end

  test "should validate presence of car_info in meta" do
    booking = Booking.new(
      meta: { customer_name: "Иван", customer_phone: "+7(916)123-45-67" },
      telegram_user: @telegram_user
    )

    assert_not booking.valid?
    assert_includes booking.errors[:meta], "должно содержать информацию об автомобиле"
  end

  test "should validate phone format" do
    # Valid phone numbers
    valid_phones = [
      "+7(916)123-45-67",
      "+79161234567",
      "89161234567",
      "+7 916 123 45 67"
    ]

    valid_phones.each do |phone|
      booking = Booking.new(
        meta: {
          customer_name: "Иван",
          customer_phone: phone,
          car_info: { brand: "Toyota", model: "Camry", year: 2018 }
        },
        telegram_user: @telegram_user
      )

      # NOTE: Our validation uses simple regex, so all these should pass
      assert booking.valid?, "Phone #{phone} should be valid"
    end
  end

  test "should reject invalid phone format" do
    invalid_phones = [
      "123",
      "abc123",
      "+7abc1234567",
      "phone",
      "123456789" # менее 10 цифр
    ]

    invalid_phones.each do |phone|
      booking = Booking.new(
        meta: {
          customer_name: "Иван",
          customer_phone: phone,
          car_info: { brand: "Toyota", model: "Camry", year: 2018 }
        },
        telegram_user: @telegram_user
      )

      assert_not booking.valid?, "Phone #{phone} should be invalid"
      assert_includes booking.errors[:meta], "телефон клиента должен содержать минимум 10 цифр"
    end
  end

  # Test associations
  test "should belong to telegram_user" do
    booking = Booking.create!(
      meta: {
        customer_name: "Иван",
        customer_phone: "+7(916)123-45-67",
        car_info: { brand: "Toyota", model: "Camry", year: 2018 }
      },
      telegram_user: @telegram_user,
      chat: @chat
    )

    assert_equal @telegram_user, booking.telegram_user
  end

  test "should belong to chat" do
    booking = Booking.create!(
      meta: {
        customer_name: "Иван",
        customer_phone: "+7(916)123-45-67",
        car_info: { brand: "Toyota", model: "Camry", year: 2018 }
      },
      telegram_user: @telegram_user,
      chat: @chat
    )

    assert_equal @chat, booking.chat
  end

  test "should allow nil chat" do
    booking = Booking.create!(
      meta: {
        customer_name: "Иван",
        customer_phone: "+7(916)123-45-67",
        car_info: { brand: "Toyota", model: "Camry", year: 2018 }
      },
      telegram_user: @telegram_user,
      chat: nil
    )

    assert booking.valid?
    assert_nil booking.chat
  end

  test "should have upcoming scope" do
    old_booking = Booking.create!(
      meta: {
        customer_name: "Старый клиент",
        customer_phone: "+7(916)111-11-11",
        car_info: { brand: "Old", model: "Car", year: 2000 }
      },
      telegram_user: @telegram_user,
      created_at: 2.days.ago
    )

    recent_booking = Booking.create!(
      meta: {
        customer_name: "Новый клиент",
        customer_phone: "+7(916)222-22-22",
        car_info: { brand: "New", model: "Car", year: 2023 }
      },
      telegram_user: @telegram_user,
      created_at: 1.hour.ago
    )

    upcoming_bookings = Booking.upcoming
    assert_includes upcoming_bookings, recent_booking
    assert_not_includes upcoming_bookings, old_booking
  end

  # Test helper methods
  test "should extract customer_name from meta" do
    booking_data = {
      customer_name: "Иван Иванов",
      customer_phone: "+7(916)123-45-67",
      car_info: { brand: "Toyota", model: "Camry", year: 2018 }
    }

    booking = Booking.create!(
      meta: booking_data,
      telegram_user: @telegram_user
    )

    assert_equal "Иван Иванов", booking.customer_name
  end

  test "should extract customer_phone from meta" do
    booking_data = {
      customer_name: "Иван",
      customer_phone: "+7(916)123-45-67",
      car_info: { brand: "Toyota", model: "Camry", year: 2018 }
    }

    booking = Booking.create!(
      meta: booking_data,
      telegram_user: @telegram_user
    )

    assert_equal "+7(916)123-45-67", booking.customer_phone
  end

  test "should extract car_info from meta" do
    car_info = { "brand" => "Toyota", "model" => "Camry", "year" => 2018 }
    booking_data = {
      customer_name: "Иван",
      customer_phone: "+7(916)123-45-67",
      car_info: car_info
    }

    booking = Booking.create!(
      meta: booking_data,
      telegram_user: @telegram_user
    )

    assert_equal car_info, booking.car_info
  end

  test "should return nil for missing meta fields" do
    booking = Booking.new(
      meta: {},
      telegram_user: @telegram_user
    )

    # Этот тест проверяет только методы доступа, а не создание
    assert_nil booking.customer_name
    assert_nil booking.customer_phone
    assert_nil booking.car_info
    assert_nil booking.preferred_date
    assert_nil booking.preferred_time
  end
end
