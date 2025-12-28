# frozen_string_literal: true

require 'test_helper'

class Admin::ModelsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @superuser = admin_users(:superuser)
    @manager = admin_users(:manager)
    @model = models(:one)
    host! "admin.#{ApplicationConfig.host}"
  end

  # === AUTHENTICATION ===
  test 'unauthenticated user cannot access models index' do
    get admin_models_path
    assert_redirected_to admin_login_path
  end

  test 'unauthenticated user cannot access model show' do
    get admin_model_path(@model)
    assert_redirected_to admin_login_path
  end

  # === SUPERUSER AUTHORIZATION ===
  test 'manager cannot access models index' do
    sign_in_admin(@manager)
    get admin_models_path
    assert_redirected_to admin_root_path
    assert_equal I18n.t('admin.impersonations.access_denied'), flash[:alert]
  end

  test 'manager cannot access model show' do
    sign_in_admin(@manager)
    get admin_model_path(@model)
    assert_redirected_to admin_root_path
    assert_equal I18n.t('admin.impersonations.access_denied'), flash[:alert]
  end

  test 'superuser can access models index' do
    sign_in_admin(@superuser)
    get admin_models_path
    assert_response :success
  end

  test 'superuser can access model show' do
    sign_in_admin(@superuser)
    get admin_model_path(@model)
    assert_response :success
  end

  # === URL FILTERING (COLLECTION_FILTERS) ===
  test 'superuser can filter models by provider' do
    sign_in_admin(@superuser)
    get admin_models_path, params: { provider: 'openai' }
    assert_response :success
    assert_select 'tr[data-url]', count: 1
  end

  test 'superuser can filter models by family' do
    sign_in_admin(@superuser)
    get admin_models_path, params: { family: 'claude' }
    assert_response :success
    assert_select 'tr[data-url]', count: 1
  end

  test 'superuser can filter models by name with ILIKE' do
    sign_in_admin(@superuser)
    get admin_models_path, params: { name: 'gpt' }
    assert_response :success
    assert_select 'tr[data-url]', count: 1
  end

  test 'superuser can filter models by name case-insensitive' do
    sign_in_admin(@superuser)
    get admin_models_path, params: { name: 'CLAUDE' }
    assert_response :success
    assert_select 'tr[data-url]', count: 1
  end

  test 'multiple filters are applied together' do
    sign_in_admin(@superuser)
    get admin_models_path, params: { provider: 'openai', family: 'gpt' }
    assert_response :success
    assert_select 'tr[data-url]', count: 1
  end

  test 'empty filter value is ignored' do
    sign_in_admin(@superuser)
    get admin_models_path, params: { provider: '' }
    assert_response :success
    assert_select 'tr[data-url]', count: 3
  end

  test 'non-matching filter returns empty results' do
    sign_in_admin(@superuser)
    get admin_models_path, params: { provider: 'nonexistent' }
    assert_response :success
    assert_select 'tr[data-url]', count: 0
  end

  test 'unknown filter parameter is ignored' do
    sign_in_admin(@superuser)
    get admin_models_path, params: { unknown_filter: 'test' }
    assert_response :success
    assert_select 'tr[data-url]', count: 3
  end

  # === READ-ONLY ROUTES ===
  # Routes are defined with only: [:index, :show]
  # so new, create, edit, update, destroy return 404
  test 'new model route does not exist' do
    sign_in_admin(@superuser)
    get '/models/new'
    assert_response :not_found
  end

  test 'create model route does not exist' do
    sign_in_admin(@superuser)
    post '/models'
    assert_response :not_found
  end

  test 'edit model route does not exist' do
    sign_in_admin(@superuser)
    get "/models/#{@model.id}/edit"
    assert_response :not_found
  end

  test 'update model route does not exist' do
    sign_in_admin(@superuser)
    patch "/models/#{@model.id}"
    assert_response :not_found
  end

  test 'destroy model route does not exist' do
    sign_in_admin(@superuser)
    delete "/models/#{@model.id}"
    assert_response :not_found
  end

  private

  def sign_in_admin(admin_user)
    post admin_login_path, params: { email: admin_user.email, password: 'password' }
  end
end
