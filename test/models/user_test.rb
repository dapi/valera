# frozen_string_literal: true

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test 'valid user' do
    user = User.new(email: 'test@example.com', name: 'Test User')
    assert user.valid?
  end

  test 'requires email' do
    user = User.new(email: nil, name: 'Test User')
    assert_not user.valid?
    assert user.errors[:email].any?
  end

  test 'requires name' do
    user = User.new(email: 'test@example.com', name: nil)
    assert_not user.valid?
    assert user.errors[:name].any?
  end

  test 'requires unique email' do
    existing_user = users(:one)
    user = User.new(email: existing_user.email, name: 'Another User')
    assert_not user.valid?
    assert user.errors[:email].any?
  end

  test 'rejects invalid email format' do
    invalid_emails = [
      'invalid',
      'invalid@',
      '@example.com',
      'invalid@example',
      'invalid email@example.com'
    ]

    invalid_emails.each do |email|
      user = User.new(email: email, name: 'Test User')
      assert_not user.valid?, "Expected #{email} to be invalid"
      assert user.errors[:email].any?, "Expected error for #{email}"
    end
  end

  test 'accepts valid email format' do
    valid_emails = [
      'user@example.com',
      'user.name@example.com',
      'user+tag@example.com',
      'user@subdomain.example.com'
    ]

    valid_emails.each do |email|
      user = User.new(email: email, name: 'Test User')
      assert user.valid?, "Expected #{email} to be valid, got errors: #{user.errors.full_messages}"
    end
  end

  test 'has many owned_tenants' do
    user = users(:one)
    assert_respond_to user, :owned_tenants
  end

  test 'has many tenant_memberships' do
    user = users(:operator_user)
    assert_respond_to user, :tenant_memberships
    assert_includes user.tenant_memberships, tenant_memberships(:operator_on_tenant_one)
  end

  test 'has many member_tenants through tenant_memberships' do
    user = users(:operator_user)
    assert_respond_to user, :member_tenants
    assert_includes user.member_tenants, tenants(:one)
  end

  test 'accessible_tenants includes owned tenants' do
    user = users(:one)
    assert_includes user.accessible_tenants, tenants(:one)
  end

  test 'accessible_tenants includes member tenants' do
    user = users(:operator_user)
    assert_includes user.accessible_tenants, tenants(:one)
  end

  test 'accessible_tenants returns unique tenants' do
    user = users(:one)
    # Owner should not have duplicates
    assert_equal user.accessible_tenants.uniq, user.accessible_tenants
  end

  test 'membership_for returns membership for tenant' do
    user = users(:operator_user)
    membership = user.membership_for(tenants(:one))
    assert_equal tenant_memberships(:operator_on_tenant_one), membership
  end

  test 'membership_for returns nil for non-member tenant' do
    user = users(:operator_user)
    assert_nil user.membership_for(tenants(:two))
  end

  test 'owner_of? returns true for owned tenant' do
    user = users(:one)
    assert user.owner_of?(tenants(:one))
  end

  test 'owner_of? returns false for non-owned tenant' do
    user = users(:one)
    assert_not user.owner_of?(tenants(:two))
  end

  test 'has_access_to? returns true for owner' do
    user = users(:one)
    assert user.has_access_to?(tenants(:one))
  end

  test 'has_access_to? returns true for member' do
    user = users(:operator_user)
    assert user.has_access_to?(tenants(:one))
  end

  test 'has_access_to? returns false for non-member' do
    user = users(:operator_user)
    assert_not user.has_access_to?(tenants(:two))
  end

  test 'telegram_only_user? returns true for new telegram user without email' do
    telegram_user = telegram_users(:one)
    user = User.new(name: 'Telegram User', telegram_user_id: telegram_user.id)
    assert user.telegram_only_user?
  end

  test 'telegram_only_user? returns false for persisted user' do
    user = users(:telegram_only_user)
    assert_not user.telegram_only_user?
  end

  test 'telegram_only_user? returns false for user with email' do
    user = User.new(email: 'test@example.com', name: 'Test', telegram_user_id: 1)
    assert_not user.telegram_only_user?
  end

  test 'allows blank email for telegram only users' do
    telegram_user = telegram_users(:one)
    user = User.new(name: 'Telegram Only', telegram_user_id: telegram_user.id)
    assert user.valid?
  end
end
