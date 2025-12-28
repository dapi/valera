# frozen_string_literal: true

require 'test_helper'

module Tenants
  class BookingsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @tenant = tenants(:one)
      @owner = @tenant.owner
      @owner.update!(password: 'password123')
      @booking = bookings(:one)
    end

    test 'redirects to login when not authenticated' do
      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      get '/bookings'

      assert_redirected_to '/session/new'
    end

    test 'shows bookings list when authenticated' do
      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      post '/session', params: { email: @owner.email, password: 'password123' }

      get '/bookings'

      assert_response :success
      assert_select 'h1', /Заявки/
    end

    test 'displays booking in the list' do
      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      post '/session', params: { email: @owner.email, password: 'password123' }

      get '/bookings'

      assert_response :success
      assert_select 'table tbody tr', minimum: 1
    end

    test 'filters bookings by date_from' do
      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      post '/session', params: { email: @owner.email, password: 'password123' }

      get '/bookings', params: { date_from: Date.today.to_s }

      assert_response :success
    end

    test 'filters bookings by date_to' do
      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      post '/session', params: { email: @owner.email, password: 'password123' }

      get '/bookings', params: { date_to: Date.today.to_s }

      assert_response :success
    end

    test 'filters bookings by date range' do
      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      post '/session', params: { email: @owner.email, password: 'password123' }

      get '/bookings', params: {
        date_from: 1.week.ago.to_date.to_s,
        date_to: Date.today.to_s
      }

      assert_response :success
    end

    test 'ignores invalid date format' do
      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      post '/session', params: { email: @owner.email, password: 'password123' }

      get '/bookings', params: { date_from: 'invalid-date' }

      assert_response :success
    end

    test 'shows booking detail page' do
      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      post '/session', params: { email: @owner.email, password: 'password123' }

      get "/bookings/#{@booking.id}"

      assert_response :success
      assert_select 'h1', /Заявка #{@booking.public_number}/
    end

    test 'shows booking client info' do
      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      post '/session', params: { email: @owner.email, password: 'password123' }

      get "/bookings/#{@booking.id}"

      assert_response :success
      assert_select 'div', text: /Клиент/
    end

    test 'shows booking vehicle info' do
      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      post '/session', params: { email: @owner.email, password: 'password123' }

      get "/bookings/#{@booking.id}"

      assert_response :success
      assert_select 'div', text: /Автомобиль/
    end

    test 'returns 404 for booking from another tenant' do
      other_booking = bookings(:tenant_two_booking)
      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      post '/session', params: { email: @owner.email, password: 'password123' }

      get "/bookings/#{other_booking.id}"

      assert_response :not_found
    end
  end
end
