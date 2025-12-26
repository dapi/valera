# frozen_string_literal: true

module Admin
  module Tenants
    # Контроллер для управления Telegram webhook тенанта
    #
    # Предоставляет действия для тестирования, установки и удаления webhook.
    class WebhooksController < Admin::ApplicationController
      before_action :set_tenant

      # GET /admin/tenants/:tenant_id/webhook
      # Показывает информацию о текущем webhook
      def show
        bot_info = @tenant.bot_client.get_me
        webhook_info = TenantWebhookService.new(@tenant).webhook_info

        webhook_status = build_webhook_status(webhook_info)
        redirect_back_or_to [ :admin, @tenant ], notice: t('.success', username: bot_info.dig('result', 'username'), webhook: webhook_status)
      rescue TenantWebhookService::TelegramApiError, Telegram::Bot::Error => e
        redirect_back_or_to [ :admin, @tenant ], alert: t('.error', message: e.message)
      end

      # POST /admin/tenants/:tenant_id/webhook
      # Устанавливает webhook в Telegram
      def create
        TenantWebhookService.new(@tenant).setup_webhook

        redirect_back_or_to [ :admin, @tenant ], notice: t('.success')
      rescue TenantWebhookService::TelegramApiError => e
        redirect_back_or_to [ :admin, @tenant ], alert: t('.error', message: e.message)
      end

      # DELETE /admin/tenants/:tenant_id/webhook
      # Удаляет webhook из Telegram
      def destroy
        TenantWebhookService.new(@tenant).remove_webhook

        redirect_back_or_to [ :admin, @tenant ], notice: t('.success')
      rescue TenantWebhookService::TelegramApiError => e
        redirect_back_or_to [ :admin, @tenant ], alert: t('.error', message: e.message)
      end

      private

      def set_tenant
        @tenant = Tenant.find(params[:tenant_id])
      end

      # Формирует статус webhook для отображения
      # @param webhook_info [Hash] информация о webhook из Telegram API
      # @return [String] статус webhook
      def build_webhook_status(webhook_info)
        current_url = webhook_info['url']
        return t('.webhook_not_set') if current_url.blank?

        expected_url = @tenant.webhook_url
        if current_url == expected_url
          t('.webhook_correct', url: current_url)
        else
          t('.webhook_mismatch', current: current_url, expected: expected_url)
        end
      end
    end
  end
end
