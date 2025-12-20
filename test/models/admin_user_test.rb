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
end
