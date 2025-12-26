# frozen_string_literal: true

module Admin
  class AdminUsersController < Admin::ApplicationController
    before_action :authorize_superuser!, only: %i[new create destroy]
    before_action :authorize_edit_access!, only: %i[edit update]

    private

    # Manager can only edit their own profile
    def authorize_edit_access!
      return if current_admin_user&.superuser?
      return if requested_resource == current_admin_user

      redirect_to admin_root_path, alert: t('admin.admin_users.edit_own_profile_only')
    end

    # Manager cannot change role field
    def resource_params
      params_hash = super

      unless current_admin_user&.superuser?
        params_hash.delete(:role)
      end

      params_hash
    end
  end
end
