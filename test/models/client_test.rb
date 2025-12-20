# frozen_string_literal: true

require 'test_helper'

# Тесты для модели Client
#
# Проверяет связи, валидации и поведение при удалении
class ClientTest < ActiveSupport::TestCase
  setup do
    @tenant = tenants(:one)
    @telegram_user = telegram_users(:one)
    @client = clients(:one)
  end

  test 'fixture is valid' do
    assert @client.valid?
    assert @client.persisted?
  end

  test 'belongs to tenant' do
    assert_respond_to @client, :tenant
    assert_not_nil @client.tenant
  end

  test 'belongs to telegram_user' do
    assert_respond_to @client, :telegram_user
    assert_not_nil @client.telegram_user
  end

  test 'has many vehicles' do
    assert_respond_to @client, :vehicles
  end

  test 'has many chats with dependent destroy' do
    # Verify association exists
    assert_respond_to @client, :chats

    # Create a chat for this client
    chat = Chat.create!(tenant: @tenant, client: @client)

    # Verify chat exists
    assert_includes @client.chats.reload, chat

    # Destroy client should destroy associated chats
    assert_difference 'Chat.count', -(@client.chats.count) do
      @client.destroy!
    end
  end

  test 'has many bookings with dependent destroy' do
    # Verify association exists
    assert_respond_to @client, :bookings

    # Create a booking for this client
    chat = Chat.create!(tenant: @tenant, client: @client)
    booking = Booking.create!(
      tenant: @tenant,
      client: @client,
      chat: chat,
      details: 'Test booking'
    )

    # Verify booking exists
    assert_includes @client.bookings.reload, booking

    # Get counts before destroy
    bookings_count = @client.bookings.count
    chats_count = @client.chats.count

    # Destroy client should destroy associated bookings and chats
    @client.destroy!

    # Verify bookings were destroyed (not nullified)
    assert_nil Booking.find_by(id: booking.id)
    assert_nil Chat.find_by(id: chat.id)
  end

  test 'validates uniqueness of telegram_user_id scoped to tenant_id' do
    duplicate = Client.new(
      tenant: @client.tenant,
      telegram_user: @client.telegram_user
    )

    assert_not duplicate.valid?
    assert duplicate.errors[:telegram_user_id].any?, 'Expected validation error on telegram_user_id'
  end

  test 'allows same telegram_user in different tenants' do
    Telegram::Bot::Client.any_instance.stubs(:get_me).returns({ 'ok' => true, 'result' => { 'username' => 'other_bot' } })

    other_tenant = Tenant.create!(
      name: 'Other Tenant',
      bot_token: '333333333:ABCdefGHIjklMNOpqrsTUVwxyz_other'
    )

    other_client = Client.new(
      tenant: other_tenant,
      telegram_user: @client.telegram_user
    )

    assert other_client.valid?
  end

  test 'display_name returns client name if present' do
    @client.name = 'Custom Name'
    assert_equal 'Custom Name', @client.display_name
  end

  test 'display_name falls back to telegram_user first_name' do
    @client.name = nil
    @client.telegram_user.first_name = 'TelegramName'
    assert_equal 'TelegramName', @client.display_name
  end

  test 'display_name falls back to Client #id' do
    @client.name = nil
    @client.telegram_user.first_name = nil
    assert_equal "Client ##{@client.id}", @client.display_name
  end
end
