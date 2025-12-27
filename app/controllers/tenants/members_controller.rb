# frozen_string_literal: true

module Tenants
  # Контроллер для управления участниками tenant'а
  #
  # Позволяет owner'у и admin'ам приглашать новых участников
  # и управлять существующими членами команды.
  class MembersController < ApplicationController
    before_action :require_admin!

    # GET /members
    def index
      @memberships = current_tenant.tenant_memberships.includes(:user, tenant_invite: %i[invited_by_user invited_by_admin])
      @pending_invites = current_tenant.tenant_invites.active.includes(:invited_by_user, :invited_by_admin)
      @owner = current_tenant.owner
    end

    # POST /members
    def create
      role = params[:role]
      unless TenantMembership.roles.key?(role)
        redirect_to tenant_members_path, alert: 'Недопустимая роль'
        return
      end

      invite = current_tenant.tenant_invites.create!(
        invited_by_user: current_user,
        role: role,
        expires_at: 7.days.from_now
      )

      @invite_url = invite.telegram_url
      @role = role

      respond_to do |format|
        format.html { redirect_to invite_tenant_members_path(token: invite.token, role: role) }
        format.turbo_stream
      end
    end

    # GET /members/invite
    def invite
      @token = params[:token]
      @role = params[:role]
      @invite = current_tenant.tenant_invites.find_by(token: @token)
      @invite_url = @invite&.telegram_url || "https://t.me/#{ApplicationConfig.platform_bot_username}?start=#{@token}"
    end

    # DELETE /members/:id
    def destroy
      membership = current_tenant.tenant_memberships.find(params[:id])

      if membership.destroy
        redirect_to tenant_members_path, notice: 'Участник удалён из команды'
      else
        redirect_to tenant_members_path, alert: 'Не удалось удалить участника'
      end
    end

    # DELETE /members/invites/:id
    def cancel_invite
      invite = current_tenant.tenant_invites.pending.find(params[:id])
      invite.cancel!
      redirect_to tenant_members_path, notice: 'Приглашение отменено'
    end

    private

    def require_admin!
      return if current_user_can_manage_members?

      redirect_to tenant_root_path, alert: 'У вас нет прав для управления участниками'
    end
  end
end
