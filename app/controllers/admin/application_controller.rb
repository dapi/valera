# frozen_string_literal: true

# All Administrate controllers inherit from this controller.
# Authentication is handled via session-based login.
module Admin
  class ApplicationController < Administrate::ApplicationController
    before_action :authenticate_admin!

    helper_method :current_admin_user, :impersonating?, :original_admin_user

    private

    def authenticate_admin!
      return if current_admin_user

      redirect_to admin_login_path, alert: 'Please log in to access the admin panel'
    end

    def current_admin_user
      Current.admin_user ||= AdminUser.find_by(id: session[:admin_user_id])
    end

    def impersonating?
      session[:original_admin_user_id].present?
    end

    def original_admin_user
      return unless impersonating?

      @original_admin_user ||= AdminUser.find_by(id: session[:original_admin_user_id])
    end

    def authorize_superuser!
      # When impersonating, check the original user's role
      user_to_check = impersonating? ? original_admin_user : current_admin_user

      return if user_to_check&.superuser?

      redirect_to admin_root_path, alert: t('admin.impersonations.access_denied')
    end

    # Override this value to specify the number of elements to display at a time
    # on index pages. Defaults to 20.
    # def records_per_page
    #   params[:per_page] || 20
    # end

    # Apply COLLECTION_FILTERS from dashboard if defined.
    # Filters are applied via URL parameters matching filter names.
    # Example: ?provider=openai&family=gpt
    def scoped_resource
      apply_collection_filters(super)
    end

    def apply_collection_filters(resources)
      return resources unless dashboard_class.const_defined?(:COLLECTION_FILTERS)

      filters = dashboard_class::COLLECTION_FILTERS
      filters.each do |filter_name, filter_proc|
        filter_value = params[filter_name]
        next if filter_value.blank?

        resources = safe_apply_filter(resources, filter_name, filter_proc, filter_value)
      end
      resources
    end

    def safe_apply_filter(resources, filter_name, filter_proc, filter_value)
      filter_proc.call(resources, filter_value)
    rescue ActiveRecord::StatementInvalid => e
      Rails.logger.error "[Admin::Filters] Filter '#{filter_name}' failed: #{e.message}"
      resources
    end

    def dashboard_class
      "#{resource_name.to_s.camelize}Dashboard".constantize
    end
  end
end
