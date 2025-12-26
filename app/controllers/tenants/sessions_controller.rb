# frozen_string_literal: true

module Tenants
  # Handles tenant user authentication.
  # Allows owner or any tenant member to login with email + password.
  #
  class SessionsController < ApplicationController
    skip_before_action :authenticate_user_with_access!
    layout 'tenants/auth'

    # GET /session/new
    def new
      @email = params[:email]
    end

    # POST /session
    def create
      user = find_user_by_email

      unless user
        flash.now[:alert] = I18n.t('tenants.sessions.create.invalid_credentials')
        render :new, status: :unprocessable_entity
        return
      end

      unless user_has_access?(user)
        flash.now[:alert] = I18n.t('tenants.sessions.create.no_access')
        render :new, status: :unprocessable_entity
        return
      end

      if user.password_digest.nil?
        session[:pending_user_id] = user.id
        redirect_to new_tenant_password_path
        return
      end

      if user.authenticate(params[:password])
        session[:user_id] = user.id
        redirect_to tenant_root_path, notice: I18n.t('tenants.sessions.create.success')
      else
        flash.now[:alert] = I18n.t('tenants.sessions.create.invalid_credentials')
        render :new, status: :unprocessable_entity
      end
    end

    # DELETE /session
    def destroy
      session.delete(:user_id)
      redirect_to new_tenant_session_path, notice: I18n.t('tenants.sessions.destroy.success')
    end

    private

    def find_user_by_email
      email = params[:email]&.downcase&.strip
      return nil if email.blank?

      User.find_by(email:)
    end

    def user_has_access?(user)
      current_tenant.owner_id == user.id || current_tenant.members.exists?(user.id)
    end
  end
end
