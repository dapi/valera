# frozen_string_literal: true

require 'test_helper'

module Tenants
  class SessionsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @tenant = tenants(:one)
      @owner = @tenant.owner
      @owner.update!(password: 'password123')
    end

    test 'shows login page' do
      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      get '/session/new'

      assert_response :success
      assert_select 'input[type=password]'
    end

    test 'redirects to set password when user has no password' do
      @owner.update_column(:password_digest, nil)
      host! "#{@tenant.key}.#{ApplicationConfig.host}"

      post '/session', params: { email: @owner.email, password: 'anything' }

      assert_redirected_to '/password/new'
      assert_equal @owner.id, session[:pending_user_id]
    end

    test 'logs in with correct email and password' do
      host! "#{@tenant.key}.#{ApplicationConfig.host}"

      post '/session', params: { email: @owner.email, password: 'password123' }

      assert_redirected_to '/'
      assert_equal @owner.id, session[:user_id]
    end

    test 'rejects incorrect password' do
      host! "#{@tenant.key}.#{ApplicationConfig.host}"

      post '/session', params: { email: @owner.email, password: 'wrongpassword' }

      assert_response :unprocessable_entity
      assert_nil session[:user_id]
    end

    test 'rejects unknown email' do
      host! "#{@tenant.key}.#{ApplicationConfig.host}"

      post '/session', params: { email: 'unknown@example.com', password: 'password123' }

      assert_response :unprocessable_entity
      assert_nil session[:user_id]
    end

    test 'rejects user without tenant access' do
      other_user = users(:two)
      other_user.update!(password: 'password123')
      host! "#{@tenant.key}.#{ApplicationConfig.host}"

      post '/session', params: { email: other_user.email, password: 'password123' }

      assert_response :unprocessable_entity
      assert_nil session[:user_id]
    end

    test 'logs out successfully' do
      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      post '/session', params: { email: @owner.email, password: 'password123' }

      delete '/session'

      assert_redirected_to '/session/new'
      assert_nil session[:user_id]
    end

    test 'allows tenant member to login' do
      member = users(:two)
      member.update!(password: 'memberpass')
      @tenant.tenant_memberships.create!(user: member, role: :viewer)
      host! "#{@tenant.key}.#{ApplicationConfig.host}"

      post '/session', params: { email: member.email, password: 'memberpass' }

      assert_redirected_to '/'
      assert_equal member.id, session[:user_id]
    end
  end
end
