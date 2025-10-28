# VCR Testing Patterns Examples

require 'spec_helper'
require 'vcr'

# VCR configuration for comprehensive testing
VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  c.hook_into :webmock
  c.default_cassette_options = {
    record: :once,
    match_requests_on: [:method, :uri]
  }

  # Filter sensitive test data
  c.filter_sensitive_data('<API_TOKEN>') { |interaction|
    interaction.request.headers['Authorization']&.first&.gsub(/Bearer\s+/, '')
  }

  c.filter_sensitive_data('<USER_EMAIL>') { |interaction|
    interaction.request.body.match(/email=([^&]+)/)&.captures&.first
  }
end

RSpec.configure do |config|
  config.extend VCR::RSpec::Macros

  # Global before/after hooks for VCR
  config.before(:suite) do
    # Clean up old cassettes or set up test data
  end

  config.after(:suite) do
    # Cleanup after test suite
  end
end

# Pattern 1: API Integration Testing
describe "API Integration Tests" do
  context "User management" do
    # Create a new cassette for each test scenario
    it "creates a user successfully", vcr: {
      cassette_name: 'users/create_success',
      record: :once
    } do
      user_data = {
        name: 'John Doe',
        email: 'john@example.com',
        password: 'securepassword'
      }

      response = UserService.create(user_data)

      expect(response).to be_success
      expect(response.user.name).to eq('John Doe')
      expect(response.user.email).to eq('john@example.com')
    end

    it "handles duplicate email error", vcr: {
      cassette_name: 'users/create_duplicate_email',
      record: :once
    } do
      user_data = {
        name: 'Jane Doe',
        email: 'existing@example.com',  # This email already exists
        password: 'securepassword'
      }

      response = UserService.create(user_data)

      expect(response).not_to be_success
      expect(response.errors).to include('Email already taken')
    end

    it "validates required fields", vcr: {
      cassette_name: 'users/create_validation_error',
      record: :once
    } do
      user_data = {
        name: '',  # Empty name should fail validation
        email: 'invalid-email',  # Invalid email format
        password: '123'  # Password too short
      }

      response = UserService.create(user_data)

      expect(response).not_to be_success
      expect(response.errors).to include('Name is required', 'Email is invalid', 'Password is too short')
    end
  end
end

# Pattern 2: Workflow Testing with Multiple Cassettes
describe "User Registration Workflow" do
  it "completes full registration process" do
    VCR.use_cassette('registration/step1_account_creation', record: :once) do
      # Step 1: Create account
      @user = UserService.create({
        name: 'Test User',
        email: 'test@example.com',
        password: 'password123'
      })
      expect(@user).to be_success
    end

    VCR.use_cassette('registration/step2_email_verification', record: :once) do
      # Step 2: Send verification email
      verification_response = EmailService.send_verification(@user.user)
      expect(verification_response).to be_success
    end

    VCR.use_cassette('registration/step3_profile_setup', record: :once) do
      # Step 3: Complete profile
      profile_response = ProfileService.update(@user.user.id, {
        bio: 'Software Developer',
        location: 'San Francisco',
        preferences: { newsletter: true }
      })
      expect(profile_response).to be_success
    end

    # Verify final state
    expect(@user.user.verified?).to be_falsey  # Still needs email verification
    expect(@user.user.profile).to be_present
  end
end

# Pattern 3: Error Scenario Testing
describe "Error Handling" do
  context "Network and server errors" do
    it "handles timeout gracefully", vcr: {
      cassette_name: 'errors/timeout',
      record: :once
    } do
      expect {
        SlowService.call_with_timeout(1.second)
      }.to raise_error(Service::TimeoutError)
    end

    it "handles 500 server error", vcr: {
      cassette_name: 'errors/server_error',
      record: :once
    } do
      response = UnreliableService.get_data

      expect(response).not_to be_success
      expect(response.error_type).to eq('server_error')
      expect(response.status_code).to eq(500)
    end

    it "handles rate limiting", vcr: {
      cassette_name: 'errors/rate_limited',
      record: :once
    } do
      # Make multiple rapid requests to trigger rate limiting
      responses = []
      5.times do
        responses.push(RateLimitedService.get_data)
      end

      expect(responses.last.status_code).to eq(429)
      expect(responses.last.error_type).to eq('rate_limited')
    end
  end
end

# Pattern 4: Data-Driven Testing with VCR
describe "Data-Driven API Tests" do
  # Test multiple endpoints with similar structure
  [
    { endpoint: '/users', expected_fields: ['id', 'name', 'email'] },
    { endpoint: '/posts', expected_fields: ['id', 'title', 'content', 'author_id'] },
    { endpoint: '/comments', expected_fields: ['id', 'content', 'post_id', 'user_id'] }
  ].each do |test_case|
    it "returns correct structure for #{test_case[:endpoint]}", vcr: {
      cassette_name: "endpoints#{test_case[:endpoint].gsub('/', '_')}",
      record: :once
    } do
      response = ApiService.get(test_case[:endpoint])

      expect(response).to be_success

      if response.data.is_a?(Array)
        response.data.each do |item|
          test_case[:expected_fields].each do |field|
            expect(item).to have_key(field)
          end
        end
      else
        test_case[:expected_fields].each do |field|
          expect(response.data).to have_key(field)
        end
      end
    end
  end
end

