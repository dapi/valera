# Basic VCR Usage Example

require 'vcr'
require 'net/http'

# Configure VCR
VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  c.hook_into :webmock
  c.default_cassette_options = { record: :new_episodes }
end

# Basic usage with a cassette
VCR.use_cassette('google_search') do
  # This HTTP request will be recorded the first time
  # and replayed on subsequent runs
  uri = URI('https://www.google.com')
  response = Net::HTTP.get_response(uri)

  puts "Status: #{response.code}"
  puts "Body length: #{response.body.length}"
end

# Using manual cassette control
VCR.insert_cassette('github_user')
begin
  # Make request to GitHub API
  uri = URI('https://api.github.com/users/octocat')
  response = Net::HTTP.get_response(uri)

  puts "GitHub user: #{JSON.parse(response.body)['login']}"
ensure
  VCR.eject_cassette
end

# Checking if VCR is turned on
puts "VCR is turned on: #{VCR.turned_on?}"