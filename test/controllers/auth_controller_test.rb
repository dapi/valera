# frozen_string_literal: true

require 'test_helper'

class AuthControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @user.update!(password: 'password123')
    @tenant = tenants(:one)
  end

  # GET /login
  test 'shows login page' do
    get login_path

    assert_response :success
    assert_select 'input[type=email]'
    assert_select 'input[type=password]'
  end

  test 'redirects to select tenant if already logged in' do
    login_as(@user)

    get login_path

    assert_redirected_to select_tenant_path
  end

  # POST /login
  test 'logs in with correct credentials' do
    post login_path, params: { email: @user.email, password: 'password123' }

    assert_equal @user.id, session[:user_id]
  end

  test 'rejects incorrect password' do
    post login_path, params: { email: @user.email, password: 'wrongpassword' }

    assert_response :unprocessable_entity
    assert_nil session[:user_id]
  end

  test 'rejects unknown email' do
    post login_path, params: { email: 'unknown@example.com', password: 'password123' }

    assert_response :unprocessable_entity
    assert_nil session[:user_id]
  end

  test 'redirects to tenant on login when user has one tenant' do
    # Remove extra tenants so user has only one
    @user.owned_tenants.where.not(id: @tenant.id).update_all(owner_id: nil)
    assert_equal 1, @user.owned_tenants.reload.count

    post login_path, params: { email: @user.email, password: 'password123' }

    assert_response :redirect
    assert_match(/#{@tenant.key}/, response.location)
  end

  test 'redirects to select page when user has multiple tenants' do
    # User already has multiple tenants from fixtures (one and unconfigured)
    assert @user.owned_tenants.count >= 2, 'User should have multiple tenants from fixtures'

    post login_path, params: { email: @user.email, password: 'password123' }

    assert_redirected_to select_tenant_path
  end

  test 'shows error when user has no tenants' do
    # Remove all tenant ownerships for this user
    @user.owned_tenants.update_all(owner_id: nil)
    assert_equal 0, @user.owned_tenants.reload.count

    post login_path, params: { email: @user.email, password: 'password123' }

    assert_redirected_to login_path
    assert_equal I18n.t('auth.redirect_after_login.no_tenants'), flash[:alert]
  end

  # DELETE /logout
  test 'logs out successfully' do
    login_as(@user)

    delete logout_path

    assert_nil session[:user_id]
    assert_redirected_to root_path
  end

  # GET /login/select
  test 'shows tenant selection page' do
    login_as(@user)

    get select_tenant_path

    assert_response :success
    assert_select '.font-semibold', text: @tenant.name
  end

  test 'redirects to login if not logged in' do
    get select_tenant_path

    assert_redirected_to login_path
  end

  # POST /login/select
  test 'switches to tenant' do
    login_as(@user)

    post select_tenant_path, params: { tenant_key: @tenant.key }

    assert_response :redirect
    assert_match(/#{@tenant.key}/, response.location)
    assert_match(/auth\/token/, response.location)
  end

  test 'rejects invalid tenant key' do
    login_as(@user)

    post select_tenant_path, params: { tenant_key: 'invalid' }

    assert_redirected_to select_tenant_path
  end

  private

  def login_as(user)
    post login_path, params: { email: user.email, password: 'password123' }
    # Clear redirect for subsequent requests
    get select_tenant_path if response.redirect?
  end
end
