# frozen_string_literal: true

require 'test_helper'

module Tenants
  module Bookings
    class ExportsControllerTest < ActionDispatch::IntegrationTest
      setup do
        @tenant = tenants(:one)
        @owner = @tenant.owner
        @owner.update!(password: 'password123')
      end

      test 'redirects to login when not authenticated' do
        host! "#{@tenant.key}.#{ApplicationConfig.host}"
        post '/bookings/export'

        assert_redirected_to '/session/new'
      end

      test 'exports bookings as CSV when authenticated' do
        host! "#{@tenant.key}.#{ApplicationConfig.host}"
        post '/session', params: { email: @owner.email, password: 'password123' }

        post '/bookings/export'

        assert_response :success
        assert_equal 'text/csv; charset=utf-8', response.content_type
      end

      test 'CSV filename contains current date' do
        host! "#{@tenant.key}.#{ApplicationConfig.host}"
        post '/session', params: { email: @owner.email, password: 'password123' }

        post '/bookings/export'

        assert_match(/bookings-#{Date.current}\.csv/, response.headers['Content-Disposition'])
      end

      test 'CSV contains UTF-8 BOM' do
        host! "#{@tenant.key}.#{ApplicationConfig.host}"
        post '/session', params: { email: @owner.email, password: 'password123' }

        post '/bookings/export'

        assert response.body.start_with?("\xEF\xBB\xBF"), 'CSV should start with UTF-8 BOM'
      end

      test 'CSV contains booking data' do
        host! "#{@tenant.key}.#{ApplicationConfig.host}"
        post '/session', params: { email: @owner.email, password: 'password123' }
        booking = bookings(:one)

        post '/bookings/export'

        assert_includes response.body, booking.public_number
      end

      test 'exports only current tenant bookings' do
        host! "#{@tenant.key}.#{ApplicationConfig.host}"
        post '/session', params: { email: @owner.email, password: 'password123' }
        other_booking = bookings(:tenant_two_booking)

        post '/bookings/export'

        assert_not_includes response.body, other_booking.public_number
      end

      test 'filters bookings by date_from' do
        host! "#{@tenant.key}.#{ApplicationConfig.host}"
        post '/session', params: { email: @owner.email, password: 'password123' }

        # Set date_from to tomorrow to exclude all existing bookings
        post '/bookings/export', params: { date_from: Date.tomorrow.to_s }

        # Should only have headers, no data rows (beyond the header)
        lines = response.body.split("\n")
        assert_equal 1, lines.size, 'Should only have header row when filtering by future date'
      end

      test 'filters bookings by date_to' do
        host! "#{@tenant.key}.#{ApplicationConfig.host}"
        post '/session', params: { email: @owner.email, password: 'password123' }

        # Set date_to to yesterday to exclude all existing bookings
        post '/bookings/export', params: { date_to: Date.yesterday.to_s }

        # Should only have headers, no data rows
        lines = response.body.split("\n")
        assert_equal 1, lines.size, 'Should only have header row when filtering by past date'
      end

      test 'handles invalid date_from gracefully' do
        host! "#{@tenant.key}.#{ApplicationConfig.host}"
        post '/session', params: { email: @owner.email, password: 'password123' }

        post '/bookings/export', params: { date_from: 'invalid-date' }

        # Should succeed and ignore invalid date filter
        assert_response :success
        assert_equal 'text/csv; charset=utf-8', response.content_type
      end

      test 'handles invalid date_to gracefully' do
        host! "#{@tenant.key}.#{ApplicationConfig.host}"
        post '/session', params: { email: @owner.email, password: 'password123' }

        post '/bookings/export', params: { date_to: '2024-13-45' }

        # Should succeed and ignore invalid date filter
        assert_response :success
      end
    end
  end
end
