# frozen_string_literal: true

module Tenants
  # Settings controller for tenant dashboard.
  # Allows owner or admin to edit tenant settings: subdomain, Telegram config, and content.
  #
  class SettingsController < ApplicationController
    before_action :require_admin!
    before_action :set_tenant

    # GET /settings/edit
    def edit
      load_webhook_status
    end

    # PATCH /settings
    def update
      old_key = @tenant.key

      if @tenant.update(tenant_params)
        handle_successful_update(old_key)
      else
        load_webhook_status
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_tenant
      @tenant = current_tenant
    end

    def tenant_params
      params.require(:tenant).permit(
        :key,
        :new_bot_token,
        :admin_chat_id,
        :welcome_message,
        :company_info,
        :price_list
      )
    end

    def handle_successful_update(old_key)
      if @tenant.key != old_key
        redirect_to_new_subdomain
      else
        redirect_to edit_tenant_settings_path(anchor: params[:active_tab]),
                    notice: t('.success')
      end
    end

    def redirect_to_new_subdomain
      new_host = "#{@tenant.key}.#{ApplicationConfig.host}"
      port_suffix = request.port.in?([80, 443]) ? '' : ":#{request.port}"
      new_url = "#{request.protocol}#{new_host}#{port_suffix}#{edit_tenant_settings_path}"

      redirect_to new_url, notice: t('.key_changed'), allow_other_host: true
    end

    def load_webhook_status
      return unless @tenant.bot_token.present?

      @webhook_info = TenantWebhookService.new(@tenant).webhook_info
      @expected_url = @tenant.webhook_url
      @current_url = @webhook_info.dig('result', 'url')
      @webhook_status = determine_webhook_status
    rescue TenantWebhookService::TelegramApiError, Telegram::Bot::Error => e
      @webhook_error = e.message
    end

    def determine_webhook_status
      return :not_set if @current_url.blank?

      @current_url == @expected_url ? :correct : :mismatch
    end
  end
end
