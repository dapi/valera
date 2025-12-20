# frozen_string_literal: true

require 'test_helper'

class TenantTest < ActiveSupport::TestCase
  test 'valid tenant with all required attributes' do
    tenant = Tenant.new(
      name: 'Test AutoService',
      bot_token: 'unique_token_123',
      bot_username: 'test_bot'
    )
    assert tenant.valid?
  end

  test 'generates key on create' do
    tenant = Tenant.create!(
      name: 'Test AutoService',
      bot_token: 'token_for_key_test',
      bot_username: 'test_bot'
    )
    assert_not_nil tenant.key
    assert_equal Tenant::KEY_LENGTH, tenant.key.length
  end

  test 'generates webhook_secret on create' do
    tenant = Tenant.create!(
      name: 'Test AutoService',
      bot_token: 'token_for_secret_test',
      bot_username: 'test_bot'
    )
    assert_not_nil tenant.webhook_secret
  end

  test 'does not regenerate key if provided' do
    custom_key = 'custom12'
    tenant = Tenant.create!(
      name: 'Test AutoService',
      bot_token: 'token_custom_key',
      bot_username: 'test_bot',
      key: custom_key
    )
    assert_equal custom_key, tenant.key
  end

  test 'validates name presence' do
    tenant = Tenant.new(bot_token: 'token', bot_username: 'bot')
    assert_not tenant.valid?
    assert tenant.errors[:name].any?
  end

  test 'validates bot_token presence' do
    tenant = Tenant.new(name: 'Test', bot_username: 'bot')
    assert_not tenant.valid?
    assert tenant.errors[:bot_token].any?
  end

  test 'validates bot_username presence' do
    tenant = Tenant.new(name: 'Test', bot_token: 'token')
    assert_not tenant.valid?
    assert tenant.errors[:bot_username].any?
  end

  test 'validates bot_token uniqueness' do
    existing = tenants(:one)
    tenant = Tenant.new(
      name: 'Another Service',
      bot_token: existing.bot_token,
      bot_username: 'another_bot'
    )
    assert_not tenant.valid?
    assert tenant.errors[:bot_token].any?
  end

  test 'validates key uniqueness' do
    existing = tenants(:one)
    tenant = Tenant.new(
      name: 'Another Service',
      bot_token: 'new_unique_token',
      bot_username: 'another_bot',
      key: existing.key
    )
    assert_not tenant.valid?
    assert tenant.errors[:key].any?
  end

  test 'validates key length' do
    tenant = Tenant.new(
      name: 'Test',
      bot_token: 'token_length_test',
      bot_username: 'bot',
      key: 'short'
    )
    assert_not tenant.valid?
    assert tenant.errors[:key].any?
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
      bot_token: 'token_no_owner',
      bot_username: 'no_owner_bot'
    )
    assert tenant.valid?
    assert_nil tenant.owner
  end
end
