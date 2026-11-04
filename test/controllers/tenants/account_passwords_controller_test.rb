# frozen_string_literal: true

require 'test_helper'

module Tenants
  class AccountPasswordsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @tenant = tenants(:one)
      @user = users(:operator_user)
      @user.update!(password: 'old-password')
      host! "#{@tenant.key}.#{ApplicationConfig.host}"
    end

    test 'requires login and permits ordinary operators' do
      get '/account/password/edit'
      assert_redirected_to '/session/new'
      login
      get '/account/password/edit'
      assert_response :success
      assert_select 'input[type="password"]', count: 3
      assert_select 'a', 'Сменить пароль'
    end

    test 'current password and new password confirmation are required' do
      login
      patch '/account/password', params: { current_password: 'wrong', password: 'new-password', password_confirmation: 'new-password' }
      assert_response :unprocessable_entity
      assert @user.reload.authenticate('old-password')
      patch '/account/password', params: { current_password: 'old-password', password: 'new-password', password_confirmation: 'mismatch' }
      assert_response :unprocessable_entity
      assert @user.reload.authenticate('old-password')
      patch '/account/password', params: { current_password: 'old-password', password: 'new-password' }
      assert_response :unprocessable_entity
    end

    test 'changes only current user password and preserves current session' do
      login
      version = @user.session_version
      other = users(:two)
      other.update!(password: 'unrelated-password')
      other_digest = other.password_digest
      patch '/account/password', params: { current_password: 'old-password', password: 'new-password', password_confirmation: 'new-password', user_id: users(:two).id }
      assert_redirected_to '/account/password/edit'
      assert @user.reload.authenticate('new-password')
      assert_equal version + 1, @user.session_version
      assert_equal other_digest, users(:two).reload.password_digest
      follow_redirect!
      assert_response :success
      assert_equal @user.id, session[:user_id]
    end

    private

    def login
      post '/session', params: { email: @user.email, password: 'old-password' }
    end
  end
end
