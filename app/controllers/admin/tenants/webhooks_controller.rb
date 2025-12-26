# frozen_string_literal: true

module Admin
  module Tenants
    # Контроллер для управления Telegram webhook тенанта
    #
    # Предоставляет действия для тестирования, установки и удаления webhook.
    class WebhooksController < Admin::ApplicationController
      before_action :set_tenant

      # GET /admin/tenants/:tenant_id/webhook
      # Показывает информацию о текущем webhook на отдельной странице
      def show
        @bot_info = @tenant.bot_client.get_me
        @webhook_info = TenantWebhookService.new(@tenant).webhook_info
        @expected_url = @tenant.webhook_url
        # Telegram API возвращает данные в result.url
        @current_url = @webhook_info.dig('result', 'url')

        @webhook_status = determine_webhook_status
      rescue TenantWebhookService::TelegramApiError, Telegram::Bot::Error => e
        @error = e.message
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

      # Определяет статус webhook
      # @return [Symbol] :not_set, :correct, :mismatch
      def determine_webhook_status
        return :not_set if @current_url.blank?

        @current_url == @expected_url ? :correct : :mismatch
      end
    end
  end
end
