# frozen_string_literal: true

require 'test_helper'

class BookingTest < ActiveSupport::TestCase
  test 'assigns sequential number within tenant on create' do
    tenant = tenants(:one)
    client = clients(:one)
    chat = chats(:one)

    # Удаляем существующие bookings для чистоты теста
    Booking.where(tenant: tenant).delete_all

    booking1 = Booking.create!(
      tenant: tenant,
      client: client,
      chat: chat,
      meta: { customer_name: 'Test 1' }
    )

    assert_equal 1, booking1.number
    assert_equal "#{tenant.id}-1", booking1.public_number

    booking2 = Booking.create!(
      tenant: tenant,
      client: client,
      chat: chat,
      meta: { customer_name: 'Test 2' }
    )

    assert_equal 2, booking2.number
    assert_equal "#{tenant.id}-2", booking2.public_number
  end

  test 'each tenant has independent numbering' do
    tenant_one = tenants(:one)
    tenant_two = tenants(:two)

    # Удаляем существующие bookings для чистоты теста
    Booking.delete_all

    booking_one = Booking.create!(
      tenant: tenant_one,
      client: clients(:one),
      chat: chats(:one),
      meta: { customer_name: 'Tenant One Booking' }
    )

    booking_two = Booking.create!(
      tenant: tenant_two,
      client: clients(:two),
      chat: chats(:two),
      meta: { customer_name: 'Tenant Two Booking' }
    )

    # Оба тенанта начинают нумерацию с 1
    assert_equal 1, booking_one.number
    assert_equal 1, booking_two.number

    # Публичные номера разные
    assert_equal "#{tenant_one.id}-1", booking_one.public_number
    assert_equal "#{tenant_two.id}-1", booking_two.public_number
    assert_not_equal booking_one.public_number, booking_two.public_number
  end

  test 'find_by_public_number returns correct booking' do
    booking = bookings(:one)

    found = Booking.find_by_public_number(booking.public_number)

    assert_equal booking, found
  end

  test 'find_by_public_number returns nil for invalid format' do
    assert_nil Booking.find_by_public_number('invalid')
    assert_nil Booking.find_by_public_number('')
    assert_nil Booking.find_by_public_number(nil)
    assert_nil Booking.find_by_public_number('abc-def')
    assert_nil Booking.find_by_public_number('0-0')
  end

  test 'find_by_public_number returns nil for non-existent booking' do
    assert_nil Booking.find_by_public_number('999999-999999')
  end

  test 'public_number is globally unique' do
    booking_one = bookings(:one)
    booking_two = bookings(:tenant_two_booking)

    # Оба имеют number=1, но разные public_number
    assert_equal booking_one.number, booking_two.number
    assert_not_equal booking_one.public_number, booking_two.public_number
  end

  test 'increments chat bookings_count on create' do
    chat = chats(:one)
    chat.update_columns(bookings_count: 0)
    initial_count = chat.bookings_count

    Booking.create!(
      tenant: chat.tenant,
      client: chat.client,
      chat: chat,
      meta: { customer_name: 'Test' }
    )

    assert_equal initial_count + 1, chat.reload.bookings_count
  end

  test 'sets first_booking_at on first booking' do
    chat = chats(:one)
    chat.update_columns(first_booking_at: nil, last_booking_at: nil, bookings_count: 0)
    chat.bookings.delete_all

    freeze_time do
      booking = Booking.create!(
        tenant: chat.tenant,
        client: chat.client,
        chat: chat,
        meta: { customer_name: 'First Booking' }
      )

      chat.reload
      assert_equal booking.created_at, chat.first_booking_at
      assert_equal booking.created_at, chat.last_booking_at
    end
  end

  test 'does not change first_booking_at on subsequent bookings' do
    chat = chats(:one)
    first_booking_time = 1.day.ago
    chat.update_columns(
      first_booking_at: first_booking_time,
      last_booking_at: first_booking_time,
      bookings_count: 1
    )

    freeze_time do
      Booking.create!(
        tenant: chat.tenant,
        client: chat.client,
        chat: chat,
        meta: { customer_name: 'Second Booking' }
      )

      chat.reload
      assert_equal first_booking_time.to_i, chat.first_booking_at.to_i
      assert_equal Time.current.to_i, chat.last_booking_at.to_i
    end
  end

  test 'updates last_booking_at on each booking' do
    chat = chats(:one)
    chat.update_columns(bookings_count: 0)
    chat.bookings.delete_all

    first_booking = nil
    travel_to 2.days.ago do
      first_booking = Booking.create!(
        tenant: chat.tenant,
        client: chat.client,
        chat: chat,
        meta: { customer_name: 'First' }
      )
    end

    chat.reload
    assert_equal first_booking.created_at, chat.last_booking_at

    second_booking = nil
    travel_to 1.day.ago do
      second_booking = Booking.create!(
        tenant: chat.tenant,
        client: chat.client,
        chat: chat,
        meta: { customer_name: 'Second' }
      )
    end

    chat.reload
    assert_equal second_booking.created_at, chat.last_booking_at
    assert_not_equal first_booking.created_at, chat.last_booking_at
  end
end
