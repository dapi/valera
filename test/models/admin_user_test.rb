# frozen_string_literal: true

require 'test_helper'

class AdminUserTest < ActiveSupport::TestCase
  test 'valid admin user' do
    admin = AdminUser.new(email: 'test@example.com', password: 'password')
    assert admin.valid?
  end

  test 'invalid without email' do
    admin = AdminUser.new(password: 'password')
    assert_not admin.valid?
    assert admin.errors[:email].any?
  end

  test 'invalid without password' do
    admin = AdminUser.new(email: 'test@example.com')
    assert_not admin.valid?
    assert admin.errors[:password].any?
  end

  test 'invalid with duplicate email' do
    AdminUser.create!(email: 'duplicate@example.com', password: 'password')
    admin = AdminUser.new(email: 'duplicate@example.com', password: 'password')
    assert_not admin.valid?
    assert admin.errors[:email].any?
  end

  test 'authenticate with correct password' do
    admin = AdminUser.create!(email: 'auth@example.com', password: 'password')
    assert admin.authenticate('password')
  end

  test 'authenticate fails with wrong password' do
    admin = AdminUser.create!(email: 'auth2@example.com', password: 'password')
    assert_not admin.authenticate('wrong')
  end

  # Role tests
  test 'default role is manager' do
    admin = AdminUser.create!(email: 'default_role@example.com', password: 'password')
    assert admin.manager?
    assert_not admin.superuser?
  end

  test 'superuser role' do
    admin = admin_users(:superuser)
    assert admin.superuser?
    assert_not admin.manager?
  end

  test 'manager role' do
    admin = admin_users(:manager)
    assert admin.manager?
    assert_not admin.superuser?
  end

  test 'can change role from manager to superuser' do
    admin = AdminUser.create!(email: 'role_change@example.com', password: 'password')
    assert admin.manager?

    admin.superuser!
    assert admin.superuser?
  end

  test 'role enum values' do
    assert_equal({ 'manager' => 0, 'superuser' => 1 }, AdminUser.roles)
  end
end
