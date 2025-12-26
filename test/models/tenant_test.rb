# frozen_string_literal: true

require 'test_helper'

class TenantTest < ActiveSupport::TestCase
  setup do
    # Stub Telegram API для всех тестов
    stub_telegram_get_me
  end

  test 'valid tenant with all required attributes' do
    tenant = Tenant.new(
      name: 'Test AutoService',
      bot_token: '123456789:ABCdefGHIjklMNOpqrsTUVwxyz'
    )
    assert tenant.valid?
  end

  test 'generates key on create' do
    tenant = Tenant.create!(
      name: 'Test AutoService',
      bot_token: '123456790:ABCdefGHIjklMNOpqrsTUVwxyz'
    )
    assert_not_nil tenant.key
    assert_equal Tenant::KEY_LENGTH, tenant.key.length
  end

  test 'generates webhook_secret on create' do
    tenant = Tenant.create!(
      name: 'Test AutoService',
      bot_token: '123456791:ABCdefGHIjklMNOpqrsTUVwxyz'
    )
    assert_not_nil tenant.webhook_secret
  end

  test 'does not regenerate key if provided' do
    custom_key = 'c12'
    tenant = Tenant.create!(
      name: 'Test AutoService',
      bot_token: '123456792:ABCdefGHIjklMNOpqrsTUVwxyz',
      key: custom_key
    )
    assert_equal custom_key, tenant.key
  end

  test 'validates name presence' do
    tenant = Tenant.new(bot_token: '123456793:ABCdefGHIjklMNOpqrsTUVwxyz')
    assert_not tenant.valid?
    assert tenant.errors[:name].any?
  end

  test 'validates bot_token presence' do
    tenant = Tenant.new(name: 'Test', bot_username: 'bot')
    assert_not tenant.valid?
    assert tenant.errors[:bot_token].any?
  end

  test 'validates bot_token format' do
    tenant = Tenant.new(name: 'Test', bot_token: 'invalid_token')
    assert_not tenant.valid?
    assert tenant.errors[:bot_token].any?
  end

  test 'accepts valid bot_token format' do
    tenant = Tenant.new(name: 'Test', bot_token: '123456794:ABCdefGHIjklMNOpqrsTUVwxyz')
    tenant.valid?
    assert_empty tenant.errors[:bot_token].select { |e| e.include?('формат') }
  end

  test 'validates bot_token uniqueness' do
    existing = tenants(:one)
    tenant = Tenant.new(
      name: 'Another Service',
      bot_token: existing.bot_token
    )
    assert_not tenant.valid?
    assert tenant.errors[:bot_token].any?
  end

  test 'validates key uniqueness' do
    existing = tenants(:one)
    tenant = Tenant.new(
      name: 'Another Service',
      bot_token: '123456795:ABCdefGHIjklMNOpqrsTUVwxyz',
      key: existing.key
    )
    assert_not tenant.valid?
    assert tenant.errors[:key].any?
  end

  test 'validates key length' do
    tenant = Tenant.new(
      name: 'Test',
      bot_token: '123456796:ABCdefGHIjklMNOpqrsTUVwxyz',
      key: 'short'
    )
    assert_not tenant.valid?
    assert tenant.errors[:key].any?
  end

  test 'validates key format - only letters and digits allowed' do
    # Keys with special characters should be invalid (after downcase)
    # Each key is exactly KEY_LENGTH (3) and contains at least one invalid char
    invalid_keys = %w[a-b a_b a.b a@b a!b]

    invalid_keys.each do |invalid_key|
      tenant = Tenant.new(
        name: 'Test',
        bot_token: '123456796:ABCdefGHIjklMNOpqrsTUVwxyz',
        key: invalid_key
      )
      assert_not tenant.valid?, "Key '#{invalid_key}' should be invalid"
      assert tenant.errors[:key].any?, "Key '#{invalid_key}' should have error"
    end
  end

  test 'accepts valid key format' do
    tenant = Tenant.new(
      name: 'Test',
      bot_token: '999456796:ABCdefGHIjklMNOpqrsTUVwxyz',
      key: 'ab1'
    )
    tenant.valid?
    assert_empty tenant.errors[:key]
  end

  test 'rejects reserved subdomain keys' do
    ApplicationConfig.reserved_subdomains.each do |reserved_key|
      # Pad to KEY_LENGTH if shorter
      test_key = reserved_key[0, Tenant::KEY_LENGTH].ljust(Tenant::KEY_LENGTH, 'a')
      # Only test if it matches the reserved key exactly (for 3-char keys like 'www')
      next unless reserved_key.length == Tenant::KEY_LENGTH

      tenant = Tenant.new(
        name: 'Test',
        bot_token: "123456796:ABCdefGHIjklMNOpqrsTUVwxyz#{reserved_key}",
        key: reserved_key
      )
      assert_not tenant.valid?, "Key '#{reserved_key}' should be invalid (reserved)"
      assert tenant.errors[:key].any?, "Key '#{reserved_key}' should have reserved error"
    end
  end

  test 'accepts non-reserved key' do
    tenant = Tenant.new(
      name: 'Test',
      bot_token: '997456796:ABCdefGHIjklMNOpqrsTUVwxyz',
      key: 'xyz'
    )
    tenant.valid?
    assert_empty tenant.errors[:key].select { |e| e.include?('reserved') || e.include?('зарезервирован') }
  end

  test 'downcases key before validation' do
    tenant = Tenant.create!(
      name: 'Test',
      bot_token: '998456796:ABCdefGHIjklMNOpqrsTUVwxyz',
      key: 'ABC'
    )
    assert_equal 'abc', tenant.key
  end

  test 'bot_client returns Telegram Bot client' do
    tenant = tenants(:one)
    bot = tenant.bot_client

    assert bot.respond_to?(:send_message)
  end

  test 'bot_client is memoized' do
    tenant = tenants(:one)
    bot1 = tenant.bot_client
    bot2 = tenant.bot_client

    assert_same bot1, bot2
  end

  test 'has_many clients' do
    tenant = tenants(:one)
    assert_respond_to tenant, :clients
    assert_kind_of ActiveRecord::Associations::CollectionProxy, tenant.clients
  end

  test 'has_many chats' do
    tenant = tenants(:one)
    assert_respond_to tenant, :chats
  end

  test 'has_many bookings' do
    tenant = tenants(:one)
    assert_respond_to tenant, :bookings
  end

  test 'has_many analytics_events' do
    tenant = tenants(:one)
    assert_respond_to tenant, :analytics_events
  end

  test 'belongs_to owner optionally' do
    tenant = Tenant.new(
      name: 'No Owner Service',
      bot_token: '123456797:ABCdefGHIjklMNOpqrsTUVwxyz'
    )
    assert tenant.valid?
    assert_nil tenant.owner
  end

  # === Tests for new callbacks ===

  test 'fetches bot_username from Telegram API on create' do
    stub_telegram_get_me(username: 'my_awesome_bot')

    tenant = Tenant.create!(
      name: 'Auto Fetch Username',
      bot_token: '123456798:ABCdefGHIjklMNOpqrsTUVwxyz'
    )

    assert_equal 'my_awesome_bot', tenant.bot_username
  end

  test 'fetches bot_username when bot_token changes' do
    tenant = tenants(:one)
    stub_telegram_get_me(username: 'updated_bot_username')

    tenant.update!(bot_token: '999888777:NewTokenForUpdate')

    assert_equal 'updated_bot_username', tenant.bot_username
  end

  test 'does not fetch bot_username if already provided' do
    Telegram::Bot::Client.any_instance.expects(:get_me).never

    tenant = Tenant.new(
      name: 'Provided Username',
      bot_token: '123456799:ABCdefGHIjklMNOpqrsTUVwxyz',
      bot_username: 'provided_username'
    )
    tenant.valid?
  end

  test 'allows nil values for prompt fields on create' do
    tenant = Tenant.create!(
      name: 'Defaults Test',
      bot_token: '123456800:ABCdefGHIjklMNOpqrsTUVwxyz'
    )

    assert_nil tenant.system_prompt
    assert_nil tenant.welcome_message
    assert_nil tenant.company_info
    assert_nil tenant.price_list
  end

  test '*_or_default methods return config defaults when fields are nil' do
    tenant = Tenant.create!(
      name: 'Defaults Test',
      bot_token: '123456801:ABCdefGHIjklMNOpqrsTUVwxyz'
    )

    assert_equal ApplicationConfig.system_prompt, tenant.system_prompt_or_default
    assert_equal ApplicationConfig.welcome_message_template, tenant.welcome_message_or_default
    assert_equal ApplicationConfig.company_info, tenant.company_info_or_default
    assert_equal ApplicationConfig.price_list, tenant.price_list_or_default
  end

  test '*_or_default methods return tenant values when fields are set' do
    custom_prompt = 'Custom system prompt'
    custom_welcome = 'Custom welcome'

    tenant = Tenant.create!(
      name: 'Custom Prompt Test',
      bot_token: '123456802:ABCdefGHIjklMNOpqrsTUVwxyz',
      system_prompt: custom_prompt,
      welcome_message: custom_welcome
    )

    assert_equal custom_prompt, tenant.system_prompt_or_default
    assert_equal custom_welcome, tenant.welcome_message_or_default
  end

  test 'adds error when Telegram API fails' do
    error = Telegram::Bot::Error.new('Invalid token')
    Telegram::Bot::Client.any_instance.stubs(:get_me).raises(error)

    tenant = Tenant.new(
      name: 'API Fail Test',
      bot_token: '123456802:InvalidToken'
    )

    assert_not tenant.valid?
    assert tenant.errors[:bot_token].any?
  end

  # === Counter Cache Tests ===

  test 'chats_count increments when chat is created' do
    tenant = tenants(:one)
    client = clients(:one)
    initial_count = tenant.chats_count

    Chat.create!(tenant: tenant, client: client)

    assert_equal initial_count + 1, tenant.reload.chats_count
  end

  test 'chats_count decrements when chat is destroyed' do
    tenant = tenants(:one)
    chat = chats(:one)
    initial_count = tenant.chats_count

    chat.destroy

    assert_equal initial_count - 1, tenant.reload.chats_count
  end

  test 'clients_count increments when client is created' do
    tenant = tenants(:one)
    telegram_user = telegram_users(:unlinked)
    initial_count = tenant.clients_count

    Client.create!(tenant: tenant, telegram_user: telegram_user)

    assert_equal initial_count + 1, tenant.reload.clients_count
  end

  test 'clients_count decrements when client is destroyed' do
    tenant = tenants(:one)
    # Create a client without associated chats for clean destruction
    telegram_user = TelegramUser.create!(username: 'test_counter_cache', first_name: 'Test')
    client = Client.create!(tenant: tenant, telegram_user: telegram_user)
    initial_count = tenant.reload.clients_count

    client.destroy

    assert_equal initial_count - 1, tenant.reload.clients_count
  end

  test 'bookings_count increments when booking is created' do
    tenant = tenants(:one)
    client = clients(:one)
    chat = chats(:one)
    initial_count = tenant.bookings_count

    Booking.create!(tenant: tenant, client: client, chat: chat)

    assert_equal initial_count + 1, tenant.reload.bookings_count
  end

  test 'bookings_count decrements when booking is destroyed' do
    tenant = tenants(:one)
    client = clients(:one)
    chat = chats(:one)
    booking = Booking.create!(tenant: tenant, client: client, chat: chat)
    initial_count = tenant.reload.bookings_count

    booking.destroy

    assert_equal initial_count - 1, tenant.reload.bookings_count
  end

  private

  def stub_telegram_get_me(username: 'stubbed_bot')
    response = { 'ok' => true, 'result' => { 'username' => username, 'id' => 123_456_789, 'first_name' => 'Test Bot' } }
    Telegram::Bot::Client.any_instance.stubs(:get_me).returns(response)
  end
end
