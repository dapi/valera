# frozen_string_literal: true

module Admin
  class SessionsController < ApplicationController
    skip_before_action :authenticate_admin!, only: %i[new create]

    layout 'admin/session'

    def new
    end

    def create
      admin_user = AdminUser.find_by(email: params[:email])

      if admin_user&.authenticate(params[:password])
        reset_session # Prevent session fixation attacks
        session[:admin_user_id] = admin_user.id
        redirect_to admin_root_path, notice: 'Logged in successfully'
      else
        flash.now[:alert] = 'Invalid email or password'
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      session.delete(:admin_user_id)
      redirect_to admin_login_path, notice: 'Logged out successfully'
    end
  end
end
