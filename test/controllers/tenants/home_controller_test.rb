# frozen_string_literal: true

require 'test_helper'

module Tenants
  class HomeControllerTest < ActionDispatch::IntegrationTest
    setup do
      @tenant = tenants(:one)
      @owner = @tenant.owner
      @owner.update!(password: 'password123')
    end

    test 'redirects to login when not authenticated' do
      host! "#{@tenant.key}.lvh.me"
      get '/'

      assert_redirected_to '/session/new'
    end

    test 'shows dashboard when authenticated' do
      host! "#{@tenant.key}.lvh.me"
      post '/session', params: { password: 'password123' }

      get '/'

      assert_response :success
      assert_select 'h1', /Обзор/
    end

    test 'shows tenant statistics' do
      host! "#{@tenant.key}.lvh.me"
      post '/session', params: { password: 'password123' }

      get '/'

      assert_response :success
      # Check that stats cards are present
      assert_select '.bg-white.rounded-lg.shadow', minimum: 4
    end

    test 'displays tenant name in sidebar' do
      host! "#{@tenant.key}.lvh.me"
      post '/session', params: { password: 'password123' }

      get '/'

      assert_response :success
      assert_select 'aside h1', @tenant.name
    end

    test 'supports period parameter for chart' do
      host! "#{@tenant.key}.lvh.me"
      post '/session', params: { password: 'password123' }

      get '/', params: { period: 30 }

      assert_response :success
    end

    test 'defaults to 7 days period for invalid period' do
      host! "#{@tenant.key}.lvh.me"
      post '/session', params: { password: 'password123' }

      get '/', params: { period: 999 }

      assert_response :success
    end

    test 'shows activity chart section' do
      host! "#{@tenant.key}.lvh.me"
      post '/session', params: { password: 'password123' }

      get '/'

      assert_response :success
      assert_select 'h2', /Активность/
      assert_select 'canvas[data-chart-target="canvas"]'
    end

    test 'shows recent dialogs section' do
      host! "#{@tenant.key}.lvh.me"
      post '/session', params: { password: 'password123' }

      get '/'

      assert_response :success
      assert_select 'h2', /Последние диалоги/
    end
  end
end
