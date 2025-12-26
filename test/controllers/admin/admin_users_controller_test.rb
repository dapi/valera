# frozen_string_literal: true

require 'test_helper'

class Admin::AdminUsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @superuser = admin_users(:superuser)
    @manager = admin_users(:manager)
    host! "admin.#{ApplicationConfig.host}"
  end

  # === INDEX ===
  test 'superuser can access admin users index' do
    sign_in_admin(@superuser)
    get admin_admin_users_path
    assert_response :success
  end

  test 'manager can access admin users index' do
    sign_in_admin(@manager)
    get admin_admin_users_path
    assert_response :success
  end

  # === SHOW ===
  test 'superuser can view any admin user' do
    sign_in_admin(@superuser)
    get admin_admin_user_path(@manager)
    assert_response :success
  end

  test 'manager can view any admin user' do
    sign_in_admin(@manager)
    get admin_admin_user_path(@superuser)
    assert_response :success
  end

  # === NEW/CREATE ===
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

  # === EDIT/UPDATE ===
  test 'superuser can edit any admin user' do
    sign_in_admin(@superuser)
    get edit_admin_admin_user_path(@manager)
    assert_response :success
  end

  test 'manager can edit own profile' do
    sign_in_admin(@manager)
    get edit_admin_admin_user_path(@manager)
    assert_response :success
  end

  test 'manager cannot edit other admin user' do
    sign_in_admin(@manager)
    get edit_admin_admin_user_path(@superuser)
    assert_redirected_to admin_root_path
    assert_equal I18n.t('admin.admin_users.edit_own_profile_only'), flash[:alert]
  end

  test 'superuser can update any admin user' do
    sign_in_admin(@superuser)
    patch admin_admin_user_path(@manager), params: {
      admin_user: { name: 'Updated Name' }
    }
    assert_redirected_to admin_admin_user_path(@manager)
    assert_equal 'Updated Name', @manager.reload.name
  end

  test 'manager can update own profile' do
    sign_in_admin(@manager)
    patch admin_admin_user_path(@manager), params: {
      admin_user: { name: 'My New Name' }
    }
    assert_redirected_to admin_admin_user_path(@manager)
    assert_equal 'My New Name', @manager.reload.name
  end

  test 'manager cannot update other admin user' do
    sign_in_admin(@manager)
    original_name = @superuser.name
    patch admin_admin_user_path(@superuser), params: {
      admin_user: { name: 'Hacked Name' }
    }
    assert_redirected_to admin_root_path
    assert_equal original_name, @superuser.reload.name
  end

  test 'manager cannot change own role' do
    sign_in_admin(@manager)
    patch admin_admin_user_path(@manager), params: {
      admin_user: { role: 'superuser' }
    }
    assert_equal 'manager', @manager.reload.role
  end

  test 'superuser can change role' do
    sign_in_admin(@superuser)
    patch admin_admin_user_path(@manager), params: {
      admin_user: { role: 'superuser' }
    }
    assert_equal 'superuser', @manager.reload.role
  end

  # === DESTROY ===
  test 'superuser can destroy admin user' do
    sign_in_admin(@superuser)
    other_manager = AdminUser.create!(email: 'other@example.com', password: 'password', role: :manager)
    assert_difference('AdminUser.count', -1) do
      delete admin_admin_user_path(other_manager)
    end
  end

  test 'manager cannot destroy admin user' do
    sign_in_admin(@manager)
    assert_no_difference('AdminUser.count') do
      delete admin_admin_user_path(@superuser)
    end
    assert_redirected_to admin_root_path
  end

  # === AUTHENTICATION ===
  test 'unauthenticated user cannot access admin users' do
    get admin_admin_users_path
    assert_redirected_to admin_login_path
  end

  private

  def sign_in_admin(admin_user)
    post admin_login_path, params: { email: admin_user.email, password: 'password' }
  end
end
