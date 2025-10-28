# Advanced VCR Configuration Examples

require 'vcr'
require 'net/http'

# Advanced VCR configuration with multiple options
VCR.configure do |c|
  # Set cassette storage directory
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'

  # Hook into multiple HTTP libraries
  c.hook_into :webmock, :typhoeus

  # Default cassette options
  c.default_cassette_options = {
    record: :new_episodes,
    match_requests_on: [:method, :uri, :headers],
    allow_unused_http_interactions: false,
    serialize_with: :json
  }

  # Filter sensitive data
  c.filter_sensitive_data('<AUTH_TOKEN>') do |interaction|
    auth_header = interaction.request.headers['Authorization']&.first
    auth_header ? auth_header.gsub(/Bearer\s+/, '') : nil
  end

  c.filter_sensitive_data('<USER_ID>') { |interaction|
    interaction.request.uri.match(/\/users\/(\d+)/)&.captures&.first
  }

  # Custom request filtering
  c.ignore_request do |request|
    request.uri.include?('/health_check') ||
    request.uri.include?('/ping') ||
    request.host == 'localhost'
  end

  c.ignore_hosts 'localhost', '127.0.0.1', '0.0.0.0'

  # Before/after hooks
  c.before_record do |interaction|
    # Modify recorded interactions before saving
    interaction.response.headers.delete('Set-Cookie')
    interaction.response.body.gsub!(/\d{4}-\d{2}-\d{2}/, '<DATE>')
  end

  c.before_playback do |interaction|
    # Modify interactions before playback
    interaction.request.headers['User-Agent'] = ['VCR Test']
  end

  # Tagged hooks for specific cassette types
  c.before_record(:sensitive) do |interaction|
    interaction.filter_sensitive_data('<PASSWORD>', 'secret')
  end

  c.before_playback(:sensitive) do |interaction|
    # Decrypt or modify sensitive data for playback
  end

  # Custom request matchers
  c.register_request_matcher :body_json do |request_1, request_2|
    body_1 = JSON.parse(request_1.body) rescue request_1.body
    body_2 = JSON.parse(request_2.body) rescue request_2.body
    body_1 == body_2
  end

  c.register_request_matcher :custom_auth do |request_1, request_2|
    auth_1 = request_1.headers['Authorization']&.first
    auth_2 = request_2.headers['Authorization']&.first

    # Extract token and compare without Bearer prefix
    token_1 = auth_1&.gsub(/Bearer\s+/, '')
    token_2 = auth_2&.gsub(/Bearer\s+/, '')

    token_1 == token_2
  end

  # Preserve exact body bytes for binary data
  c.preserve_exact_body_bytes { |http_message|
    http_message.headers['Content-Type']&.include?('application/octet-stream')
  }

  # Allow HTTP connections when no cassette is in use
  c.allow_http_connections_when_no_cassette = false

  # Handle requests not matching any cassette
  c.handle_http_connections_when_no_cassette = :raise
end

# Example 1: Advanced cassette usage with multiple options
VCR.use_cassette('complex_api_call',
                 record: :once,
                 match_requests_on: [:method, :uri, :body_json],
                 re_record_interval: 86400,  # Re-record every 24 hours
                 erb: {
                   api_key: 'dynamic_key_123',
                   timestamp: Time.now.to_i
                 },
                 preserve_exact_body_bytes: true,
                 decode_compressed_response: true) do

  uri = URI('https://api.example.com/v2/data')
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true

  request = Net::HTTP::Post.new(uri)
  request['Content-Type'] = 'application/json'
  request['Authorization'] = 'Bearer dynamic_key_123'
  request.body = JSON.generate({
    query: 'test data',
    timestamp: Time.now.to_i
  })

  response = http.request(request)
  puts "Response status: #{response.code}"
  puts "Response body: #{response.body[0..100]}..." if response.body.length > 100
end

