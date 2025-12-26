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

    # POST /admin/tenants/:id/test_telegram
    # Тестирует подключение к Telegram API и показывает информацию о боте
    def test_telegram
      tenant = requested_resource
      bot_info = tenant.bot_client.get_me
      webhook_info = TenantWebhookService.new(tenant).webhook_info

      webhook_status = webhook_info['url'].present? ? webhook_info['url'] : t('.webhook_not_set')
      redirect_to [ :admin, tenant ], notice: t('.success', username: bot_info['username'], webhook: webhook_status)
    rescue TenantWebhookService::TelegramApiError, Telegram::Bot::Error => e
      redirect_to [ :admin, tenant ], alert: t('.error', message: e.message)
    end

    # POST /admin/tenants/:id/setup_webhook
    # Устанавливает webhook в Telegram для данного tenant
    def setup_webhook
      tenant = requested_resource
      TenantWebhookService.new(tenant).setup_webhook

      redirect_to [ :admin, tenant ], notice: t('.success')
    rescue TenantWebhookService::TelegramApiError => e
      redirect_to [ :admin, tenant ], alert: t('.error', message: e.message)
    end

    # DELETE /admin/tenants/:id/remove_webhook
    # Удаляет webhook в Telegram для данного tenant
    def remove_webhook
      tenant = requested_resource
      TenantWebhookService.new(tenant).remove_webhook

      redirect_to [ :admin, tenant ], notice: t('.success')
    rescue TenantWebhookService::TelegramApiError => e
      redirect_to [ :admin, tenant ], alert: t('.error', message: e.message)
    end
  end
end
