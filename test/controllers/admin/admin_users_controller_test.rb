# frozen_string_literal: true

require 'test_helper'

class Admin::AdminUsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @superuser = admin_users(:superuser)
    @manager = admin_users(:manager)
    host! 'admin.lvh.me'
  end

  test 'superuser can access admin users index' do
    sign_in_admin(@superuser)
    get admin_admin_users_path
    assert_response :success
  end

  test 'manager cannot access admin users index' do
    sign_in_admin(@manager)
    get admin_admin_users_path
    assert_redirected_to admin_root_path
    assert_equal 'Access denied. Superuser privileges required.', flash[:alert]
  end

  test 'superuser can view admin user' do
    sign_in_admin(@superuser)
    get admin_admin_user_path(@manager)
    assert_response :success
  end

  test 'manager cannot view admin user' do
    sign_in_admin(@manager)
    get admin_admin_user_path(@superuser)
    assert_redirected_to admin_root_path
  end

  test 'superuser can access new admin user form' do
    sign_in_admin(@superuser)
    get new_admin_admin_user_path
    assert_response :success
  end

  test 'manager cannot access new admin user form' do
    sign_in_admin(@manager)
    get new_admin_admin_user_path
    assert_redirected_to admin_root_path
  end

  test 'superuser can create admin user' do
    sign_in_admin(@superuser)
    assert_difference('AdminUser.count') do
      post admin_admin_users_path, params: {
        admin_user: {
          email: 'new_admin@example.com',
          password: 'password123',
          role: 'manager'
        }
      }
    end
    assert_redirected_to admin_admin_user_path(AdminUser.last)
  end

  test 'manager cannot create admin user' do
    sign_in_admin(@manager)
    assert_no_difference('AdminUser.count') do
      post admin_admin_users_path, params: {
        admin_user: {
          email: 'new_admin@example.com',
          password: 'password123',
          role: 'manager'
        }
      }
    end
    assert_redirected_to admin_root_path
  end

  test 'unauthenticated user cannot access admin users' do
    get admin_admin_users_path
    assert_redirected_to admin_login_path
  end

  private

  def sign_in_admin(admin_user)
    post admin_login_path, params: { email: admin_user.email, password: 'password' }
  end
end
