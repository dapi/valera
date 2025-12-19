# frozen_string_literal: true

require 'test_helper'

# Тесты для BookingTool
#
# Проверяет корректность создания заявок через multi-tenancy структуру
class BookingToolTest < ActiveSupport::TestCase
  setup do
    @tenant = tenants(:one)
    @client = clients(:one)
    @chat = chats(:one)
  end

  test 'initializes with chat only' do
    tool = BookingTool.new(chat: @chat)
    assert_not_nil tool
  end

  test 'creates booking with tenant and client from chat' do
    tool = BookingTool.new(chat: @chat)

    # Mock the analytics to avoid side effects
    AnalyticsService.stub(:track_conversion, nil) do
      result = tool.execute(
        customer_name: 'Test Customer',
        customer_phone: '+7(900)123-45-67',
        car_brand: 'Toyota',
        dialog_context: { date: '2024-12-01' },
        details: 'Test booking details'
      )

      assert_match(/Заявка под номером \d+ отправлена/, result.text)
    end

    # Verify booking was created with correct associations
    booking = Booking.last
    assert_equal @chat.tenant, booking.tenant
    assert_equal @chat.client, booking.client
    assert_equal @chat, booking.chat
  end

  test 'accesses telegram_user through chat.client' do
    tool = BookingTool.new(chat: @chat)

    # The private telegram_user method should return the chat's telegram_user
    telegram_user = tool.send(:telegram_user)
    assert_equal @chat.telegram_user, telegram_user
  end

  test 'handles telegram_user access through chat' do
    tool = BookingTool.new(chat: @chat)

    # telegram_user should be accessible through chat -> client -> telegram_user
    telegram_user = tool.send(:telegram_user)
    assert_not_nil telegram_user
    assert_equal @chat.client.telegram_user, telegram_user
  end
end
