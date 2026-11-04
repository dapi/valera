# frozen_string_literal: true

class InvitationsController < AccountAccessController
  before_action :set_invite, only: %i[email send_email confirm create]
  before_action :require_email_verification, only: %i[confirm create]
  rate_limit to: 5, within: 10.minutes, only: :send_email,
             with: -> { redirect_to invitations_email_path, alert: 'Слишком много запросов. Попробуйте позже.' }

  def index; end

  def open
    invite = TenantInvite.active.find_by(token: params[:token].to_s)
    unless invite
      redirect_to login_path, alert: 'Приглашение недействительно или уже использовано.'
      return
    end
    session.delete(:invite_email_verification)
    session[:tenant_invite_id] = invite.id
    redirect_to invitations_email_path
  end

  def email; end

  def send_email
    recipient = params[:email].to_s.strip.downcase
    if (@invite.email.present? && @invite.email != recipient) ||
       !ValidEmail2::Address.new(recipient).valid?
      flash.now[:alert] = 'Укажите корректный email, для которого создано приглашение.'
      render :email, status: :unprocessable_entity
      return
    end
    AccountMailer.invitation(@invite, recipient).deliver_later
    redirect_to invitations_email_path, notice: 'Отправили письмо. Откройте ссылку из него для подтверждения email.'
  end

  def accept; end

  def verify
    data = TenantInvite.verify_email_token(params[:token])
    invite = TenantInvite.active.find_by(id: data&.fetch(:invite_id, nil))
    unless invite && (invite.email.blank? || invite.email == data[:email])
      redirect_to login_path, alert: 'Ссылка недействительна или устарела.'
      return
    end
    session[:tenant_invite_id] = invite.id
    session[:invite_email_verification] = { email: data[:email], expires_at: 30.minutes.from_now.to_i }
    redirect_to invitations_confirm_path
  end

  def confirm
    @existing_user = User.find_by(email: verified_email)
  end

  def create
    user = TenantInvitationAcceptance.call(
      invite: @invite, email: verified_email, name: params[:name], password: params[:password],
      password_confirmation: params[:password_confirmation], current_user: current_user
    )
    sign_in_user(user)
    redirect_to select_tenant_path, notice: 'Приглашение принято. Доступ к аккаунту открыт.'
  rescue TenantInvitationAcceptance::Invalid, ActiveRecord::RecordInvalid => e
    @existing_user = User.find_by(email: verified_email)
    @errors = e.is_a?(ActiveRecord::RecordInvalid) ? e.record.errors.full_messages : [ e.message ]
    render :confirm, status: :unprocessable_entity
  rescue ActiveRecord::RecordNotUnique
    @existing_user = User.find_by(email: verified_email)
    @errors = [ 'Аккаунт уже создан другим запросом. Введите пароль этого аккаунта и повторите попытку.' ]
    render :confirm, status: :unprocessable_entity
  end

  private

  def set_invite
    @invite = TenantInvite.active.find_by(id: session[:tenant_invite_id])
    redirect_to login_path, alert: 'Приглашение недействительно или уже использовано.' unless @invite
  end

  def require_email_verification
    data = session[:invite_email_verification]
    unless data && data['expires_at'].to_i > Time.current.to_i
      redirect_to invitations_email_path, alert: 'Подтвердите email по ссылке из письма.'
    end
  end

  def verified_email
    session[:invite_email_verification].fetch('email')
  end
end
