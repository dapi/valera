# frozen_string_literal: true

require 'test_helper'

class Admin::TenantsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @superuser = admin_users(:superuser)
    @manager = admin_users(:manager)
    @tenant_one = tenants(:one)
    @tenant_two = tenants(:two)
    host! "admin.#{ApplicationConfig.host}"
  end

  test 'index shows all tenants without filter' do
    sign_in_admin(@superuser)
    get admin_tenants_path
    assert_response :success
    assert_select 'table tbody tr', minimum: 2
  end

  test 'index filters tenants by manager_id' do
    # Assign tenant_one to manager
    @tenant_one.update!(manager: @manager)
    @tenant_two.update!(manager: nil)

    sign_in_admin(@superuser)
    get admin_tenants_path(manager_id: @manager.id)
    assert_response :success

    # Should only show tenant_one
    assert_match @tenant_one.name, response.body
    assert_no_match @tenant_two.name, response.body
  end

  test 'index shows empty list when manager has no tenants' do
    sign_in_admin(@superuser)
    get admin_tenants_path(manager_id: @superuser.id)
    assert_response :success
  end

  private

  def sign_in_admin(admin_user)
    post admin_login_path, params: { email: admin_user.email, password: 'password' }
  end
end
