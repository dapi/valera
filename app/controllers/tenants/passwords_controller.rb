# frozen_string_literal: true

module Tenants
  # Handles first-time password setup for tenant owners.
  # Used when owner has no password_digest set.
  #
  class PasswordsController < ApplicationController
    skip_before_action :authenticate_owner!
    before_action :require_pending_user!
    layout 'tenants/auth'

    # GET /password/new
    def new
      @user = User.find(session[:pending_user_id])
    end

    # POST /password
    def create
      @user = User.find(session[:pending_user_id])

      if @user.update(password_params)
        session.delete(:pending_user_id)
        session[:user_id] = @user.id
        redirect_to tenant_root_path, notice: I18n.t('tenants.passwords.set_success')
      else
        render :new, status: :unprocessable_entity
      end
    end

    private

    def require_pending_user!
      return if session[:pending_user_id].present?

      redirect_to new_tenant_session_path
    end

    def password_params
      params.require(:user).permit(:password, :password_confirmation)
    end
  end
end
