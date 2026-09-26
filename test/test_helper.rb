# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'
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
  # Records one successful LLM call for +chat+ in the RubyLLM usage ledger
  # (ruby_llm_usages). A nil +model+ stands for a model missing from the registry.
  def create_llm_usage(chat:, model:, input_tokens:, output_tokens:)
    RubyLLM::ActiveRecord::Usage.create!(
      chat: chat,
      operation: 'chat',
      status: 'succeeded',
      provider: model&.provider || 'openai',
      model: model&.model_id || 'model-missing-from-registry',
      input_tokens: input_tokens,
      output_tokens: output_tokens
    )
  end
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
