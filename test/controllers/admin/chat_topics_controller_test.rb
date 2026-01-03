# frozen_string_literal: true

require 'test_helper'

class Admin::ChatTopicsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @superuser = admin_users(:superuser)
    host! "admin.#{ApplicationConfig.host}"
  end

  # === SINGLE-ARGUMENT FILTERS ===
  # These tests verify that filters with arity=1 work correctly
  # (filters that don't require a value, just presence of param)
  test 'single-arg filter active works' do
    sign_in_admin(@superuser)
    get admin_chat_topics_path, params: { active: 'true' }
    assert_response :success
  end

  test 'single-arg filter inactive works' do
    sign_in_admin(@superuser)
    get admin_chat_topics_path, params: { inactive: '1' }
    assert_response :success
  end

  test 'single-arg filter global works' do
    sign_in_admin(@superuser)
    get admin_chat_topics_path, params: { global: 'yes' }
    assert_response :success
  end

  private

  def sign_in_admin(admin_user)
    post admin_login_path, params: { email: admin_user.email, password: 'password' }
  end
end
