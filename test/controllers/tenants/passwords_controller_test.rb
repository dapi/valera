# frozen_string_literal: true

require 'test_helper'

module Tenants
  class PasswordsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @tenant = tenants(:one)
      @owner = @tenant.owner
      @owner.update_column(:password_digest, nil)
    end

    test 'redirects to login without pending user' do
      host! "#{@tenant.key}.lvh.me"
      get '/password/new'

      assert_redirected_to '/session/new'
    end

    test 'shows set password form with pending user' do
      host! "#{@tenant.key}.lvh.me"
      post '/session', params: { password: 'anything' }

      get '/password/new'

      assert_response :success
      assert_select 'input[type=password]', count: 2
    end

    test 'sets password and logs in' do
      host! "#{@tenant.key}.lvh.me"
      post '/session', params: { password: 'anything' }

      post '/password', params: {
        user: {
          password: 'newpassword123',
          password_confirmation: 'newpassword123'
        }
      }

      assert_redirected_to '/'
      assert_equal @owner.id, session[:user_id]
      assert_nil session[:pending_user_id]
      assert @owner.reload.authenticate('newpassword123')
    end

    test 'rejects mismatched password confirmation' do
      host! "#{@tenant.key}.lvh.me"
      post '/session', params: { password: 'anything' }

      post '/password', params: {
        user: {
          password: 'newpassword123',
          password_confirmation: 'differentpassword'
        }
      }

      assert_response :unprocessable_entity
    end

    test 'rejects password shorter than 8 characters' do
      host! "#{@tenant.key}.lvh.me"
      post '/session', params: { password: 'anything' }

      post '/password', params: {
        user: {
          password: 'short',
          password_confirmation: 'short'
        }
      }

      assert_response :unprocessable_entity
    end
  end
end
