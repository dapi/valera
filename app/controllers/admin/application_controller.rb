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

    # Override this value to specify the number of elements to display at a time
    # on index pages. Defaults to 20.
    # def records_per_page
    #   params[:per_page] || 20
    # end
  end
end
