# frozen_string_literal: true

module Tenants
  class AccountPasswordsController < ApplicationController
    rate_limit to: 10, within: 10.minutes, only: :update,
               with: -> { redirect_to edit_tenant_account_password_path, alert: 'Слишком много попыток. Попробуйте позже.' }

    def edit; end

    def update
      user = current_user
      user.with_lock do
        if user.password_digest.present? && !user.authenticate(params[:current_password].to_s)
          @errors = [ 'Текущий пароль указан неверно.' ]
        elsif params[:password].blank? || params[:password_confirmation].blank?
          @errors = [ 'Укажите новый пароль и повторите его.' ]
        elsif user.update(password: params[:password], password_confirmation: params[:password_confirmation])
          sign_in_user(user)
          redirect_to edit_tenant_account_password_path, notice: 'Пароль изменён. Остальные сессии закрыты.'
          return
        else
          @errors = user.errors.full_messages
        end
        render :edit, status: :unprocessable_entity
      end
    end
  end
end
