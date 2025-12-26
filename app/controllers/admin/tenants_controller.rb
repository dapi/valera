# frozen_string_literal: true

module Admin
  class TenantsController < Admin::ApplicationController
    def scoped_resource
      if params[:manager_id].present?
        resource_class.where(manager_id: params[:manager_id])
      else
        resource_class
      end
    end
  end
end
