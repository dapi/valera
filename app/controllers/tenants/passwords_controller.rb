# frozen_string_literal: true

module Tenants
  # Legacy first-password URLs now require proof of mailbox ownership.
  class PasswordsController < ApplicationController
    skip_before_action :authenticate_user_with_access!

    def new
      redirect_to_email_reset
    end

    def create
      redirect_to_email_reset
    end

    private

    def redirect_to_email_reset
      session.delete(:pending_user_id)
      redirect_to new_password_reset_url(**ApplicationConfig.default_url_options),
                  allow_other_host: true, notice: 'Для установки пароля подтвердите email по ссылке из письма.'
    end
  end
end
