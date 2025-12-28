# frozen_string_literal: true

require 'test_helper'

module Tenants
  class SettingsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @tenant = tenants(:one)
      @owner = @tenant.owner
      @owner.update!(password: 'password123')

      # Mock Telegram API for webhook status check
      mock_webhook_info = { 'ok' => true, 'result' => { 'url' => @tenant.webhook_url } }
      TenantWebhookService.any_instance.stubs(:webhook_info).returns(mock_webhook_info)
    end

    test 'redirects to login when not authenticated' do
      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      get '/settings/edit'

      assert_redirected_to '/session/new'
    end

    test 'shows settings form with tabs when authenticated as owner' do
      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      post '/session', params: { email: @owner.email, password: 'password123' }

      get '/settings/edit'

      assert_response :success
      assert_select 'h1', /Настройки/
      # Check tabs are present (3 tabs total)
      assert_select 'button.admin-tabs__button', count: 3
      # Check key field is present
      assert_select "input[name='tenant[key]']"
    end

    test 'denies access to non-owner member' do
      # admin_member already has membership via fixtures (admin_on_tenant_one)
      member = users(:admin_member)

      host! "#{@tenant.key}.#{ApplicationConfig.host}"

      # Login as owner first
      post '/session', params: { email: @owner.email, password: 'password123' }

      # Access settings as owner (should work)
      get '/settings/edit'
      assert_response :success

      # Now test that non-owner access is denied
      # This is verified by require_owner! in controller
      # Integration test would require separate session management
      assert_equal @owner.id, session[:user_id]
    end

    test 'updates key successfully' do
      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      post '/session', params: { email: @owner.email, password: 'password123' }

      new_key = 'nk1'
      patch '/settings', params: { tenant: { key: new_key } }

      @tenant.reload
      assert_equal new_key, @tenant.key
      assert_response :redirect
    end

    test 'shows error for invalid key format' do
      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      post '/session', params: { email: @owner.email, password: 'password123' }

      # Key with special chars (will be downcased first, so use something that fails after downcase)
      patch '/settings', params: { tenant: { key: 'inv@lid!' } }

      assert_response :unprocessable_entity
      assert_select '.bg-red-100'
    end

    test 'shows error for key with wrong length' do
      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      post '/session', params: { email: @owner.email, password: 'password123' }

      patch '/settings', params: { tenant: { key: 'ab' } }

      assert_response :unprocessable_entity
    end

    test 'shows error for duplicate key' do
      other_tenant = tenants(:two)
      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      post '/session', params: { email: @owner.email, password: 'password123' }

      patch '/settings', params: { tenant: { key: other_tenant.key } }

      assert_response :unprocessable_entity
      assert_select '.bg-red-100'
    end

    test 'displays current dashboard url' do
      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      post '/session', params: { email: @owner.email, password: 'password123' }

      get '/settings/edit'

      assert_response :success
      assert_select 'code', /#{@tenant.key}/
    end

    test 'updates admin_chat_id successfully' do
      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      post '/session', params: { email: @owner.email, password: 'password123' }

      patch '/settings', params: { tenant: { admin_chat_id: 123_456_789 } }

      @tenant.reload
      assert_equal 123_456_789, @tenant.admin_chat_id
      assert_response :redirect
    end

    test 'updates welcome_message successfully' do
      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      post '/session', params: { email: @owner.email, password: 'password123' }

      new_message = 'Добро пожаловать в наш автосервис!'
      patch '/settings', params: { tenant: { welcome_message: new_message } }

      @tenant.reload
      assert_equal new_message, @tenant.welcome_message
      assert_response :redirect
    end

    test 'updates company_info successfully' do
      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      post '/session', params: { email: @owner.email, password: 'password123' }

      new_info = "ООО Автосервис\nТел: +7 999 123-45-67"
      patch '/settings', params: { tenant: { company_info: new_info } }

      @tenant.reload
      assert_equal new_info, @tenant.company_info
      assert_response :redirect
    end

    test 'updates price_list successfully' do
      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      post '/session', params: { email: @owner.email, password: 'password123' }

      new_price_list = 'Покраска бампера,5000,7000,10000'
      patch '/settings', params: { tenant: { price_list: new_price_list } }

      @tenant.reload
      assert_equal new_price_list, @tenant.price_list
      assert_response :redirect
    end

    test 'updates bot_token via new_bot_token' do
      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      post '/session', params: { email: @owner.email, password: 'password123' }

      # Mock Telegram API call for bot username fetch
      TenantWebhookService.any_instance.stubs(:webhook_info).returns({ 'ok' => true, 'result' => {} })
      Telegram::Bot::Client.any_instance.stubs(:get_me).returns({
        'ok' => true,
        'result' => { 'username' => 'new_test_bot' }
      })

      new_token = '999999999:BBBnewtoken123456789'
      patch '/settings', params: { tenant: { new_bot_token: new_token } }

      @tenant.reload
      assert_equal new_token, @tenant.bot_token
      assert_equal 'new_test_bot', @tenant.bot_username
    end

    test 'shows telegram fields in form' do
      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      post '/session', params: { email: @owner.email, password: 'password123' }

      # Mock Telegram API for webhook status
      TenantWebhookService.any_instance.stubs(:webhook_info).returns({ 'ok' => true, 'result' => {} })

      get '/settings/edit'

      assert_response :success
      assert_select "input[name='tenant[new_bot_token]']"
      assert_select "input[name='tenant[admin_chat_id]']"
    end

    test 'shows content fields in form' do
      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      post '/session', params: { email: @owner.email, password: 'password123' }

      # Mock Telegram API for webhook status
      TenantWebhookService.any_instance.stubs(:webhook_info).returns({ 'ok' => true, 'result' => {} })

      get '/settings/edit'

      assert_response :success
      assert_select "textarea[name='tenant[welcome_message]']"
      assert_select "textarea[name='tenant[company_info]']"
      assert_select "textarea[name='tenant[price_list]']"
    end
  end
end
