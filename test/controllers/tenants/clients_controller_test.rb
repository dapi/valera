# frozen_string_literal: true

require 'test_helper'

module Tenants
  class ClientsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @tenant = tenants(:one)
      @owner = @tenant.owner
      @owner.update!(password: 'password123')
      @client = clients(:one)
    end

    test 'redirects to login when not authenticated' do
      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      get '/clients'

      assert_redirected_to '/session/new'
    end

    test 'shows clients list when authenticated' do
      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      post '/session', params: { email: @owner.email, password: 'password123' }

      get '/clients'

      assert_response :success
      assert_select 'h1', /Клиенты/
    end

    test 'displays client in the list' do
      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      post '/session', params: { email: @owner.email, password: 'password123' }

      get '/clients'

      assert_response :success
      assert_select 'table tbody tr', minimum: 1
      assert_select 'td', text: @client.display_name
    end

    test 'search filters clients by name' do
      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      post '/session', params: { email: @owner.email, password: 'password123' }

      get '/clients', params: { q: 'Ivan' }

      assert_response :success
      assert_select 'td', text: @client.display_name
    end

    test 'search filters clients by phone' do
      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      post '/session', params: { email: @owner.email, password: 'password123' }

      get '/clients', params: { q: '123-45' }

      assert_response :success
      assert_select 'td', text: @client.display_name
    end

    test 'shows no results for non-matching search' do
      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      post '/session', params: { email: @owner.email, password: 'password123' }

      get '/clients', params: { q: 'nonexistent' }

      assert_response :success
      assert_select 'p', /не найдены/
    end

    test 'shows client detail page' do
      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      post '/session', params: { email: @owner.email, password: 'password123' }

      get "/clients/#{@client.id}"

      assert_response :success
      assert_select 'h1', @client.display_name
    end

    test 'shows client vehicles section' do
      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      post '/session', params: { email: @owner.email, password: 'password123' }

      get "/clients/#{@client.id}"

      assert_response :success
      assert_select 'h2', /Автомобили/
    end

    test 'shows client bookings section' do
      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      post '/session', params: { email: @owner.email, password: 'password123' }

      get "/clients/#{@client.id}"

      assert_response :success
      assert_select 'h2', /Заявки/
    end

    test 'returns 404 for client from another tenant' do
      other_client = clients(:two)
      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      post '/session', params: { email: @owner.email, password: 'password123' }

      get "/clients/#{other_client.id}"

      assert_response :not_found
    end
  end
end
