# frozen_string_literal: true

module Admin
  class TenantInvitesController < Admin::ApplicationController
    # Administrate автоматически обрабатывает index/show
    # Мы переопределяем new/create для автоустановки invited_by_admin

    def new
      resource = TenantInvite.new(tenant_id: params[:tenant_id])
      render locals: {
        page: Administrate::Page::Form.new(dashboard, resource)
      }
    end

    def create
      resource = TenantInvite.new(resource_params)
      resource.invited_by_admin = current_admin_user
      resource.expires_at = ApplicationConfig.tenant_invite_expiration_days.days.from_now

      if resource.save
        redirect_to(
          [:admin, resource],
          notice: translate_with_resource('create.success')
        )
      else
        render :new, locals: {
          page: Administrate::Page::Form.new(dashboard, resource)
        }, status: :unprocessable_entity
      end
    end

    # Отмена приглашения вместо удаления
    def destroy
      requested_resource.cancel!

      redirect_to(
        [:admin, :tenant_invites],
        notice: t('admin.tenant_invites.destroy.success', default: 'Приглашение отменено')
      )
    end

    private

    def resource_params
      params.require(:tenant_invite).permit(:tenant_id, :role)
    end
  end
end
