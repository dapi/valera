# frozen_string_literal: true

module PasswordLoginRateLimit
  extend ActiveSupport::Concern

  included do
    rate_limit to: ApplicationConfig.login_ip_attempts, within: ApplicationConfig.login_window_seconds.seconds,
               scope: 'password-login', name: 'ip', only: :create, with: :login_rate_limited
    rate_limit to: ApplicationConfig.login_account_attempts, within: ApplicationConfig.login_window_seconds.seconds,
               scope: 'password-login', name: 'account', only: :create, with: :login_rate_limited,
               by: -> { Digest::SHA256.hexdigest(params[:email].to_s.strip.downcase) }
  end

  private

  def login_rate_limited
    response.set_header('Retry-After', ApplicationConfig.login_window_seconds.to_s)
    render plain: 'Слишком много попыток входа. Попробуйте позже.', status: :too_many_requests
  end
end
