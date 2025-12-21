# frozen_string_literal: true

module Constraints
  # Route constraint that matches requests with a valid tenant subdomain.
  # Checks if the subdomain exists in the database as a tenant key.
  #
  # @example Usage in routes.rb
  #   constraints Constraints::TenantSubdomainConstraint.new do
  #     scope module: 'tenants' do
  #       root 'home#show'
  #     end
  #   end
  #
  class TenantSubdomainConstraint
    # Checks if the request subdomain matches an existing tenant key.
    # Sets Current.tenant if found, so subsequent code can use it.
    #
    # @param request [ActionDispatch::Request] the incoming request
    # @return [Boolean] true if tenant exists with this key
    def matches?(request)
      subdomain = request.subdomain
      return false if subdomain.blank?

      tenant = Tenant.find_by(key: subdomain)
      return false unless tenant

      Current.tenant = tenant
      true
    end
  end
end
