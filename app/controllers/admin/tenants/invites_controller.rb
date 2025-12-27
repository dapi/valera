# frozen_string_literal: true

module Admin
  module Tenants
    # Контроллер для управления приглашениями участников tenant из admin-панели
    #
    # Позволяет менеджерам создавать приглашения для владельцев и сотрудников.
    class InvitesController < Admin::ApplicationController
      before_action :set_tenant

      # POST /admin/tenants/:tenant_id/invites
      # Создаёт приглашение для tenant
      def create
        @invite = @tenant.tenant_invites.build(invite_params)
        @invite.invited_by_admin = current_admin_user
        @invite.expires_at = ApplicationConfig.tenant_invite_expiration_days.days.from_now

        if @invite.save
          redirect_to [ :admin, @tenant ], notice: t('.success', telegram_url: @invite.telegram_url)
        else
          redirect_to [ :admin, @tenant ], alert: @invite.errors.full_messages.to_sentence
        end
      end

      # DELETE /admin/tenants/:tenant_id/invites/:id
      # Отменяет приглашение
      def destroy
        @invite = @tenant.tenant_invites.find(params[:id])
        @invite.cancel!

        redirect_to [ :admin, @tenant ], notice: t('.success')
      end

      private

      def set_tenant
        @tenant = Tenant.find(params[:tenant_id])
      end

      def invite_params
        params.require(:tenant_invite).permit(:role)
      end
    end
  end
end
