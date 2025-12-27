# frozen_string_literal: true

# The test environment is used exclusively to run your application's
# test suite. You never need to work with it otherwise. Remember that
# your test database is "scratch space" for the test suite and is wiped
# and recreated between test runs. Don't rely on the data there!

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Configure test LLM settings to avoid errors
  config.valera = {
    llm_provider: 'test',
    llm_model: 'test-model',
    bot_token: 'test_token_12345',
    admin_chat_id: 123_456,
    system_prompt_path: './data/system-prompt.md',
    welcome_message_path: './data/welcome-message.md',
    price_list_path: './data/price.csv',
    company_info_path: './data/company-info.md',
    redis_cache_store_url: 'redis://localhost:6379/2',
    rate_limit_requests: 10,
    rate_limit_period: 60,
    max_history_size: 10
  }

  # While tests run files are not watched, reloading is not necessary.
  config.enable_reloading = false

  # Eager loading loads your entire application. When running a single test locally,
  # this is usually not necessary, and can slow down your test suite. However, it's
  # recommended that you enable it in continuous integration systems to ensure eager
  # loading is working properly before deploying your code.
  config.eager_load = ENV['CI'].present?

  # Configure public file server for tests with cache-control for performance.
  config.public_file_server.headers = { 'cache-control' => 'public, max-age=3600' }

  # Show full error reports.
  config.consider_all_requests_local = true
  config.cache_store = :null_store

  # Render exception templates for rescuable exceptions and raise for other exceptions.
  config.action_dispatch.show_exceptions = :rescuable

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false

  # Store uploaded files on the local file system in a temporary directory.
  config.active_storage.service = :test

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Set host to be used by links generated in mailer templates.
  config.action_mailer.default_url_options = { host: 'example.com' }

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  # Raises error for missing translations.
  # config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names.
  # config.action_view.annotate_rendered_view_with_filenames = true

  # Raise error when a before_action's only/except options reference missing actions.
  config.action_controller.raise_on_missing_callback_actions = true

  # Use test adapter for job assertions (assert_enqueued_with, etc.)
  config.active_job.queue_adapter = :test

  # Force tld_length = 1 for lvh.me subdomain testing
  # This overrides ApplicationConfig.tld_length which may be affected by HOST env var
  config.action_dispatch.tld_length = 1
end
