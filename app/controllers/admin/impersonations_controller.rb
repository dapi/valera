# frozen_string_literal: true

module Admin
  class ImpersonationsController < Admin::ApplicationController
    before_action :authorize_superuser!
    before_action :set_target_admin_user, only: :create

    def create
      if @target_admin_user == current_admin_user
        redirect_to admin_admin_users_path, alert: t('admin.impersonations.cannot_impersonate_self')
        return
      end

      log_impersonation_start

      session[:original_admin_user_id] = current_admin_user.id
      session[:admin_user_id] = @target_admin_user.id
      Current.admin_user = nil

      redirect_to admin_root_path, notice: t('admin.impersonations.started', name: display_name(@target_admin_user))
    end

    def destroy
      unless impersonating?
        redirect_to admin_root_path, alert: t('admin.impersonations.not_impersonating')
        return
      end

      original_admin_user = AdminUser.find(session[:original_admin_user_id])
      impersonated_user = current_admin_user

      log_impersonation_stop(original_admin_user, impersonated_user)

      session[:admin_user_id] = session[:original_admin_user_id]
      session.delete(:original_admin_user_id)
      Current.admin_user = nil

      redirect_to admin_root_path, notice: t('admin.impersonations.stopped')
    end

    private

    def set_target_admin_user
      @target_admin_user = AdminUser.find(params[:id])
    end

    def impersonating?
      session[:original_admin_user_id].present?
    end

    def display_name(admin_user)
      admin_user.name.presence || admin_user.email
    end

    def log_impersonation_start
      Rails.logger.info(
        "[IMPERSONATION] Superuser #{current_admin_user.email} (ID: #{current_admin_user.id}) " \
        "started impersonating #{@target_admin_user.email} (ID: #{@target_admin_user.id})"
      )
    end

    def log_impersonation_stop(original_user, impersonated_user)
      Rails.logger.info(
        "[IMPERSONATION] Superuser #{original_user.email} (ID: #{original_user.id}) " \
        "stopped impersonating #{impersonated_user.email} (ID: #{impersonated_user.id})"
      )
    end
  end
end
