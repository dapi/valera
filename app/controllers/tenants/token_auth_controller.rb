# frozen_string_literal: true

module Tenants
  # Обрабатывает cross-domain авторизацию через подписанные токены
  #
  # Используется для переноса сессии с главного домена на subdomain tenant'а.
  # Токен генерируется AuthController и верифицируется здесь.
  #
  # @author Danil Pismenny
  # @since 0.4.0
  class TokenAuthController < ApplicationController
    skip_before_action :authenticate_owner!

    # GET /auth/token?t=xxx
    def show
      data = verify_token(params[:t])

      unless data
        redirect_to new_tenant_session_path, alert: I18n.t('tenants.token_auth.invalid_token')
        return
      end

      unless data[:tenant_key] == current_tenant.key
        redirect_to new_tenant_session_path, alert: I18n.t('tenants.token_auth.wrong_tenant')
        return
      end

      session[:user_id] = data[:user_id]
      redirect_to tenant_root_path, notice: I18n.t('tenants.token_auth.success')
    end

    private

    def verify_token(token)
      return nil if token.blank?

      data = Rails.application.message_verifier(:cross_auth).verify(token)
      data.symbolize_keys
    rescue ActiveSupport::MessageVerifier::InvalidSignature, ActiveSupport::MessageEncryptor::InvalidMessage
      nil
    end
  end
end
