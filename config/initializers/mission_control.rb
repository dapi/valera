# frozen_string_literal: true

# Mission Control Jobs configuration
# Web UI for SolidQueue/ActiveJob monitoring
# https://github.com/rails/mission_control-jobs

Rails.application.configure do
  # Disable default HTTP Basic Authentication
  # We use Admin::ApplicationController session-based auth instead
  config.mission_control.jobs.http_basic_auth_enabled = false

  # Use Admin::ApplicationController for authentication
  # This inherits session-based authentication from Administrate
  config.mission_control.jobs.base_controller_class = 'Admin::ApplicationController'
end
