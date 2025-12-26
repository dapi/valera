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
    # Handles both Array and Hash (tabbed) FORM_ATTRIBUTES
    def permitted_attributes
      attrs = super
      # If Hash (tabbed form), flatten all values into a single array
      attrs = attrs.values.flatten if attrs.is_a?(Hash)

      attrs.flat_map do |attr|
        case attr
        when :bot_token
          :new_bot_token # SecureTokenField uses virtual attribute
        when :owner_and_manager
          %i[owner_id manager_id] # FieldRowField expands to actual attributes
        else
          attr
        end
      end
    end
  end
end
