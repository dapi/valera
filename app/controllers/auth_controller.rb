# frozen_string_literal: true

# Универсальный контроллер авторизации для главного домена
#
# Позволяет пользователям авторизоваться на главном домене и затем
# выбрать tenant для перехода. Используется cross-domain авторизация
# через подписанные токены.
#
# @author Danil Pismenny
# @since 0.4.0
class AuthController < ApplicationController
  layout 'landing'

  before_action :redirect_if_logged_in, only: %i[new create telegram_login]
  before_action :require_login, only: %i[select switch_tenant]

  # GET /login
  def new; end

  # POST /login
  def create
    user = User.find_by(email: params[:email])

    if user&.authenticate(params[:password])
      reset_session
      session[:user_id] = user.id
      redirect_after_login(user)
    else
      flash.now[:alert] = I18n.t('auth.create.invalid_credentials')
      render :new, status: :unprocessable_entity
    end
  end

  # DELETE /logout
  def destroy
    session.delete(:user_id)
    redirect_to root_path, notice: I18n.t('auth.destroy.success')
  end

  # GET /login/select
  def select
    @tenants = current_user.accessible_tenants
  end

  # POST /login/select
  def switch_tenant
    tenant = current_user.accessible_tenants.find { |t| t.key == params[:tenant_key] }
    raise ActiveRecord::RecordNotFound unless tenant
    token = generate_cross_domain_token(current_user, tenant)
    redirect_to tenant_auth_token_url(subdomain: tenant.key, t: token), allow_other_host: true
  rescue ActiveRecord::RecordNotFound
    redirect_to select_tenant_path, alert: I18n.t('auth.switch_tenant.not_found')
  end

  # GET /login/telegram
  def telegram_login
    auth_key = TelegramAuthService.new.create_global_auth_request(
      return_url: login_telegram_callback_url
    )

    bot_url = "https://t.me/#{ApplicationConfig.platform_bot_username}?start=#{auth_key}"
    redirect_to bot_url, allow_other_host: true
  end

  # GET /login/telegram/callback
  def telegram_callback
    data = TelegramAuthService.new.verify_global_confirm_token(params[:token].to_s)

    unless data
      redirect_to login_path, alert: I18n.t('auth.telegram_callback.invalid_token')
      return
    end

    telegram_user = TelegramUser.find_by(id: data[:telegram_user_id])
    user = User.find_by(telegram_user_id: telegram_user&.id)

    if user
      reset_session
      session[:user_id] = user.id
      redirect_after_login(user)
    else
      redirect_to login_path, alert: I18n.t('auth.telegram_callback.not_linked')
    end
  end

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end
  helper_method :current_user

  def logged_in?
    current_user.present?
  end
  helper_method :logged_in?

  def redirect_if_logged_in
    redirect_to select_tenant_path if logged_in?
  end

  def require_login
    redirect_to login_path, alert: I18n.t('auth.require_login') unless logged_in?
  end

  def redirect_after_login(user)
    tenants = user.accessible_tenants

    case tenants.count
    when 0
      redirect_to login_path, alert: I18n.t('auth.redirect_after_login.no_tenants')
    when 1
      switch_to_tenant(tenants.first)
    else
      redirect_to select_tenant_path
    end
  end

  def switch_to_tenant(tenant)
    token = generate_cross_domain_token(current_user, tenant)
    redirect_to tenant_auth_token_url(subdomain: tenant.key, t: token), allow_other_host: true
  end

  def generate_cross_domain_token(user, tenant)
    Rails.application.message_verifier(:cross_auth).generate(
      { user_id: user.id, tenant_key: tenant.key, exp: 5.minutes.from_now.to_i },
      expires_in: 5.minutes
    )
  end
end
