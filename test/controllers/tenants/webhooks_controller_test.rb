# frozen_string_literal: true

require 'test_helper'

module Tenants
  class WebhooksControllerTest < ActionDispatch::IntegrationTest
    setup do
      @tenant = tenants(:one)
      @owner = @tenant.owner
      @owner.update!(password: 'password123')

      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      post '/session', params: { email: @owner.email, password: 'password123' }
    end

    test 'creates webhook successfully' do
      TenantWebhookService.any_instance.expects(:setup_webhook).returns({ 'ok' => true })

      post '/webhook'

      assert_redirected_to '/settings/edit#telegram'
      assert_equal I18n.t('tenants.webhooks.create.success'), flash[:notice]
    end

    test 'shows error when webhook creation fails' do
      TenantWebhookService.any_instance.expects(:setup_webhook)
        .raises(TenantWebhookService::TelegramApiError.new('API Error'))

      post '/webhook'

      assert_redirected_to '/settings/edit#telegram'
      assert_match(/API Error/, flash[:alert])
    end

    test 'destroys webhook successfully' do
      TenantWebhookService.any_instance.expects(:remove_webhook).returns({ 'ok' => true })

      delete '/webhook'

      assert_redirected_to '/settings/edit#telegram'
      assert_equal I18n.t('tenants.webhooks.destroy.success'), flash[:notice]
    end

    test 'shows error when webhook deletion fails' do
      TenantWebhookService.any_instance.expects(:remove_webhook)
        .raises(TenantWebhookService::TelegramApiError.new('Delete Error'))

      delete '/webhook'

      assert_redirected_to '/settings/edit#telegram'
      assert_match(/Delete Error/, flash[:alert])
    end

    test 'requires admin access' do
      # Logout
      delete '/session'

      post '/webhook'
      assert_redirected_to '/session/new'

      delete '/webhook'
      assert_redirected_to '/session/new'
    end
  end
end
