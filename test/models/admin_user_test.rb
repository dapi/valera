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

  # Counter cache tests
  test 'managed_tenants_count starts at zero' do
    admin = AdminUser.create!(email: 'counter@example.com', password: 'password')
    assert_equal 0, admin.managed_tenants_count
  end

  test 'managed_tenants_count increments when tenant is assigned' do
    stub_telegram_get_me
    admin = AdminUser.create!(email: 'counter2@example.com', password: 'password')

    assert_difference -> { admin.reload.managed_tenants_count }, 1 do
      Tenant.create!(
        name: 'Counter Test Tenant',
        bot_token: '123456800:CounterTestToken',
        manager: admin
      )
    end
  end

  test 'managed_tenants_count decrements when tenant manager is removed' do
    stub_telegram_get_me
    admin = AdminUser.create!(email: 'counter3@example.com', password: 'password')
    tenant = Tenant.create!(
      name: 'Counter Test Tenant 2',
      bot_token: '123456801:CounterTestToken2',
      manager: admin
    )

    assert_difference -> { admin.reload.managed_tenants_count }, -1 do
      tenant.update!(manager: nil)
    end
  end

  test 'managed_tenants_count updates when tenant changes manager' do
    stub_telegram_get_me
    admin1 = AdminUser.create!(email: 'counter4@example.com', password: 'password')
    admin2 = AdminUser.create!(email: 'counter5@example.com', password: 'password')
    tenant = Tenant.create!(
      name: 'Counter Test Tenant 3',
      bot_token: '123456802:CounterTestToken3',
      manager: admin1
    )

    assert_equal 1, admin1.reload.managed_tenants_count
    assert_equal 0, admin2.reload.managed_tenants_count

    tenant.update!(manager: admin2)

    assert_equal 0, admin1.reload.managed_tenants_count
    assert_equal 1, admin2.reload.managed_tenants_count
  end

  private

  def stub_telegram_get_me(username: 'stubbed_bot')
    response = { 'ok' => true, 'result' => { 'username' => username, 'id' => 123_456_789, 'first_name' => 'Test Bot' } }
    Telegram::Bot::Client.any_instance.stubs(:get_me).returns(response)
  end
end
