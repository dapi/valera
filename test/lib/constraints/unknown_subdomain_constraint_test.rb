# frozen_string_literal: true

require 'test_helper'

module Constraints
  class UnknownSubdomainConstraintTest < ActiveSupport::TestCase
    setup do
      @constraint = UnknownSubdomainConstraint.new
      @existing_tenant = tenants(:one)
    end

    test 'matches when subdomain is not an existing tenant' do
      request = mock_request('nonexistent')
      assert @constraint.matches?(request)
    end

    test 'does not match when subdomain is empty' do
      request = mock_request('')
      refute @constraint.matches?(request)
    end

    test 'does not match when subdomain is nil' do
      request = mock_request(nil)
      refute @constraint.matches?(request)
    end

    test 'does not match when subdomain is an existing tenant' do
      request = mock_request(@existing_tenant.key)
      refute @constraint.matches?(request)
    end

    test 'does not match reserved subdomain admin' do
      request = mock_request('admin')
      refute @constraint.matches?(request)
    end

    test 'does not match reserved subdomain www' do
      request = mock_request('www')
      refute @constraint.matches?(request)
    end

    test 'does not match reserved subdomain api' do
      request = mock_request('api')
      refute @constraint.matches?(request)
    end

    test 'matches random unknown subdomain' do
      request = mock_request('randomtenant123')
      assert @constraint.matches?(request)
    end

    private

    # Simple mock request object
    MockRequest = Struct.new(:subdomain)

    def mock_request(subdomain)
      MockRequest.new(subdomain)
    end
  end
end
