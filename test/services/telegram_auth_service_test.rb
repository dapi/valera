# frozen_string_literal: true

require 'test_helper'

class TelegramAuthServiceTest < ActiveSupport::TestCase
  setup do
    @service = TelegramAuthService.new
    @tenant = tenants(:one)
    @telegram_user = telegram_users(:one)
    @user = users(:one)

    # Use memory store for cache tests (null_store in test env doesn't persist)
    @original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
  end

  teardown do
    Rails.cache = @original_cache
  end

  # === Auth Request Tests ===

  test 'creates auth request and returns short key' do
    key = @service.create_auth_request(
      tenant_key: @tenant.key,
      return_url: 'https://example.com/'
    )

    assert_not_nil key
    assert_kind_of String, key
    assert key.length <= 64, 'Key must fit in Telegram deep link (64 chars max)'
  end

  test 'retrieves auth request data by key' do
    key = @service.create_auth_request(
      tenant_key: @tenant.key,
      return_url: 'https://example.com/'
    )

    data = @service.get_auth_request(key)

    assert_not_nil data
    assert_equal @tenant.key, data[:tenant_key]
    assert_equal 'https://example.com/', data[:return_url]
  end

  test 'returns nil for non-existent auth request' do
    data = @service.get_auth_request('non_existent_key')
    assert_nil data
  end

  test 'deletes auth request' do
    key = @service.create_auth_request(
      tenant_key: @tenant.key,
      return_url: 'https://example.com/'
    )

    @service.delete_auth_request(key)

    assert_nil @service.get_auth_request(key)
  end

  # === Confirm Token Tests ===

  test 'generates confirm token' do
    token = @service.generate_confirm_token(
      telegram_user_id: @telegram_user.id,
      tenant_key: @tenant.key
    )

    assert_not_nil token
    assert_kind_of String, token
  end

  test 'verifies valid confirm token' do
    token = @service.generate_confirm_token(
      telegram_user_id: @telegram_user.id,
      tenant_key: @tenant.key
    )

    data = @service.verify_confirm_token(token)

    assert_not_nil data
    assert_equal @telegram_user.id, data[:telegram_user_id]
    assert_equal @tenant.key, data[:tenant_key]
  end

  test 'returns nil for invalid confirm token' do
    data = @service.verify_confirm_token('invalid_token')
    assert_nil data
  end

  test 'returns nil for expired confirm token' do
    token = @service.generate_confirm_token(
      telegram_user_id: @telegram_user.id,
      tenant_key: @tenant.key
    )

    # Simulate token expiration
    Timecop.travel(10.minutes.from_now) do
      data = @service.verify_confirm_token(token)
      assert_nil data
    end
  end

  # === Invite Token Tests ===

  test 'creates invite token' do
    token = @service.create_invite_token(user_id: @user.id)

    assert_not_nil token
    assert token.start_with?('INV_'), 'Invite token must start with INV_'
  end

  test 'consumes valid invite token' do
    token = @service.create_invite_token(user_id: @user.id)

    data = @service.consume_invite_token(token)

    assert_not_nil data
    assert_equal @user.id, data[:user_id]
  end

  test 'consume removes invite token' do
    token = @service.create_invite_token(user_id: @user.id)

    @service.consume_invite_token(token)
    data = @service.consume_invite_token(token)

    assert_nil data, 'Invite token should be consumed only once'
  end

  test 'returns nil for invalid invite token' do
    data = @service.consume_invite_token('INV_invalid')
    assert_nil data
  end

  # === Link User Tests ===

  test 'links user to telegram user' do
    user = User.create!(
      name: 'Test User',
      email: 'test_link@example.com',
      telegram_user: nil
    )

    # Use unlinked telegram user to avoid unique constraint violation
    unlinked_telegram_user = telegram_users(:unlinked)
    result = @service.link_user_to_telegram(user, unlinked_telegram_user)

    assert result
    user.reload
    assert_equal unlinked_telegram_user.id, user.telegram_user_id
  end

  test 'returns false when user already has telegram linked' do
    user = User.create!(
      name: 'Test User',
      email: 'test_link2@example.com',
      telegram_user: telegram_users(:two)
    )

    result = @service.link_user_to_telegram(user, @telegram_user)

    assert_not result
  end
end
