# frozen_string_literal: true

require 'test_helper'

class SharedAssetsTest < ActiveSupport::TestCase
  setup do
    fallback = ->(_env) { [ 418, { 'content-type' => 'text/plain' }, [ 'application fallback' ] ] }
    @request = Rack::MockRequest.new(SharedAssets::Server.new(
      fallback, root: Rails.root.join('test/fixtures/files/shared_assets'),
      cache_control: 'public, max-age=31536000, immutable'
    ))
  end

  test 'serves an immutable asset absent from the application manifest' do
    response = @request.get('/assets/probe-01234567.css')
    assert_equal 200, response.status
    assert_includes response.body, 'shared asset fixture'
    assert_equal 'text/css', response['content-type']
    assert_equal 'public, max-age=31536000, immutable', response['cache-control']
  end

  test 'supports HEAD and byte ranges' do
    assert_equal '', @request.head('/assets/probe-01234567.css').body
    response = @request.get('/assets/probe-01234567.css', 'HTTP_RANGE' => 'bytes=0-1')
    assert_equal 206, response.status
    assert_equal '/*', response.body
  end

  test 'missing files and non-asset requests reach the application' do
    %w[/login /assets/missing-01234567.css /assets/.manifest.json /assets/../Gemfile /assets/%2e%2e/Gemfile].each do |path|
      assert_equal 418, @request.get(path).status
    end
    assert_equal 418, @request.post('/assets/probe-01234567.css').status
  end
end
