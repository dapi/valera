# frozen_string_literal: true

# Mission Control Jobs configuration
# Web UI for SolidQueue/ActiveJob monitoring
# https://github.com/rails/mission_control-jobs

# Disable default HTTP Basic Authentication
# We use Admin::ApplicationController session-based auth instead
MissionControl::Jobs.http_basic_auth_enabled = false

# Use Admin::ApplicationController for authentication
# This inherits session-based authentication from Administrate
MissionControl::Jobs.base_controller_class = 'Admin::ApplicationController'
