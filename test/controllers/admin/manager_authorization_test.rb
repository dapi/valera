# frozen_string_literal: true

require 'test_helper'

class Admin::ManagerAuthorizationTest < ActionDispatch::IntegrationTest
  setup do
    @superuser = admin_users(:superuser)
    @manager = admin_users(:manager)
    @tenant = tenants(:one)
    @user = users(:one)
    host! "admin.#{ApplicationConfig.host}"
  end

  # === UsersController ===
  test 'manager can view users index' do
    sign_in_admin(@manager)
    get admin_users_path
    assert_response :success
  end

  test 'manager can view user show' do
    sign_in_admin(@manager)
    get admin_user_path(@user)
    assert_response :success
  end

  test 'manager cannot access new user form' do
    sign_in_admin(@manager)
    get new_admin_user_path
    assert_redirected_to admin_root_path
    assert_equal I18n.t('admin.impersonations.access_denied'), flash[:alert]
  end

  test 'manager cannot create user' do
    sign_in_admin(@manager)
    assert_no_difference('User.count') do
      post admin_users_path, params: {
        user: { email: 'new@example.com', name: 'New User' }
      }
    end
    assert_redirected_to admin_root_path
  end

  test 'manager cannot edit user' do
    sign_in_admin(@manager)
    get edit_admin_user_path(@user)
    assert_redirected_to admin_root_path
  end

  test 'manager cannot update user' do
    sign_in_admin(@manager)
    original_name = @user.name
    patch admin_user_path(@user), params: {
      user: { name: 'Hacked Name' }
    }
    assert_redirected_to admin_root_path
    assert_equal original_name, @user.reload.name
  end

  test 'manager cannot destroy user' do
    sign_in_admin(@manager)
    assert_no_difference('User.count') do
      delete admin_user_path(@user)
    end
    assert_redirected_to admin_root_path
  end

  test 'superuser can create user' do
    sign_in_admin(@superuser)
    assert_difference('User.count') do
      post admin_users_path, params: {
        user: { email: 'new_user@example.com', name: 'New User' }
      }
    end
  end

  # === TenantMembershipsController ===
  test 'manager can view tenant memberships index' do
    sign_in_admin(@manager)
    get admin_tenant_memberships_path
    assert_response :success
  end

  test 'manager cannot access new tenant membership form' do
    sign_in_admin(@manager)
    get new_admin_tenant_membership_path
    assert_redirected_to admin_root_path
    assert_equal I18n.t('admin.impersonations.access_denied'), flash[:alert]
  end

  test 'manager cannot create tenant membership' do
    sign_in_admin(@manager)
    assert_no_difference('TenantMembership.count') do
      post admin_tenant_memberships_path, params: {
        tenant_membership: { tenant_id: @tenant.id, user_id: @user.id, role: 'viewer' }
      }
    end
    assert_redirected_to admin_root_path
  end

  test 'superuser can create tenant membership' do
    sign_in_admin(@superuser)
    new_user = User.create!(email: 'membership_test@example.com', name: 'Test')
    assert_difference('TenantMembership.count') do
      post admin_tenant_memberships_path, params: {
        tenant_membership: { tenant_id: @tenant.id, user_id: new_user.id, role: 'viewer' }
      }
    end
  end

  private

  def sign_in_admin(admin_user)
    post admin_login_path, params: { email: admin_user.email, password: 'password' }
  end
end
