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
    AnalyticsService.stubs(:track_conversion).returns(nil)

    result = tool.execute(
      customer_name: 'Test Customer',
      customer_phone: '+7(900)123-45-67',
      car_brand: 'Toyota',
      dialog_context: { date: '2024-12-01' },
      details: 'Test booking details'
    )

    assert_match(/Заявка под номером \d+-\d+ сохранена/, result)

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

  test 'analytics enqueue failure rolls back booking instead of returning false failure' do
    AnalyticsService.stubs(:track_conversion).raises(ActiveJob::EnqueueError, 'Synthetic analytics failure')
    assert_no_difference 'Booking.count' do
      assert_raises(ActiveJob::EnqueueError) do
        BookingTool.new(chat: @chat).execute(details: 'Synthetic', dialog_context: {})
      end
    end
  end

  test 'repeated tool call for one update returns existing booking without duplicate analytics' do
    update = TelegramUpdate.accept!(tenant: @tenant, payload: { 'update_id' => 99 })
    AnalyticsService.expects(:track_conversion).once
    Current.set(telegram_update: update) do
      assert_difference 'Booking.count', 1 do
        tool = BookingTool.new(chat: @chat)
        first = tool.execute(details: 'Synthetic', dialog_context: {})
        assert_equal first, tool.execute(details: 'Synthetic', dialog_context: {})
      end
    end
  end

  test 'notification enqueue failure does not commit an unnotified booking' do
    BookingNotificationJob.stubs(:perform_later).raises(ActiveJob::EnqueueError, 'Synthetic queue failure')
    assert_no_difference 'Booking.count' do
      assert_raises(ActiveJob::EnqueueError) do
        BookingTool.new(chat: @chat).execute(details: 'Synthetic', dialog_context: {})
      end
    end
  end

  test 'handles telegram_user access through chat' do
    tool = BookingTool.new(chat: @chat)

    # telegram_user should be accessible through chat -> client -> telegram_user
    telegram_user = tool.send(:telegram_user)
    assert_not_nil telegram_user
    assert_equal @chat.client.telegram_user, telegram_user
  end
end
