# frozen_string_literal: true

class AccountMailer < ApplicationMailer
  def password_reset(user)
    @url = edit_password_reset_url(**ApplicationConfig.default_url_options) +
           "#token=#{ERB::Util.url_encode(user.password_reset_token)}"
    mail(to: user.email, subject: 'Супер Валера — восстановление пароля')
  end

  def invitation(invite, email)
    return unless invite.pending? && invite.expires_at > Time.current

    @invite = invite
    @url = invitations_accept_url(**ApplicationConfig.default_url_options) +
           "#token=#{ERB::Util.url_encode(invite.email_verification_token(email))}"
    mail(to: email, subject: "Супер Валера — приглашение в #{@invite.tenant.name}")
  end
end
