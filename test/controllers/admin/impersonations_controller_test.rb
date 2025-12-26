# frozen_string_literal: true

require 'test_helper'

class Admin::ImpersonationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @superuser = admin_users(:superuser)
    @manager = admin_users(:manager)
    host! "admin.#{ApplicationConfig.host}"
  end

  # === Create (start impersonation) ===

  test 'superuser can impersonate another admin user' do
    sign_in_admin(@superuser)

    post impersonate_admin_admin_user_path(@manager)

    assert_redirected_to admin_root_path
    assert_equal I18n.t('admin.impersonations.started', name: @manager.email), flash[:notice]

    # Verify session state
    follow_redirect!
    assert_equal @manager.id, session[:admin_user_id]
    assert_equal @superuser.id, session[:original_admin_user_id]
  end

  test 'superuser cannot impersonate themselves' do
    sign_in_admin(@superuser)

    post impersonate_admin_admin_user_path(@superuser)

    assert_redirected_to admin_admin_users_path
    assert_equal I18n.t('admin.impersonations.cannot_impersonate_self'), flash[:alert]
  end

  test 'manager cannot impersonate anyone' do
    sign_in_admin(@manager)

    post impersonate_admin_admin_user_path(@superuser)

    assert_redirected_to admin_root_path
    assert_equal I18n.t('admin.impersonations.access_denied'), flash[:alert]
  end

  test 'unauthenticated user cannot impersonate' do
    post impersonate_admin_admin_user_path(@manager)

    assert_redirected_to admin_login_path
  end

  # === Destroy (stop impersonation) ===

  test 'superuser can stop impersonating' do
    sign_in_admin(@superuser)
    post impersonate_admin_admin_user_path(@manager)

    delete admin_stop_impersonating_path

    assert_redirected_to admin_root_path
    assert_equal I18n.t('admin.impersonations.stopped'), flash[:notice]

    # Verify session state
    follow_redirect!
    assert_equal @superuser.id, session[:admin_user_id]
    assert_nil session[:original_admin_user_id]
  end

  test 'cannot stop impersonating when not impersonating' do
    sign_in_admin(@superuser)

    delete admin_stop_impersonating_path

    assert_redirected_to admin_root_path
    assert_equal I18n.t('admin.impersonations.not_impersonating'), flash[:alert]
  end

  test 'impersonation is logged' do
    sign_in_admin(@superuser)

    # Test start impersonation logging
    assert_output_includes_log "[IMPERSONATION] Superuser #{@superuser.email}" do
      post impersonate_admin_admin_user_path(@manager)
    end

    # Test stop impersonation logging
    assert_output_includes_log "[IMPERSONATION] Superuser #{@superuser.email}" do
      delete admin_stop_impersonating_path
    end
  end

  # === Helper methods ===

  test 'impersonating? returns true when impersonating' do
    sign_in_admin(@superuser)
    post impersonate_admin_admin_user_path(@manager)
    follow_redirect!

    # Access a page and verify impersonating? is available
    get admin_root_path
    assert_response :success
    assert session[:original_admin_user_id].present?
  end

  test 'impersonating? returns false when not impersonating' do
    sign_in_admin(@superuser)
    get admin_root_path
    assert_response :success
    assert_nil session[:original_admin_user_id]
  end

  private

  def sign_in_admin(admin_user)
    post admin_login_path, params: { email: admin_user.email, password: 'password' }
  end

  def assert_output_includes_log(expected_message)
    original_logger = Rails.logger
    string_io = StringIO.new
    Rails.logger = Logger.new(string_io)
    Rails.logger.level = Logger::INFO

    yield

    string_io.rewind
    log_output = string_io.read
    assert_includes log_output, expected_message

    Rails.logger = original_logger
  end
end
