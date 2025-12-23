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
      @memberships = current_tenant.tenant_memberships.includes(:user, :invited_by)
      @owner = current_tenant.owner
    end

    # POST /members
    def create
      role = params[:role]
      unless TenantMembership.roles.key?(role)
        redirect_to tenant_members_path, alert: 'Недопустимая роль'
        return
      end

      invited_by = current_user
      token = TelegramAuthService.new.create_member_invite_token(
        tenant_id: current_tenant.id,
        role: role,
        invited_by_user_id: invited_by.id
      )

      @invite_url = "https://t.me/#{ApplicationConfig.platform_bot_username}?start=#{token}"
      @role = role

      respond_to do |format|
        format.html { redirect_to invite_tenant_members_path(token: token, role: role) }
        format.turbo_stream
      end
    end

    # GET /members/invite
    def invite
      @token = params[:token]
      @role = params[:role]
      @invite_url = "https://t.me/#{ApplicationConfig.platform_bot_username}?start=#{@token}"
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

    private

    def require_admin!
      return if current_user_can_manage_members?

      redirect_to tenant_root_path, alert: 'У вас нет прав для управления участниками'
    end
  end
end
