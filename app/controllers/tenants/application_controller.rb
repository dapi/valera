# frozen_string_literal: true

module Tenants
  # Base controller for tenant dashboard.
  # Current.tenant is set by TenantSubdomainConstraint in routes.
  # Authenticates users with access (owner or member) via session.
  #
  # @example Usage in child controller
  #   class Tenants::HomeController < Tenants::ApplicationController
  #     def show
  #       @stats = build_stats
  #     end
  #   end
  #
  class ApplicationController < ::ApplicationController
    include RoleAuthorization

    before_action :authenticate_user_with_access!

    helper_method :current_user, :user_signed_in?, :current_tenant, :current_membership,
                  :current_user_is_owner?, :current_user_is_admin?, :current_user_can_manage_members?

    layout 'tenants/application'

    private

    # Returns current tenant from Current (set by TenantSubdomainConstraint).
    #
    # @return [Tenant]
    def current_tenant
      Current.tenant
    end

    # Returns current user's membership for current tenant.
    # nil if user is owner (no membership needed).
    #
    # @return [TenantMembership, nil]
    def current_membership
      return @current_membership if defined?(@current_membership)
      return @current_membership = nil unless current_user && current_tenant

      @current_membership = current_user.membership_for(current_tenant)
    end

    # Ensures current user has access to the tenant (owner or member).
    # Redirects to login if not authenticated or has no access.
    def authenticate_user_with_access!
      return if current_user&.has_access_to?(current_tenant)

      redirect_to new_tenant_session_path
    end

    # Checks if current user is owner of current tenant.
    #
    # @return [Boolean]
    def current_user_is_owner?
      current_tenant&.owner_id == current_user&.id
    end

    # Checks if current user is admin (owner or admin member).
    #
    # @return [Boolean]
    def current_user_is_admin?
      current_user_is_owner? || current_membership&.admin?
    end

    # Checks if current user can manage members.
    #
    # @return [Boolean]
    def current_user_can_manage_members?
      current_user_is_owner? || current_membership&.can_manage_members?
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
