# frozen_string_literal: true

require 'test_helper'

class PasswordResetsControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper
  include ActionMailer::TestHelper

  setup do
    host! ApplicationConfig.host
    @user = users(:one)
    @user.update!(password: 'old-password')
  end

  test 'known and unknown addresses receive identical public responses' do
    assert_enqueued_emails 1 do
      post '/password_resets', params: { email: @user.email.upcase }
    end
    known_notice = flash[:notice]
    assert_redirected_to '/password_resets/new'
    assert_no_enqueued_emails do
      post '/password_resets', params: { email: 'unknown@example.com' }
    end
    assert_redirected_to '/password_resets/new'
    assert_equal known_notice, flash[:notice]
  end

  test 'reset token is short lived and becomes invalid after changing password' do
    token = @user.password_reset_token
    patch '/password_resets', params: { token: token, password: 'new-password', password_confirmation: 'new-password' }
    assert_redirected_to login_url
    assert @user.reload.authenticate('new-password')
    assert_not @user.authenticate('old-password')
    assert_nil User.find_by_password_reset_token(token)

    patch '/password_resets', params: { token: token, password: 'another-password', password_confirmation: 'another-password' }
    assert_redirected_to '/password_resets/new'
    assert @user.reload.authenticate('new-password')

    token = @user.password_reset_token
    travel 16.minutes do
      patch '/password_resets', params: { token: token, password: 'another-password', password_confirmation: 'another-password' }
      assert_redirected_to '/password_resets/new'
    end
  end

  test 'reset requires valid confirmation and preserves account on failure' do
    token = @user.password_reset_token
    patch '/password_resets', params: { token: token, password: 'new-password', password_confirmation: 'different-password' }
    assert_response :unprocessable_entity
    assert @user.reload.authenticate('old-password')
    patch '/password_resets', params: { token: token, password: 'new-password' }
    assert_response :unprocessable_entity
    assert @user.reload.authenticate('old-password')
    patch '/password_resets', params: { token: 'invalid', password: 'new-password', password_confirmation: 'new-password' }
    assert_redirected_to '/password_resets/new'
  end

  test 'password reset revokes prior browser sessions and cross domain tokens' do
    old_session = open_session
    old_session.host! ApplicationConfig.host
    old_session.post '/login', params: { email: @user.email, password: 'old-password' }
    old_session.get '/login/select'
    old_session.assert_response :success
    cross_token = Rails.application.message_verifier(:cross_auth).generate(
      { user_id: @user.id, tenant_key: tenants(:one).key, session_version: @user.session_version }, expires_in: 5.minutes
    )

    patch '/password_resets', params: { token: @user.password_reset_token, password: 'new-password', password_confirmation: 'new-password' }
    old_session.get '/login/select'
    old_session.assert_redirected_to '/login'
    host! "#{tenants(:one).key}.#{ApplicationConfig.host}"
    get '/auth/token', params: { t: cross_token }
    assert_redirected_to '/session/new'
  end

  test 'mail sends fragment token and form advertises reset on both login screens' do
    mail = AccountMailer.password_reset(@user).message
    assert_includes mail.body.decoded, '/password_resets/edit#token='
    get '/password_resets/edit'
    assert_response :success
    assert_select '[data-controller="fragment-token"]'
    get '/login'
    assert_select 'a', 'Забыли пароль?'
    assert_select 'form[action="/login"][data-turbo="false"]'
    host! "#{tenants(:one).key}.#{ApplicationConfig.host}"
    get '/session/new'
    assert_select 'a', 'Забыли пароль?'
  end

  test 'cross domain login uses full navigation and a single base domain session cookie' do
    post '/login', params: { email: @user.email, password: 'old-password' }
    get '/login/select'
    assert_select 'form[action^="/login/select"][data-turbo="false"]', count: @user.accessible_tenants.count

    host! "#{tenants(:one).key}.#{ApplicationConfig.host}"
    post '/session', params: { email: @user.email, password: 'old-password' }
    cookie = Array(response.headers['set-cookie']).find { |value| value.start_with?('_session=') }
    assert cookie
    assert_equal ApplicationConfig.host, cookie[/domain=([^;]+)/i, 1]
  end
end
