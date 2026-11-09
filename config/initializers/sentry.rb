# frozen_string_literal: true

Sentry.init do |config|
  config.dsn = ApplicationConfig.sentry_dsn
  config.release = "super-valera@#{AppVersion.format('%M.%m.%p')}"
  config.environment = Rails.env
  config.enabled_environments = %w[production staging]
  # Rails SDK excludes CSRF failures by default; retain them to diagnose login 422s.
  config.excluded_exceptions -= [ 'ActionController::InvalidAuthenticityToken' ]
  config.send_default_pii = false
  config.traces_sample_rate = 0.0
  config.send_modules = false
  config.before_send = lambda do |event, _hint|
    # Error reports must not contain login forms, webhook payloads or session data.
    if event.request
      event.request.data = nil
      event.request.query_string = nil
      event.request.cookies = nil
      event.request.headers = {}
      event.request.env = {}
    end
    event.user = nil
    event.breadcrumbs = nil
    event
  end
end
