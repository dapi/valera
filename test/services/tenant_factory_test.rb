# frozen_string_literal: true

require 'test_helper'

class TenantFactoryTest < ActiveSupport::TestCase
  test 'creates tenant with required attributes' do
    result = TenantFactory.create(
      name: 'Test AutoService',
      bot_token: 'factory_test_token_1',
      bot_username: 'factory_test_bot'
    )

    assert result.success?
    assert_not_nil result.tenant
    assert result.tenant.persisted?
    assert_equal 'Test AutoService', result.tenant.name
    assert_equal 'factory_test_token_1', result.tenant.bot_token
    assert_equal 'factory_test_bot', result.tenant.bot_username
  end

  test 'generates key and webhook_secret automatically' do
    result = TenantFactory.create(
      name: 'Test AutoService',
      bot_token: 'factory_test_token_2',
      bot_username: 'factory_test_bot'
    )

    assert result.success?
    assert_not_nil result.tenant.key
    assert_equal Tenant::KEY_LENGTH, result.tenant.key.length
    assert_not_nil result.tenant.webhook_secret
  end

  test 'creates tenant with owner' do
    owner = users(:one)
    result = TenantFactory.create(
      name: 'Test AutoService',
      bot_token: 'factory_test_token_3',
      bot_username: 'factory_test_bot',
      owner: owner
    )

    assert result.success?
    assert_equal owner, result.tenant.owner
  end

  test 'creates tenant with additional attributes' do
    result = TenantFactory.create(
      name: 'Test AutoService',
      bot_token: 'factory_test_token_4',
      bot_username: 'factory_test_bot',
      system_prompt: 'Custom prompt',
      welcome_message: 'Custom welcome',
      company_info: 'Custom info',
      price_list: 'Custom prices',
      admin_chat_id: 123_456
    )

    assert result.success?
    assert_equal 'Custom prompt', result.tenant.system_prompt
    assert_equal 'Custom welcome', result.tenant.welcome_message
    assert_equal 'Custom info', result.tenant.company_info
    assert_equal 'Custom prices', result.tenant.price_list
    assert_equal 123_456, result.tenant.admin_chat_id
  end

  test 'returns failure for invalid tenant' do
    result = TenantFactory.create(
      name: '',
      bot_token: 'factory_test_token_5',
      bot_username: 'factory_test_bot'
    )

    assert result.failure?
    assert_not result.tenant.persisted?
    assert result.errors.any? { |e| e.include?('Name') || e.include?('name') }
  end

  test 'returns failure for duplicate bot_token' do
    existing = tenants(:one)
    result = TenantFactory.create(
      name: 'Another Service',
      bot_token: existing.bot_token,
      bot_username: 'another_bot'
    )

    assert result.failure?
    assert result.errors.any? { |e| e.include?('Bot token') || e.include?('bot_token') }
  end

  test 'creates tenant without webhook when register_webhook is false' do
    result = TenantFactory.create(
      name: 'Test AutoService',
      bot_token: 'factory_test_token_6',
      bot_username: 'factory_test_bot',
      register_webhook: false
    )

    assert result.success?
    assert_nil result.webhook_result
  end
end
