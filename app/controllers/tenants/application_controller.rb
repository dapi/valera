# frozen_string_literal: true

module Tenants
  # Base controller for tenant dashboard.
  # Sets Current.tenant from subdomain and authenticates owner.
  #
  # @example Usage in child controller
  #   class Tenants::HomeController < Tenants::ApplicationController
  #     def show
  #       @stats = build_stats
  #     end
  #   end
  #
  class ApplicationController < ::ApplicationController
    before_action :set_tenant_from_subdomain
    before_action :authenticate_owner!

    layout 'tenants'

    private

    # Sets Current.tenant based on request subdomain.
    # Tenant is already validated by TenantSubdomainConstraint in routes.
    def set_tenant_from_subdomain
      @tenant = Tenant.find_by!(key: request.subdomain)
      Current.tenant = @tenant
    rescue ActiveRecord::RecordNotFound
      render 'tenants/errors/not_found', status: :not_found
    end

    # Ensures current user is the owner of the tenant.
    # Redirects to login if not authenticated or not the owner.
    def authenticate_owner!
      return if current_user&.owned_tenants&.include?(Current.tenant)

      redirect_to new_tenant_session_path
    end

    # Returns current logged in user from session.
    #
    # @return [User, nil]
    def current_user
      return @current_user if defined?(@current_user)

      @current_user = User.find_by(id: session[:user_id])
    end
    helper_method :current_user

    # Returns whether user is authenticated.
    #
    # @return [Boolean]
    def user_signed_in?
      current_user.present?
    end
    helper_method :user_signed_in?
  end
end
