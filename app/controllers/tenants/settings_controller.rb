# frozen_string_literal: true

module Tenants
  # Settings controller for tenant dashboard.
  # Allows admin to edit tenant settings like key (subdomain).
  #
  class SettingsController < ApplicationController
    before_action :require_admin!

    # GET /settings/edit
    def edit
      @tenant = current_tenant
    end

    # PATCH /settings
    def update
      @tenant = current_tenant
      old_key = @tenant.key

      if @tenant.update(tenant_params)
        if @tenant.key != old_key
          redirect_to_new_subdomain
        else
          redirect_to edit_tenant_settings_path, notice: t('.success')
        end
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def tenant_params
      params.require(:tenant).permit(:key)
    end

    # Redirect to new subdomain after key change
    def redirect_to_new_subdomain
      new_host = "#{@tenant.key}.#{ApplicationConfig.host}"
      new_url = "#{request.protocol}#{new_host}:#{request.port}#{edit_tenant_settings_path}"

      redirect_to new_url, notice: t('.key_changed'), allow_other_host: true
    end
  end
end
