# frozen_string_literal: true

# GoodJob configuration
# https://github.com/bensheldon/good_job
Rails.application.configure do
  # Preserve job records for dashboard analytics
  config.good_job.preserve_job_records = true

  # Don't retry on unhandled errors - let jobs handle their own retries
  config.good_job.retry_on_unhandled_error = false

  # Use ErrorLogger for thread errors (per project conventions)
  config.good_job.on_thread_error = ->(exception) { ErrorLogger.log_error_with_backtrace(exception) }

  # Automatic cleanup of finished job records
  # Replaces the cron job from config/recurring.yml
  config.good_job.cleanup_preserved_jobs_before_seconds_ago = 14.days.to_i
  config.good_job.cleanup_interval_seconds = 1.hour.to_i

  # Cron-style scheduled jobs
  config.good_job.cron = {
    # Классификация неактивных чатов каждый час
    classify_inactive_chats: {
      cron: '0 * * * *', # каждый час в 0 минут
      class: 'ClassifyInactiveChatsJob',
      description: 'Classify inactive chats by topic using LLM'
    }
  }
end

# GoodJob Dashboard authentication
# Require admin session to access the dashboard (same as Administrate)
GoodJob::Engine.middleware.use(ActionDispatch::Cookies)
GoodJob::Engine.middleware.use(ActionDispatch::Session::CookieStore)

ActiveSupport.on_load(:good_job_application_controller) do
  before_action do
    unless session[:admin_user_id]
      raise ActionController::RoutingError, 'Not Found'
    end
  end
end
