# frozen_string_literal: true

# GoodJob configuration
# https://github.com/bensheldon/good_job
Rails.application.configure do
  # Preserve job records for dashboard analytics
  config.good_job.preserve_job_records = true

  # Don't retry on unhandled errors - let jobs handle their own retries
  config.good_job.retry_on_unhandled_error = false

  # Use ErrorLogger for thread errors (per project conventions)
  config.good_job.on_thread_error = ->(exception) { ErrorLogger.error(exception) }

  # Enable cron jobs in production
  config.good_job.enable_cron = Rails.env.production?

  # Cron jobs (migrated from config/recurring.yml)
  config.good_job.cron = {
    # Clean up finished GoodJob records hourly
    cleanup_finished_jobs: {
      cron: '12 * * * *', # every hour at minute 12
      class: 'GoodJob::CleanupJob',
      description: 'Clear finished GoodJob records'
    }
  }
end

# Use Admin::ApplicationController for authentication in the GoodJob dashboard
# This inherits session-based authentication from Administrate
GoodJob::Engine.middleware.use(ActionDispatch::Cookies)
GoodJob::Engine.middleware.use(ActionDispatch::Session::CookieStore)
