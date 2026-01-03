# frozen_string_literal: true

module Constraints
  # Route constraint that matches requests with a subdomain that is:
  # - Not empty
  # - Not a reserved subdomain (from ApplicationConfig.reserved_subdomains)
  # - Not an existing tenant key
  #
  # Used to show "tenant not found" page for unknown subdomains.
  #
  # @example Usage in routes.rb
  #   constraints Constraints::UnknownSubdomainConstraint.new do
  #     get '*path', to: 'tenants/not_found#show'
  #     root to: 'tenants/not_found#show'
  #   end
  #
  class UnknownSubdomainConstraint
    # Checks if the request has an unknown subdomain.
    #
    # @param request [ActionDispatch::Request] the incoming request
    # @return [Boolean] true if subdomain exists but is not a known tenant
    def matches?(request)
      subdomain = request.subdomain
      return false if subdomain.blank?

      # Skip reserved subdomains (they have their own routes)
      return false if ApplicationConfig.reserved_subdomains.include?(subdomain)

      # Check if tenant exists - if not, this constraint matches
      !Tenant.exists?(key: subdomain)
    end
  end
end
