# frozen_string_literal: true

module Tenants
  # Контроллер для управления сотрудниками tenant'а
  #
  # Все члены команды могут просматривать список сотрудников (index).
  # Owner и admin могут приглашать новых сотрудников,
  # управлять существующими членами команды и изменять их роли.
  class MembersController < ApplicationController
    before_action :require_admin!, except: [ :index ]
    before_action :set_membership, only: %i[update destroy]

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
        email: params[:email].presence,
        role: role,
        expires_at: 7.days.from_now
      )

      AccountMailer.invitation(invite, invite.email).deliver_later if invite.email.present?
      redirect_to invite_tenant_members_path(id: invite.id)
    rescue ActiveRecord::RecordInvalid => e
      redirect_to tenant_members_path, alert: e.record.errors.full_messages.to_sentence
    end

    # GET /members/invite
    def invite
      @invite = if params[:id].present?
        current_tenant.tenant_invites.active.find_by(id: params[:id])
      else
        current_tenant.tenant_invites.active.find_by(token: params[:token])
      end
      unless @invite
        redirect_to tenant_members_path, alert: 'Приглашение недействительно или уже использовано.'
        return
      end
      @role = @invite.role
      @invite_url = @invite.web_url
    end

    # PATCH /members/:id
    def update
      new_role = params[:role]

      unless TenantMembership.roles.key?(new_role)
        redirect_to tenant_members_path, alert: t('.invalid_role')
        return
      end

      if @membership.update(role: new_role)
        redirect_to tenant_members_path, notice: t('.role_updated', name: @membership.user.name, role: t(".roles.#{new_role}"))
      else
        redirect_to tenant_members_path, alert: t('.update_failed')
      end
    end

    # DELETE /members/:id
    def destroy
      if @membership.destroy
        redirect_to tenant_members_path, notice: t('.member_removed')
      else
        redirect_to tenant_members_path, alert: t('.remove_failed')
      end
    end

    # DELETE /members/invites/:id
    def cancel_invite
      invite = current_tenant.tenant_invites.pending.find(params[:id])
      invite.cancel!
      redirect_to tenant_members_path, notice: 'Приглашение отменено'
    end

    private

    def set_membership
      @membership = current_tenant.tenant_memberships.find(params[:id])
    end

    def require_admin!
      return if current_user_can_manage_members?

      redirect_to tenant_root_path, alert: t('tenants.members.access_denied')
    end
  end
end
