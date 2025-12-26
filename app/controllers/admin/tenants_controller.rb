module Admin
  class TenantsController < Admin::ApplicationController
    def scoped_resource
      if params[:manager_id].present?
        resource_class.where(manager_id: params[:manager_id])
      else
        resource_class
      end
    end

    # Override permitted_attributes to use new_bot_token instead of bot_token
    # SecureTokenField uses virtual attribute for updates
    def permitted_attributes
      attrs = super
      # Replace bot_token with new_bot_token for SecureTokenField
      attrs.map { |attr| attr == :bot_token ? :new_bot_token : attr }
    end
  end
end
