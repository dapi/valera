# VCR with RSpec Integration Example

require 'spec_helper'
require 'vcr'

# Configure VCR for your test suite
VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  c.hook_into :webmock
  c.default_cassette_options = {
    record: :new_episodes,
    match_requests_on: [:method, :uri]
  }
  c.filter_sensitive_data('<API_KEY>') { |interaction|
    interaction.request.headers['Authorization']&.first
  }
end

# Configure RSpec to automatically use VCR
RSpec.configure do |config|
  config.extend VCR::RSpec::Macros
end

# Example 1: Simple VCR usage
describe "External API" do
  it "fetches user data", vcr: true do
    # This will automatically use a cassette named
    # "External_API/fetches_user_data"
    response = Net::HTTP.get_response('api.example.com', '/users/1')

    expect(response.code).to eq('200')
    expect(JSON.parse(response.body)['id']).to eq(1)
  end

  # Example 2: Custom cassette name
  it "fetches user profile", vcr: { cassette_name: 'user_profile' } do
    response = Net::HTTP.get_response('api.example.com', '/users/1/profile')

    expect(response.code).to eq('200')
    expect(JSON.parse(response.body)).to have_key('profile')
  end

  # Example 3: Custom cassette options
  it "creates new user", vcr: {
    cassette_name: 'create_user',
    record: :once,
    match_requests_on: [:method, :uri, :body]
  } do
    uri = URI('api.example.com')
    http = Net::HTTP.new(uri.host, uri.port)

    request = Net::HTTP::Post.new('/users')
    request['Content-Type'] = 'application/json'
    request.body = JSON.generate({ name: 'John Doe', email: 'john@example.com' })

    response = http.request(request)

    expect(response.code).to eq('201')
    expect(JSON.parse(response.body)['id']).to be_present
  end

  # Example 4: Manual VCR usage (when tags aren't suitable)
  it "handles complex request patterns" do
    VCR.use_cassette('complex_requests', record: :new_episodes) do
      # Multiple requests in the same test
      response1 = Net::HTTP.get_response('api.example.com', '/users')
      response2 = Net::HTTP.get_response('api.example.com', '/posts')

      expect(response1.code).to eq('200')
      expect(response2.code).to eq('200')
    end
  end

  # Example 5: Using ERB templates in cassettes
  it "makes authenticated requests", vcr: {
    cassette_name: 'authenticated_requests',
    erb: { api_key: 'test_api_key_12345' }
  } do
    uri = URI('api.example.com')
    http = Net::HTTP.new(uri.host, uri.port)

    request = Net::HTTP::Get.new('/protected')
    request['Authorization'] = "Bearer test_api_key_12345"

    response = http.request(request)
    expect(response.code).to eq('200')
  end
end

# Example 6: Shared VCR configuration
describe "API Tests" do
  before(:each) do
    # Setup that runs before each VCR-enabled test
    @base_url = 'https://api.example.com'
  end

  describe "User endpoints" do
    it "lists users", vcr: true do
      response = Net::HTTP.get_response(URI("#{@base_url}/users"))
      users = JSON.parse(response.body)

      expect(users).to be_an(Array)
      expect(users.first).to have_key('id')
    end

    it "gets single user", vcr: { record: :once } do
      response = Net::HTTP.get_response(URI("#{@base_url}/users/1"))
      user = JSON.parse(response.body)

      expect(user['id']).to eq(1)
      expect(user).to have_key('name')
    end
  end
end

# Example 7: Context with different VCR settings
context "When testing with different record modes" do
  context "with new_episodes mode" do
    it "replays existing and records new requests", vcr: {
      record: :new_episodes,
      cassette_name: 'new_episodes_example'
    } do
      # Will replay if exists, record if new
      response = Net::HTTP.get_response('api.example.com', '/endpoint')
      expect(response.code).to eq('200')
    end
  end

  context "with none mode" do
    it "only replays existing interactions", vcr: {
      record: :none,
      cassette_name: 'none_mode_example'
    } do
      # Will only replay existing, fail if not found
      response = Net::HTTP.get_response('api.example.com', '/cached_endpoint')
      expect(response.code).to eq('200')
    end
  end
end