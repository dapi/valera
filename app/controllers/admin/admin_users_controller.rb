# frozen_string_literal: true

module Admin
  class AdminUsersController < Admin::ApplicationController
    before_action :authorize_superuser!

    private

    def authorize_superuser!
      return if current_admin_user&.superuser?

      redirect_to admin_root_path, alert: 'Access denied. Superuser privileges required.'
    end
  end
end
