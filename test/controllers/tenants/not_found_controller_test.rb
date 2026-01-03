# frozen_string_literal: true

require 'test_helper'

module Tenants
  class NotFoundControllerTest < ActionDispatch::IntegrationTest
    setup do
      @existing_tenant = tenants(:one)
    end

    test 'shows not found page for unknown subdomain' do
      host! "nonexistent.#{ApplicationConfig.host}"
      get '/'

      assert_response :not_found
      assert_select 'h1', /Аккаунт не найден/
    end

    test 'shows subdomain in the message' do
      host! "unknowntenant.#{ApplicationConfig.host}"
      get '/'

      assert_response :not_found
      assert_match(/unknowntenant/, response.body)
    end

    test 'contains link to main page' do
      host! "nonexistent.#{ApplicationConfig.host}"
      get '/'

      assert_response :not_found
      assert_select 'a', /На главную/
    end

    test 'contains link to login' do
      host! "nonexistent.#{ApplicationConfig.host}"
      get '/'

      assert_response :not_found
      assert_select 'a', /Войти/
    end

    test 'handles any path for unknown subdomain' do
      host! "nonexistent.#{ApplicationConfig.host}"
      get '/some/random/path'

      assert_response :not_found
      assert_select 'h1', /Аккаунт не найден/
    end

    test 'does not match admin subdomain' do
      host! "admin.#{ApplicationConfig.host}"
      get '/login'

      # Admin routes should still work
      assert_response :success
    end

    test 'does not match existing tenant subdomain' do
      host! "#{@existing_tenant.key}.#{ApplicationConfig.host}"
      get '/'

      # Should redirect to login (normal tenant behavior), not show not_found
      assert_redirected_to '/session/new'
    end
  end
end
