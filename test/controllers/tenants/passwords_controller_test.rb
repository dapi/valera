# frozen_string_literal: true

require 'test_helper'

module Tenants
  class PasswordsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @tenant = tenants(:one)
      @owner = @tenant.owner
      @owner.update_column(:password_digest, nil)
      host! "#{@tenant.key}.#{ApplicationConfig.host}"
    end

    test 'legacy password page redirects to verified email reset' do
      get '/password/new'
      assert_redirected_to new_password_reset_url(**ApplicationConfig.default_url_options)
    end

    test 'knowing an email is insufficient to set an initial password' do
      post '/session', params: { email: @owner.email, password: 'anything' }
      post '/password', params: { user: { password: 'new-password', password_confirmation: 'new-password' } }
      assert_redirected_to new_password_reset_url(**ApplicationConfig.default_url_options)
      assert_nil @owner.reload.password_digest
      assert_nil session[:user_id]
    end
  end
end
