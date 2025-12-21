# frozen_string_literal: true

module Tenants
  # Base controller for tenant dashboard.
  # Current.tenant is set by TenantSubdomainConstraint in routes.
  # Authenticates owner via session.
  #
  # @example Usage in child controller
  #   class Tenants::HomeController < Tenants::ApplicationController
  #     def show
  #       @stats = build_stats
  #     end
  #   end
  #
  class ApplicationController < ::ApplicationController
    before_action :authenticate_owner!

    helper_method :current_user, :user_signed_in?, :current_tenant

    layout 'tenants/application'

    private

    # Returns current tenant from Current (set by TenantSubdomainConstraint).
    #
    # @return [Tenant]
    def current_tenant
      Current.tenant
    end

    # Ensures current user is the owner of the tenant.
    # Redirects to login if not authenticated or not the owner.
    def authenticate_owner!
      return if current_tenant&.owner_id == current_user&.id

      redirect_to new_tenant_session_path
    end

    # Returns current logged in user from session.
    #
    # @return [User, nil]
    def current_user
      return @current_user if defined?(@current_user)

      @current_user = User.find_by(id: session[:user_id])
    end

    # Returns whether user is authenticated.
    #
    # @return [Boolean]
    def user_signed_in?
      current_user.present?
    end
  end
end
