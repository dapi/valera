# frozen_string_literal: true

require 'test_helper'

module Tenants
  class TokenAuthControllerTest < ActionDispatch::IntegrationTest
    setup do
      @tenant = tenants(:one)
      @user = @tenant.owner
      host! "#{@tenant.key}.lvh.me"
    end

    test 'logs in with valid token' do
      token = generate_cross_domain_token(@user, @tenant)

      get "/auth/token?t=#{CGI.escape(token)}"

      assert_redirected_to '/'
      assert_equal @user.id, session[:user_id]
    end

    test 'rejects invalid token' do
      get '/auth/token?t=invalid_token'

      assert_redirected_to '/session/new'
      assert_nil session[:user_id]
    end

    test 'rejects expired token' do
      # Create a token that expires immediately
      token = Rails.application.message_verifier(:cross_auth).generate(
        { user_id: @user.id, tenant_key: @tenant.key, exp: 1.second.ago.to_i },
        expires_in: 0.seconds
      )

      # Wait for expiration
      sleep 0.1

      get "/auth/token?t=#{CGI.escape(token)}"

      assert_redirected_to '/session/new'
      assert_nil session[:user_id]
    end

    test 'rejects token for wrong tenant' do
      other_tenant = tenants(:two)
      token = generate_cross_domain_token(@user, other_tenant)

      get "/auth/token?t=#{CGI.escape(token)}"

      assert_redirected_to '/session/new'
      assert_nil session[:user_id]
    end

    test 'rejects missing token' do
      get '/auth/token'

      assert_redirected_to '/session/new'
      assert_nil session[:user_id]
    end

    private

    def generate_cross_domain_token(user, tenant)
      Rails.application.message_verifier(:cross_auth).generate(
        { user_id: user.id, tenant_key: tenant.key, exp: 5.minutes.from_now.to_i },
        expires_in: 5.minutes
      )
    end
  end
end
