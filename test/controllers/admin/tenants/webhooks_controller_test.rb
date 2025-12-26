# frozen_string_literal: true

require 'test_helper'

class Admin::Tenants::WebhooksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @superuser = admin_users(:superuser)
    @tenant = tenants(:one)
    host! "admin.#{ApplicationConfig.host}"
  end

  # === SHOW (Test Telegram) ===
  test 'show displays bot info and webhook status when webhook matches expected' do
    sign_in_admin(@superuser)

    expected_url = @tenant.webhook_url
    bot_info = { 'ok' => true, 'result' => { 'username' => 'test_bot', 'id' => 123 } }
    webhook_info = { 'url' => expected_url }

    mock_client = mock('Telegram::Bot::Client')
    mock_client.expects(:get_me).returns(bot_info)
    mock_client.expects(:get_webhook_info).returns(webhook_info)

    Telegram::Bot::Client.stubs(:new).returns(mock_client)

    get admin_tenant_webhook_path(@tenant)

    assert_redirected_to admin_tenant_path(@tenant)
    assert_match 'test_bot', flash[:notice]
    assert_match expected_url, flash[:notice]
  end

  test 'show displays warning when webhook URL mismatches' do
    sign_in_admin(@superuser)

    bot_info = { 'ok' => true, 'result' => { 'username' => 'test_bot', 'id' => 123 } }
    webhook_info = { 'url' => 'https://wrong.example.com/webhook' }

    mock_client = mock('Telegram::Bot::Client')
    mock_client.expects(:get_me).returns(bot_info)
    mock_client.expects(:get_webhook_info).returns(webhook_info)

    Telegram::Bot::Client.stubs(:new).returns(mock_client)

    get admin_tenant_webhook_path(@tenant)

    assert_redirected_to admin_tenant_path(@tenant)
    assert_match 'test_bot', flash[:notice]
    assert_match 'wrong.example.com', flash[:notice]
  end

  test 'show displays not set when webhook is empty' do
    sign_in_admin(@superuser)

    bot_info = { 'ok' => true, 'result' => { 'username' => 'test_bot', 'id' => 123 } }
    webhook_info = { 'url' => '' }

    mock_client = mock('Telegram::Bot::Client')
    mock_client.expects(:get_me).returns(bot_info)
    mock_client.expects(:get_webhook_info).returns(webhook_info)

    Telegram::Bot::Client.stubs(:new).returns(mock_client)

    get admin_tenant_webhook_path(@tenant)

    assert_redirected_to admin_tenant_path(@tenant)
    assert_match 'test_bot', flash[:notice]
  end

  test 'show handles API errors' do
    sign_in_admin(@superuser)

    mock_client = mock('Telegram::Bot::Client')
    mock_client.expects(:get_me).raises(Telegram::Bot::Error.new('Invalid token'))

    Telegram::Bot::Client.stubs(:new).returns(mock_client)

    get admin_tenant_webhook_path(@tenant)

    assert_redirected_to admin_tenant_path(@tenant)
    assert_match 'Invalid token', flash[:alert]
  end

  # === CREATE (Setup Webhook) ===
  test 'create installs webhook successfully' do
    sign_in_admin(@superuser)

    mock_client = mock('Telegram::Bot::Client')
    mock_client.expects(:set_webhook).returns({ 'ok' => true })

    Telegram::Bot::Client.stubs(:new).returns(mock_client)

    post admin_tenant_webhook_path(@tenant)

    assert_redirected_to admin_tenant_path(@tenant)
    assert_equal I18n.t('admin.tenants.webhooks.create.success'), flash[:notice]
  end

  test 'create handles API errors' do
    sign_in_admin(@superuser)

    mock_client = mock('Telegram::Bot::Client')
    mock_client.expects(:set_webhook).raises(Telegram::Bot::Error.new('API error'))

    Telegram::Bot::Client.stubs(:new).returns(mock_client)

    post admin_tenant_webhook_path(@tenant)

    assert_redirected_to admin_tenant_path(@tenant)
    assert_match 'API error', flash[:alert]
  end

  # === DESTROY (Remove Webhook) ===
  test 'destroy removes webhook successfully' do
    sign_in_admin(@superuser)

    mock_client = mock('Telegram::Bot::Client')
    mock_client.expects(:delete_webhook).returns({ 'ok' => true })

    Telegram::Bot::Client.stubs(:new).returns(mock_client)

    delete admin_tenant_webhook_path(@tenant)

    assert_redirected_to admin_tenant_path(@tenant)
    assert_equal I18n.t('admin.tenants.webhooks.destroy.success'), flash[:notice]
  end

  test 'destroy handles API errors' do
    sign_in_admin(@superuser)

    mock_client = mock('Telegram::Bot::Client')
    mock_client.expects(:delete_webhook).raises(Telegram::Bot::Error.new('API error'))

    Telegram::Bot::Client.stubs(:new).returns(mock_client)

    delete admin_tenant_webhook_path(@tenant)

    assert_redirected_to admin_tenant_path(@tenant)
    assert_match 'API error', flash[:alert]
  end

  # === AUTHENTICATION ===
  test 'unauthenticated user cannot access webhook actions' do
    get admin_tenant_webhook_path(@tenant)
    assert_redirected_to admin_login_path

    post admin_tenant_webhook_path(@tenant)
    assert_redirected_to admin_login_path

    delete admin_tenant_webhook_path(@tenant)
    assert_redirected_to admin_login_path
  end

  private

  def sign_in_admin(admin_user)
    post admin_login_path, params: { email: admin_user.email, password: 'password' }
  end
end
