ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

require_relative './telegram_support'

VCR.configure do |config|
  config.cassette_library_dir = "test/cassettes"
  config.hook_into :webmock
  config.filter_sensitive_data('<BEARER_TOKEN>') { |interaction|
    auths = interaction.request.headers['Authorization'].first
    if (match = auths.match /^Bearer\s+([^,\s]+)/ )
      match.captures.first
    end
  }
end

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Use transactional fixtures for test isolation
    self.use_transactional_tests = true

    # Add more helper methods to be used by all tests here...
  end
end
