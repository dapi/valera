# frozen_string_literal: true

class PasswordResetsController < AccountAccessController
  rate_limit to: 5, within: 10.minutes, only: :create,
             with: -> { redirect_to new_password_reset_path, alert: 'Слишком много запросов. Попробуйте позже.' }

  def new; end

  def create
    user = User.find_by(email: params[:email].to_s.strip.downcase)
    AccountMailer.password_reset(user).deliver_later if user
    redirect_to new_password_reset_path,
                notice: 'Если аккаунт с этим email существует, мы отправим ссылку для смены пароля.'
  end

  def edit; end

  def update
    user = User.find_by_password_reset_token(params[:token].to_s)
    unless user
      redirect_to new_password_reset_path, alert: 'Ссылка недействительна или устарела. Запросите новую.'
      return
    end

    user.with_lock do
      unless User.find_by_password_reset_token(params[:token].to_s)&.id == user.id
        redirect_to new_password_reset_path, alert: 'Ссылка уже использована. Запросите новую.'
        return
      end
      user.password = params[:password]
      user.password_confirmation = params[:password_confirmation]
      user.errors.add(:password, 'не может быть пустым') if user.password.blank?
      user.errors.add(:password_confirmation, 'не может быть пустым') if params[:password_confirmation].blank?
      if user.password.present? && params[:password_confirmation].present? && user.save
        reset_session
        redirect_to login_url(**ApplicationConfig.default_url_options),
                    notice: 'Пароль изменён. Войдите с новым паролем.'
      else
        @errors = user.errors.full_messages
        render :edit, status: :unprocessable_entity
      end
    end
  end
end
