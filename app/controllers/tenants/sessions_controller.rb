# frozen_string_literal: true

module Tenants
  # Handles tenant owner authentication.
  # Shows owner email (readonly) and requires only password input.
  #
  class SessionsController < ApplicationController
    skip_before_action :authenticate_user_with_access!
    layout 'tenants/auth'

    # GET /session/new
    def new
      @owner = current_tenant.owner
    end

    # POST /session
    def create
      owner = current_tenant.owner

      if owner.nil?
        flash.now[:alert] = I18n.t('tenants.sessions.create.no_owner')
        render :new, status: :unprocessable_entity
        return
      end

      if owner.password_digest.nil?
        # First login - redirect to set password
        session[:pending_user_id] = owner.id
        redirect_to new_tenant_password_path
        return
      end

      if owner.authenticate(params[:password])
        session[:user_id] = owner.id
        redirect_to tenant_root_path, notice: I18n.t('tenants.sessions.create.success')
      else
        flash.now[:alert] = I18n.t('tenants.sessions.create.invalid_password')
        render :new, status: :unprocessable_entity
      end
    end

    # DELETE /session
    def destroy
      session.delete(:user_id)
      redirect_to new_tenant_session_path, notice: I18n.t('tenants.sessions.destroy.success')
    end
  end
end
