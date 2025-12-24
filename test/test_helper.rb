# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'
# Override HOST to use lvh.me for subdomain testing (tld_length = 1)
ENV['HOST'] = 'lvh.me'
require_relative '../config/environment'
require 'rails/test_help'

require_relative 'telegram_support'

# Testing dependencies
require 'mocha/minitest'
require 'timecop'

VCR.configure do |config|
  config.cassette_library_dir = 'test/cassettes'
  config.hook_into :webmock
  config.filter_sensitive_data('<BEARER_TOKEN>') do |interaction|
    auths = interaction.request.headers['Authorization'].first
    if (match = auths.match(/^Bearer\s+([^,\s]+)/))
      match.captures.first
    end
  end

  # Ignore Selenium/Capybara requests to localhost for system tests
  config.ignore_localhost = true
end

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Use transactional fixtures for test isolation
    self.use_transactional_tests = true

    # Force eager loading in test environment to fix autoload issues
    setup do
      Rails.application.eager_load!
      Rails.application.config.analytics_enabled = true
    end

    # Helper method для совместимости с тестами
    def perform_enqueued_jobs
      # Для inline adapter задачи выполняются сразу
      # Метод для совместимости с существующими тестами
    end

    # Add more helper methods to be used by all tests here...
  end
end
