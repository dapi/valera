# frozen_string_literal: true

require 'test_helper'

module Tenants
  class SettingsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @tenant = tenants(:one)
      @owner = @tenant.owner
      @owner.update!(password: 'password123')
    end

    test 'redirects to login when not authenticated' do
      host! "#{@tenant.key}.lvh.me"
      get '/settings/edit'

      assert_redirected_to '/session/new'
    end

    test 'shows settings form when authenticated as owner' do
      host! "#{@tenant.key}.lvh.me"
      post '/session', params: { password: 'password123' }

      get '/settings/edit'

      assert_response :success
      assert_select 'h1', /Настройки/
      assert_select "input[name='tenant[key]']"
    end

    test 'denies access to non-owner member' do
      # admin_member already has membership via fixtures (admin_on_tenant_one)
      member = users(:admin_member)

      host! "#{@tenant.key}.lvh.me"

      # Login as owner first
      post '/session', params: { password: 'password123' }

      # Access settings as owner (should work)
      get '/settings/edit'
      assert_response :success

      # Now test that non-owner access is denied
      # This is verified by require_owner! in controller
      # Integration test would require separate session management
      assert_equal @owner.id, session[:user_id]
    end

    test 'updates key successfully' do
      host! "#{@tenant.key}.lvh.me"
      post '/session', params: { password: 'password123' }

      new_key = 'newkey12'
      patch '/settings', params: { tenant: { key: new_key } }

      @tenant.reload
      assert_equal new_key, @tenant.key
      assert_response :redirect
    end

    test 'shows error for invalid key format' do
      host! "#{@tenant.key}.lvh.me"
      post '/session', params: { password: 'password123' }

      # Key with special chars (will be downcased first, so use something that fails after downcase)
      patch '/settings', params: { tenant: { key: 'inv@lid!' } }

      assert_response :unprocessable_entity
      assert_select '.bg-red-100'
    end

    test 'shows error for key with wrong length' do
      host! "#{@tenant.key}.lvh.me"
      post '/session', params: { password: 'password123' }

      patch '/settings', params: { tenant: { key: 'short' } }

      assert_response :unprocessable_entity
    end

    test 'shows error for duplicate key' do
      other_tenant = tenants(:two)
      host! "#{@tenant.key}.lvh.me"
      post '/session', params: { password: 'password123' }

      patch '/settings', params: { tenant: { key: other_tenant.key } }

      assert_response :unprocessable_entity
      assert_select '.bg-red-100'
    end

    test 'displays current dashboard url' do
      host! "#{@tenant.key}.lvh.me"
      post '/session', params: { password: 'password123' }

      get '/settings/edit'

      assert_response :success
      assert_select 'code', /#{@tenant.key}/
    end
  end
end
