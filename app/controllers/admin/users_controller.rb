module Admin
  class UsersController < Admin::ApplicationController
    before_action :authorize_superuser!, only: %i[new create edit update destroy]

    private

    # Remove blank password to avoid resetting existing password
    def resource_params
      params_hash = super
      params_hash.delete(:password) if params_hash[:password].blank?
      params_hash
    end
  end
end
