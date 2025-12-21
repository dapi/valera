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
      host! "#{@tenant.key}.lvh.me"
      get '/session/new'

      assert_response :success
      assert_select 'input[type=password]'
    end

    test 'redirects to set password when owner has no password' do
      @owner.update_column(:password_digest, nil)
      host! "#{@tenant.key}.lvh.me"

      post '/session', params: { password: 'anything' }

      assert_redirected_to '/password/new'
      assert_equal @owner.id, session[:pending_user_id]
    end

    test 'logs in with correct password' do
      host! "#{@tenant.key}.lvh.me"

      post '/session', params: { password: 'password123' }

      assert_redirected_to '/'
      assert_equal @owner.id, session[:user_id]
    end

    test 'rejects incorrect password' do
      host! "#{@tenant.key}.lvh.me"

      post '/session', params: { password: 'wrongpassword' }

      assert_response :unprocessable_entity
      assert_nil session[:user_id]
    end

    test 'logs out successfully' do
      host! "#{@tenant.key}.lvh.me"
      post '/session', params: { password: 'password123' }

      delete '/session'

      assert_redirected_to '/session/new'
      assert_nil session[:user_id]
    end

    test 'shows error when tenant has no owner' do
      @tenant.update!(owner: nil)
      host! "#{@tenant.key}.lvh.me"

      post '/session', params: { password: 'password123' }

      assert_response :unprocessable_entity
    end
  end
end
