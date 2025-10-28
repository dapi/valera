# VCR Gem API Reference

## Core Module Methods

### VCR.configure

Configures VCR with a block.

```ruby
VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  c.hook_into :webmock
  c.default_cassette_options = { record: :new_episodes }
end
```

### VCR.use_cassette

The primary method for using VCR. Inserts a cassette, runs a block, and ejects the cassette.

```ruby
VCR.use_cassette('twitter') do
  # make HTTP requests here
  response = Net::HTTP.get_response('api.twitter.com', '/1.1/statuses/user_timeline.json')
end
```

**Parameters:**
- `name` (String) - Name of the cassette
- `options` (Hash) - Cassette options
- `block` (Proc) - Code to execute while cassette is active

### VCR.insert_cassette / VCR.eject_cassette

Manual cassette control for when you can't use a block.

```ruby
VCR.insert_cassette('github', record: :new_episodes)
# make HTTP requests
VCR.eject_cassette
```

### VCR.current_cassette

Returns the currently active cassette.

```ruby
VCR.current_cassette.name #=> "twitter"
```

### VCR.turned_on? / VCR.turned_off?

Check if VCR is currently enabled.

```ruby
VCR.turned_on?  #=> true
VCR.turned_off? #=> false
```

## Configuration Options

### Cassette Storage

```ruby
VCR.configure do |c|
  c.cassette_library_dir = 'spec/cassettes'  # Directory for cassette files
end
```

### HTTP Library Hooks

```ruby
VCR.configure do |c|
  c.hook_into :webmock        # or :typhoeus, :excon, :faraday
  c.hook_into :webmock, :typhoeus  # multiple libraries
end
```

### Default Cassette Options

```ruby
VCR.configure do |c|
  c.default_cassette_options = {
    record: :new_episodes,
    match_requests_on: [:method, :uri],
    allow_unused_http_interactions: true
  }
end
```

### Request Filtering

```ruby
VCR.configure do |c|
  c.ignore_hosts 'localhost', '127.0.0.1'
  c.ignore_localhost = true
  c.ignore_request { |request| request.uri.include? '/api/internal' }
end
```

### Filter Sensitive Data

```ruby
VCR.configure do |c|
  c.filter_sensitive_data('<GITHUB_TOKEN>') { |interaction|
    interaction.request.headers['Authorization'].first
  }

  c.define_cassette_placeholder('<RANDOM_ID>') { '123' }
  c.before_record { |interaction|
    interaction.response.body.gsub!(/\d{10}/, '<TIMESTAMP>')
  }
end
```

## Cassette Options

### Record Modes

- `:all` - Record all HTTP interactions, no playback
- `:none` - Do not record any new interactions, only playback
- `:new_episodes` - Playback existing interactions, record new ones
- `:once` - Record if cassette doesn't exist, otherwise playback only

```ruby
VCR.use_cassette('api', record: :once) do
  # HTTP requests
end
```

### Request Matching

Control how incoming requests are matched to recorded interactions.

```ruby
VCR.use_cassette('api', match_requests_on: [:method, :uri, :body]) do
  # requests will match on method, URI, and body
end

# Built-in matchers: :method, :uri, :host, :path, :headers, :body
```

### Custom Request Matchers

```ruby
VCR.configure do |c|
  c.register_request_matcher :custom_matcher do |request_1, request_2|
    request_1.headers['Custom-Header'] == request_2.headers['Custom-Header']
  end
end

VCR.use_cassette('api', match_requests_on: [:method, :uri, :custom_matcher]) do
  # requests will match using custom matcher
end
```

### ERB Templates

Use ERB in cassette files for dynamic content.

```ruby
VCR.use_cassette('api', erb: { token: 'dynamic_token' }) do
  # cassette file can use <%= token %>
end
```

### Serialization Options

```ruby
VCR.use_cassette('api', serialize_with: :json) do
  # use JSON instead of YAML
end

# Valid serializers: :yaml, :json, :psych, :syck
```

### Re-record Intervals

Automatically re-record cassettes at intervals.

```ruby
VCR.use_cassette('api', re_record_interval: 86400) do
  # re-record every 24 hours
end
```

## Debugging and Advanced Options

### Allow Unused HTTP Interactions

```ruby
VCR.use_cassette('api', allow_unused_http_interactions: false) do
  # will raise error if not all recorded interactions are used
end
```

### Playback Repeats

```ruby
VCR.use_cassette('api', allow_playback_repeats: true) do
  # allow same interaction to be played multiple times
end
```

### Preserve Exact Body Bytes

```ruby
VCR.use_cassette('api', preserve_exact_body_bytes: true) do
  # preserve binary data exactly
end
```

### Decompress Responses

```ruby
VCR.use_cassette('api', decode_compressed_response: true) do
  # store decompressed response bodies for readability
end
```

## Library Hooks

### WebMock Integration

```ruby
VCR.configure do |c|
  c.hook_into :webmock
end
```

### Multiple Library Support

```ruby
VCR.configure do |c|
  c.hook_into :webmock, :typhoeus
end
```

## Testing Framework Integration

### RSpec Integration

```ruby
RSpec.configure do |c|
  c.extend VCR::RSpec::Macros
end

# In your specs:
describe "API", vcr: true do
  it "makes a request" do
    # automatically uses cassette named from example description
  end

  it "uses custom cassette", vcr: { cassette_name: 'custom' } do
    # uses custom cassette name
  end
end
```

### Manual RSpec Usage

```ruby
describe "API" do
  it "makes a request with VCR" do
    VCR.use_cassette('api_request') do
      # make HTTP request
    end
  end
end
```

## Error Handling

### Common Errors

- `VCR::Errors::CassetteInUseError` - Trying to turn off VCR while cassette is in use
- `VCR::Errors::TurnedOffError` - Inserting cassette when VCR is turned off
- `VCR::Errors::MissingERBVariableError` - ERB template requires undefined variable
- `VCR::Errors::UnhandledHTTPRequestError` - HTTP request made without matching cassette

### Turning VCR Off/On

```ruby
# Turn off temporarily
VCR.turned_off do
  # make real HTTP requests
end

# Turn off completely
VCR.turn_off!
# make requests
VCR.turn_on!

# Turn off but ignore cassette insertions
VCR.turn_off!(ignore_cassettes: true)
```