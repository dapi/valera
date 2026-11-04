# frozen_string_literal: true

class TenantInvitationAcceptance
  class Invalid < StandardError; end

  def self.call(invite:, email:, name:, password:, password_confirmation:, current_user: nil)
    invite.with_lock do
      raise Invalid, 'Приглашение недействительно или уже использовано.' unless invite.pending? && invite.expires_at > Time.current
      raise Invalid, 'Приглашение предназначено для другого email.' if invite.email.present? && invite.email != email

      user = User.find_or_initialize_by(email: email)
      if user.new_record? || user.password_digest.blank?
        if password.blank? || password_confirmation.blank?
          raise Invalid, 'Укажите имя, пароль не короче 8 символов и повторите пароль.'
        end

        user.name = name.presence || user.name
        user.password = password
        user.password_confirmation = password_confirmation
        user.save!
      elsif current_user&.id != user.id && !user.authenticate(password.to_s)
        raise Invalid, 'У этого email уже есть аккаунт. Введите его пароль или восстановите его.'
      end

      unless user.owner_of?(invite.tenant)
        membership = TenantMembership.find_or_initialize_by(tenant: invite.tenant, user: user)
        if membership.new_record?
          membership.role = invite.role
          membership.tenant_invite = invite
          membership.save!
        end
      end
      invite.accept!(user)
      user
    end
  end
end
