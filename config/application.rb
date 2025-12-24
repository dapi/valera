# frozen_string_literal: true

require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Valera
  # Main Rails application configuration class
  class Application < Rails::Application
    # Configure the path for configuration classes that should be used before initialization
    # NOTE: path should be relative to the project root (Rails.root)
    # config.anyway_config.autoload_static_config_path = "config/configs"
    #
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # Set timezone to Moscow (Europe/Moscow) - can be overridden via environment
    config.time_zone = ENV.fetch('TIMEZONE', 'Europe/Moscow')
    # config.eager_load_paths << Rails.root.join("extras")

    # Set default locale to Russian
    config.i18n.default_locale = :ru
    config.i18n.available_locales = [ :ru ]

    # Analytics configuration
    config.analytics_enabled = ENV.fetch('ANALYTICS_ENABLED', 'true') == 'true'

    # Disable ENV loader for test environment to use values from application.yml
    # (ENV variables like HOST from dev environment would override test config)
    Anyway.loaders.delete :env if Rails.env.test?

    # Configure TLD length for subdomain routing
    # For '3010.brandymint.ru' -> tld_length=2 -> subdomain 'admin' (not 'admin.3010')
    config.action_dispatch.tld_length = ApplicationConfig.tld_length

    # Configure default URL options for route helpers and mailers
    Rails.application.routes.default_url_options = ApplicationConfig.default_url_options
  end
end
