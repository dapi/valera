# frozen_string_literal: true

require 'test_helper'

module Tenants
  module Clients
    class ExportsControllerTest < ActionDispatch::IntegrationTest
      setup do
        @tenant = tenants(:one)
        @owner = @tenant.owner
        @owner.update!(password: 'password123')
      end

      test 'redirects to login when not authenticated' do
        host! "#{@tenant.key}.#{ApplicationConfig.host}"
        post '/clients/export'

        assert_redirected_to '/session/new'
      end

      test 'exports clients as CSV when authenticated' do
        host! "#{@tenant.key}.#{ApplicationConfig.host}"
        post '/session', params: { email: @owner.email, password: 'password123' }

        post '/clients/export'

        assert_response :success
        assert_equal 'text/csv; charset=utf-8', response.content_type
      end

      test 'CSV filename contains current date' do
        host! "#{@tenant.key}.#{ApplicationConfig.host}"
        post '/session', params: { email: @owner.email, password: 'password123' }

        post '/clients/export'

        assert_match(/clients-#{Date.current}\.csv/, response.headers['Content-Disposition'])
      end

      test 'CSV contains UTF-8 BOM' do
        host! "#{@tenant.key}.#{ApplicationConfig.host}"
        post '/session', params: { email: @owner.email, password: 'password123' }

        post '/clients/export'

        assert response.body.start_with?("\xEF\xBB\xBF"), 'CSV should start with UTF-8 BOM'
      end

      test 'CSV contains client data' do
        host! "#{@tenant.key}.#{ApplicationConfig.host}"
        post '/session', params: { email: @owner.email, password: 'password123' }
        client = clients(:one)

        post '/clients/export'

        assert_includes response.body, client.display_name
      end

      test 'exports only current tenant clients' do
        host! "#{@tenant.key}.#{ApplicationConfig.host}"
        post '/session', params: { email: @owner.email, password: 'password123' }
        other_client = clients(:two)

        post '/clients/export'

        assert_not_includes response.body, other_client.display_name
      end
    end
  end
end
