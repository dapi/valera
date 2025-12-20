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
end
