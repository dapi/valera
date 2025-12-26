module Admin
  class TenantsController < Admin::ApplicationController
    def scoped_resource
      if params[:manager_id].present?
        resource_class.where(manager_id: params[:manager_id])
      else
        resource_class
      end
    end

    # Override permitted_attributes for custom fields
    def permitted_attributes
      attrs = super
      attrs = attrs.flat_map do |attr|
        case attr
        when :bot_token
          :new_bot_token # SecureTokenField uses virtual attribute
        when :owner_and_manager
          %i[owner_id manager_id] # FieldRowField expands to actual attributes
        else
          attr
        end
      end
      attrs
    end
  end
end
