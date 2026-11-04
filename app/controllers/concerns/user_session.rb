# frozen_string_literal: true

module UserSession
  extend ActiveSupport::Concern

  private

  def current_user
    return @current_user if defined?(@current_user)

    user = User.find_by(id: session[:user_id])
    if user && user.session_version != session[:user_session_version].to_i
      reset_session
      user = nil
    end
    @current_user = user
  end

  def sign_in_user(user)
    reset_session
    session[:user_id] = user.id
    session[:user_session_version] = user.session_version
    @current_user = user
  end
end
