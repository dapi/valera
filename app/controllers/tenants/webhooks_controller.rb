# frozen_string_literal: true

module Tenants
  # Controller for managing Telegram webhook from tenant dashboard.
  # Allows admin to setup, remove, and check webhook status.
  #
  class WebhooksController < ApplicationController
    include ErrorLogger

    before_action :require_admin!

    # Setup webhook in Telegram
    def create
      TenantWebhookService.new(current_tenant).setup_webhook

      redirect_to edit_tenant_settings_path(anchor: 'telegram'),
                  notice: t('.success')
    rescue TenantWebhookService::TelegramApiError => e
      log_webhook_error('create', e)
      redirect_to edit_tenant_settings_path(anchor: 'telegram'),
                  alert: t('.error', message: e.message)
    end

    # Remove webhook from Telegram
    def destroy
      TenantWebhookService.new(current_tenant).remove_webhook

      redirect_to edit_tenant_settings_path(anchor: 'telegram'),
                  notice: t('.success')
    rescue TenantWebhookService::TelegramApiError => e
      log_webhook_error('destroy', e)
      redirect_to edit_tenant_settings_path(anchor: 'telegram'),
                  alert: t('.error', message: e.message)
    end

    private

    def log_webhook_error(action, error)
      Rails.logger.warn "[WebhooksController##{action}] #{error.message} (tenant: #{current_tenant.key})"
    end
  end
end