# Pattern 5: Mock Real-World Scenarios
describe "Real-World Scenarios" do
  it "handles slow network conditions", vcr: {
    cassette_name: 'scenarios/slow_network',
    record: :once
  } do
    start_time = Time.now

    response = SlowApiService.process_large_request

    elapsed_time = Time.now - start_time
    expect(elapsed_time).to be > 2.seconds  # Simulate slow network
    expect(response).to be_success
  end

  it "handles concurrent requests", vcr: {
    cassette_name: 'scenarios/concurrent_requests',
    record: :once
  } do
    # Simulate multiple concurrent API calls
    threads = []
    results = []

    5.times do |i|
      threads << Thread.new do
        result = ApiService.get_data_by_id(i + 1)
        results << result
      end
    end

    threads.each(&:join)

    expect(results).to all(be_success)
    expect(results.map(&:data_id)).to contain_exactly(1, 2, 3, 4, 5)
  end
end

# Pattern 6: Testing Different Authentication Methods
describe "Authentication Methods" do
  it "works with API key authentication", vcr: {
    cassette_name: 'auth/api_key',
    record: :once,
    erb: { api_key: 'test_api_key_123' }
  } do
    service = ApiKeyService.new('test_api_key_123')
    response = service.get_protected_data

    expect(response).to be_success
    expect(response.user_authenticated?).to be_truthy
  end

  it "works with OAuth token authentication", vcr: {
    cassette_name: 'auth/oauth_token',
    record: :once,
    erb: { oauth_token: 'oauth_token_456' }
  } do
    service = OAuthService.new('oauth_token_456')
    response = service.get_user_data

    expect(response).to be_success
    expect(response.token_valid?).to be_truthy
  end

  it "handles expired authentication", vcr: {
    cassette_name: 'auth/expired_token',
    record: :once
  } do
    service = OAuthService.new('expired_token_789')

    expect {
      response = service.get_user_data
    }.to raise_error(Service::AuthenticationError)
  end
end

# Pattern 7: Testing API Versioning
describe "API Versioning" do
  %w[v1 v2 v3].each do |version|
    context "API #{version}" do
      it "maintains backward compatibility", vcr: {
        cassette_name: "versions/#{version}/users_list",
        record: :once
      } do
        service = ApiVersionService.new(version)
        response = service.list_users

        expect(response).to be_success

        # Check that essential fields exist in all versions
        response.users.each do |user|
          expect(user).to have_key('id')
          expect(user).to have_key('name')
          expect(user).to have_key('email')
        end
      end

      it "handles version-specific features", vcr: {
        cassette_name: "versions/#{version}/advanced_features",
        record: :once
      } do
        service = ApiVersionService.new(version)
        response = service.get_advanced_features

        expect(response).to be_success

        case version
        when 'v1'
          expect(response.features).to include('basic_search')
        when 'v2'
          expect(response.features).to include('advanced_search', 'filters')
        when 'v3'
          expect(response.features).to include('ml_recommendations', 'real_time_updates')
        end
      end
    end
  end
end

# Pattern 8: Performance Testing with VCR
describe "Performance Testing" do
  it "measures API response times", vcr: {
    cassette_name: 'performance/response_times',
    record: :once
  } do
    measurements = []

    10.times do
      start_time = Time.now
      response = ApiService.get_data
      end_time = Time.now

      measurements << (end_time - start_time)
      expect(response).to be_success
    end

    average_time = measurements.sum / measurements.size
    expect(average_time).to be < 0.5.seconds  # Expect sub-500ms response times
    puts "Average response time: #{average_time.round(3)}s"
  end

  it "tests pagination performance", vcr: {
    cassette_name: 'performance/pagination',
    record: :once
  } do
    total_items = 0
    page_count = 0

    ApiService.paginated_list.each_page do |page|
      total_items += page.items.size
      page_count += 1

      # Performance check: each page should load quickly
      expect(page.load_time).to be < 0.1.seconds
    end

    expect(total_items).to be > 0
    expect(page_count).to be > 1  # Should have multiple pages
  end
end

# Pattern 9: Testing with Dynamic Data
describe "Dynamic Data Testing" do
  it "handles time-based data correctly", vcr: {
    cassette_name: 'dynamic/time_based',
    record: :new_episodes,  # Allow new recordings for time-sensitive data
    erb: { current_date: Date.current.iso8601 }
  } do
    service = TimeBasedService.new
    response = service.get_daily_summary(Date.current)

    expect(response).to be_success
    expect(response.date).to eq(Date.current)
    expect(response.summary).to be_present
  end

  it "works with random test data", vcr: {
    cassette_name: 'dynamic/random_data',
    record: :new_episodes,
    erb: {
      random_seed: rand(1000),
      test_email: "test-#{SecureRandom.hex(4)}@example.com"
    }
  } do
    random_user = {
      name: "Test User #{rand(1000)}",
      email: "test-#{SecureRandom.hex(4)}@example.com"
    }

    response = UserService.create(random_user)
    expect(response).to be_success
  end
end

# Pattern 10: Cleanup and Maintenance Testing
describe "Cassette Maintenance" do
  it "validates cassette completeness", vcr: {
    cassette_name: 'maintenance/completeness_test',
    record: :once,
    allow_unused_http_interactions: false  # Fail if unused interactions exist
  } do
    # This test will fail if the cassette has unused recorded interactions
    response1 = ApiService.get_user(1)
    response2 = ApiService.get_user_posts(1)

    expect(response1).to be_success
    expect(response2).to be_success

    # All recorded interactions should be used
  end

  it "ensures cassette reusability", vcr: {
    cassette_name: 'maintenance/reusability_test',
    record: :none,  # Only playback, no new recording
    match_requests_on: [:method, :uri, :body]
  } do
    # This ensures the cassette exists and can be reused
    response = ApiService.get_standard_data

    expect(response).to be_success
    expect(response.data).to have_key('id')
  end
end