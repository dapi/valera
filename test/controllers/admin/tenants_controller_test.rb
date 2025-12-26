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

  # === TEST TELEGRAM ===
  test 'test_telegram shows bot info and webhook status' do
    sign_in_admin(@superuser)

    bot_info = { 'username' => 'test_bot', 'id' => 123 }
    webhook_info = { 'url' => 'https://example.com/webhook' }

    mock_client = mock('Telegram::Bot::Client')
    mock_client.expects(:get_me).returns(bot_info)
    mock_client.expects(:get_webhook_info).returns(webhook_info)

    Telegram::Bot::Client.stubs(:new).returns(mock_client)

    post test_telegram_admin_tenant_path(@tenant_one)

    assert_redirected_to admin_tenant_path(@tenant_one)
    assert_match 'test_bot', flash[:notice]
    assert_match 'https://example.com/webhook', flash[:notice]
  end

  test 'test_telegram shows not set when webhook is empty' do
    sign_in_admin(@superuser)

    bot_info = { 'username' => 'test_bot', 'id' => 123 }
    webhook_info = { 'url' => '' }

    mock_client = mock('Telegram::Bot::Client')
    mock_client.expects(:get_me).returns(bot_info)
    mock_client.expects(:get_webhook_info).returns(webhook_info)

    Telegram::Bot::Client.stubs(:new).returns(mock_client)

    post test_telegram_admin_tenant_path(@tenant_one)

    assert_redirected_to admin_tenant_path(@tenant_one)
    assert_match 'test_bot', flash[:notice]
  end

  test 'test_telegram handles API errors' do
    sign_in_admin(@superuser)

    mock_client = mock('Telegram::Bot::Client')
    mock_client.expects(:get_me).raises(Telegram::Bot::Error.new('Invalid token'))

    Telegram::Bot::Client.stubs(:new).returns(mock_client)

    post test_telegram_admin_tenant_path(@tenant_one)

    assert_redirected_to admin_tenant_path(@tenant_one)
    assert_match 'Invalid token', flash[:alert]
  end

  # === SETUP WEBHOOK ===
  test 'setup_webhook installs webhook successfully' do
    sign_in_admin(@superuser)

    mock_client = mock('Telegram::Bot::Client')
    mock_client.expects(:set_webhook).returns({ 'ok' => true })

    Telegram::Bot::Client.stubs(:new).returns(mock_client)

    post setup_webhook_admin_tenant_path(@tenant_one)

    assert_redirected_to admin_tenant_path(@tenant_one)
    assert_equal I18n.t('admin.tenants.setup_webhook.success'), flash[:notice]
  end

  test 'setup_webhook handles API errors' do
    sign_in_admin(@superuser)

    mock_client = mock('Telegram::Bot::Client')
    mock_client.expects(:set_webhook).raises(Telegram::Bot::Error.new('API error'))

    Telegram::Bot::Client.stubs(:new).returns(mock_client)

    post setup_webhook_admin_tenant_path(@tenant_one)

    assert_redirected_to admin_tenant_path(@tenant_one)
    assert_match 'API error', flash[:alert]
  end

  # === REMOVE WEBHOOK ===
  test 'remove_webhook removes webhook successfully' do
    sign_in_admin(@superuser)

    mock_client = mock('Telegram::Bot::Client')
    mock_client.expects(:delete_webhook).returns({ 'ok' => true })

    Telegram::Bot::Client.stubs(:new).returns(mock_client)

    delete remove_webhook_admin_tenant_path(@tenant_one)

    assert_redirected_to admin_tenant_path(@tenant_one)
    assert_equal I18n.t('admin.tenants.remove_webhook.success'), flash[:notice]
  end

  test 'remove_webhook handles API errors' do
    sign_in_admin(@superuser)

    mock_client = mock('Telegram::Bot::Client')
    mock_client.expects(:delete_webhook).raises(Telegram::Bot::Error.new('API error'))

    Telegram::Bot::Client.stubs(:new).returns(mock_client)

    delete remove_webhook_admin_tenant_path(@tenant_one)

    assert_redirected_to admin_tenant_path(@tenant_one)
    assert_match 'API error', flash[:alert]
  end

  # === AUTHENTICATION ===
  test 'unauthenticated user cannot access telegram actions' do
    post test_telegram_admin_tenant_path(@tenant_one)
    assert_redirected_to admin_login_path

    post setup_webhook_admin_tenant_path(@tenant_one)
    assert_redirected_to admin_login_path

    delete remove_webhook_admin_tenant_path(@tenant_one)
    assert_redirected_to admin_login_path
  end

  private

  def sign_in_admin(admin_user)
    post admin_login_path, params: { email: admin_user.email, password: 'password' }
  end
end