# Example 2: Multiple cassettes for complex workflows
VCR.use_cassettes([
  { name: 'authentication', options: { record: :once, tag: :sensitive } },
  { name: 'user_profile', options: { record: :new_episodes } },
  { name: 'user_preferences', options: { match_requests_on: [:custom_auth] } }
]) do

  # Authentication request
  auth_response = Net::HTTP.post_form(
    URI('https://api.example.com/auth'),
    'username' => 'testuser',
    'password' => 'secret'
  )

  # Use token from auth for subsequent requests
  token = JSON.parse(auth_response.body)['token']

  # Get user profile
  profile_uri = URI('https://api.example.com/user/profile')
  profile_request = Net::HTTP::Get.new(profile_uri)
  profile_request['Authorization'] = "Bearer #{token}"
  profile_response = Net::HTTP.start(profile_uri.host, profile_uri.port, use_ssl: true) do |http|
    http.request(profile_request)
  end

  # Get user preferences
  prefs_uri = URI('https://api.example.com/user/preferences')
  prefs_request = Net::HTTP::Get.new(prefs_uri)
  prefs_request['Authorization'] = "Bearer #{token}"
  prefs_response = Net::HTTP.start(prefs_uri.host, prefs_uri.port, use_ssl: true) do |http|
    http.request(prefs_request)
  end

  puts "Auth: #{auth_response.code}, Profile: #{profile_response.code}, Prefs: #{prefs_response.code}"
end

# Example 3: Handling different record modes
def demonstrate_record_modes
  puts "=== Demonstrating different record modes ==="

  # :all mode - always record, never playback
  VCR.use_cassette('always_record', record: :all) do
    response = Net::HTTP.get_response('httpbin.org', '/get')
    puts "All mode - Status: #{response.code} (always recorded)"
  end

  # :none mode - only playback, never record
  VCR.use_cassette('only_playback', record: :none) do
    # This will fail if cassette doesn't exist
    response = Net::HTTP.get_response('httpbin.org', '/ip')
    puts "None mode - Status: #{response.code} (only playback)"
  end

  # :new_episodes mode - playback existing, record new
  VCR.use_cassette('mixed_mode', record: :new_episodes) do
    response1 = Net::HTTP.get_response('httpbin.org', '/uuid')      # Might be new
    response2 = Net::HTTP.get_response('httpbin.org', '/user-agent') # Might exist
    puts "New episodes - UUID: #{response1.code}, User-Agent: #{response2.code}"
  end

  # :once mode - record once, then playback only
  VCR.use_cassette('once_mode', record: :once) do
    response = Net::HTTP.get_response('httpbin.org', '/headers')
    puts "Once mode - Status: #{response.code} (record once, playback forever)"
  end
end

# Example 4: Error handling and debugging
def demonstrate_error_handling
  puts "=== Demonstrating error handling ==="

  # Turn off VCR temporarily for real requests
  VCR.turned_off do
    puts "VCR is off - making real HTTP request"
    response = Net::HTTP.get_response('httpbin.org', '/status/200')
    puts "Real request status: #{response.code}"
  end

  # Check VCR status
  puts "VCR turned on: #{VCR.turned_on?}"
  puts "Current cassette: #{VCR.current_cassette&.name || 'None'}"

  # Try to make request without cassette (will raise error)
  begin
    Net::HTTP.get_response('httpbin.org', '/get')
  rescue VCR::Errors::UnhandledHTTPRequestError => e
    puts "Expected error: #{e.message}"
  end
end

# Example 5: Working with different serializers
def demonstrate_serializers
  puts "=== Demonstrating different serializers ==="

  # JSON serializer
  VCR.use_cassette('json_example', serialize_with: :json) do
    response = Net::HTTP.get_response('httpbin.org', '/json')
    puts "JSON cassette - Status: #{response.code}"
  end

  # YAML serializer (default)
  VCR.use_cassette('yaml_example', serialize_with: :yaml) do
    response = Net::HTTP.get_response('httpbin.org', '/xml')
    puts "YAML cassette - Status: #{response.code}"
  end
end

# Run demonstrations if this file is executed directly
if __FILE__ == $0
  demonstrate_record_modes
  demonstrate_error_handling
  demonstrate_serializers
end