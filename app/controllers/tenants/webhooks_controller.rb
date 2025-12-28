# frozen_string_literal: true

module Tenants
  # Controller for managing Telegram webhook from tenant dashboard.
  # Allows admin to setup, remove, and check webhook status.
  #
  class WebhooksController < ApplicationController
    before_action :require_admin!

    # POST /webhook
    # Setup webhook in Telegram
    def create
      TenantWebhookService.new(current_tenant).setup_webhook

      redirect_to edit_tenant_settings_path(anchor: 'telegram'),
                  notice: t('.success')
    rescue TenantWebhookService::TelegramApiError => e
      redirect_to edit_tenant_settings_path(anchor: 'telegram'),
                  alert: t('.error', message: e.message)
    end

    # DELETE /webhook
    # Remove webhook from Telegram
    def destroy
      TenantWebhookService.new(current_tenant).remove_webhook

      redirect_to edit_tenant_settings_path(anchor: 'telegram'),
                  notice: t('.success')
    rescue TenantWebhookService::TelegramApiError => e
      redirect_to edit_tenant_settings_path(anchor: 'telegram'),
                  alert: t('.error', message: e.message)
    end
  end
end
