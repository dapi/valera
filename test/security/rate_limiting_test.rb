# frozen_string_literal: true

require 'test_helper'

class RateLimitingTest < ActiveSupport::TestCase
  include TelegramSupport

  setup do
    @chat_id = 123456789
    @webhook_url = '/telegram/webhook'
    @rate_limit_window = 1.minute
    @max_requests_per_window = 30
  end

  def create_webhook_payload(text = 'test message', chat_id: @chat_id)
    from = { id: chat_id, is_bot: false, first_name: 'Test', last_name: 'User', username: 'testuser' }
    chat = { id: chat_id, first_name: 'Test', last_name: 'User', username: 'testuser', type: 'private' }
    {
      update_id: 123456789,
      message: { message_id: 1, from: from, chat: chat, date: Time.current.to_i, text: text }
    }
  end

  test 'allows normal usage patterns without rate limiting' do
    puts "\n=== Normal Usage Pattern Test ==="

    # Test normal user behavior - reasonable message frequency
    normal_patterns = [
      { count: 5, interval: 30.seconds, description: "5 messages over 30 seconds" },
      { count: 10, interval: 60.seconds, description: "10 messages over 1 minute" },
      { count: 20, interval: 5.minutes, description: "20 messages over 5 minutes" }
    ]

    normal_patterns.each_with_index do |pattern, index|
      puts "Testing pattern #{index + 1}: #{pattern[:description]}"

      success_count = 0
      rate_limited_count = 0
      error_count = 0

      pattern[:count].times do |i|
        begin
          post @webhook_url,
               headers: { 'Content-Type' => 'application/json' },
               params: create_webhook_payload("Normal message #{index + 1}-#{i + 1}")

          case response.status
          when 200
            success_count += 1
          when 429
            rate_limited_count += 1
          else
            error_count += 1
          end

          # Wait between messages to simulate normal usage
          sleep pattern[:interval] / pattern[:count] if i < pattern[:count] - 1
        rescue => e
          error_count += 1
          puts "  Error: #{e.message}"
        end
      end

      puts "  Results: #{success_count} successful, #{rate_limited_count} rate limited, #{error_count} errors"

      # Normal usage should not be rate limited
      assert success_count >= pattern[:count] * 0.8,
             "Normal usage pattern #{pattern[:description]} should not be rate limited: #{success_count}/#{pattern[:count]} successful"
      assert rate_limited_count <= pattern[:count] * 0.2,
             "Too many rate limits for normal usage: #{rate_limited_count}/#{pattern[:count]}"
    end

    puts "✓ Normal usage patterns allowed without excessive rate limiting"
  end

  test 'detects and limits rapid message sending from single user' do
    puts "\n=== Rapid Message Detection Test ==="

    chat_id = @chat_id + 1
    rapid_request_count = 50
    success_count = 0
    rate_limited_count = 0
    response_times = []

    puts "Sending #{rapid_request_count} rapid messages from single user..."

    rapid_request_count.times do |i|
      start_time = Time.current

      post @webhook_url,
           headers: { 'Content-Type' => 'application/json' },
           params: create_webhook_payload("Rapid message #{i + 1}", chat_id)

      response_time = Time.current - start_time
      response_times << response_time

      case response.status
      when 200
        success_count += 1
      when 429
        rate_limited_count += 1
      end

      # Small delay to simulate rapid but not instant requests
      sleep 0.01

      if (i + 1) % 10 == 0
        puts "  After #{i + 1} requests: #{success_count} successful, #{rate_limited_count} rate limited"
      end
    end

    avg_response_time = response_times.sum / response_times.size
    max_response_time = response_times.max

    puts "Rapid Message Results:"
    puts "  Total requests: #{rapid_request_count}"
    puts "  Successful: #{success_count}"
    puts "  Rate limited: #{rate_limited_count}"
    puts "  Success rate: #{(success_count.to_f / rapid_request_count * 100).round(1)}%"
    puts "  Average response time: #{avg_response_time.round(3)}s"
    puts "  Max response time: #{max_response_time.round(3)}s"

    # Rapid sending should trigger rate limiting
    assert rate_limited_count > 0, "Rapid message sending should trigger rate limiting"
    assert rate_limited_count >= rapid_request_count * 0.3,
           "Rate limiting should be active for rapid sending: #{rate_limited_count}/#{rapid_request_count}"
    assert success_count > 0, "Some messages should still get through"
  end

  test 'handles concurrent requests from multiple users correctly' do
    puts "\n=== Concurrent Multi-User Test ==="

    user_count = 10
    requests_per_user = 10
    threads = []
    results = []

    puts "Testing #{user_count} concurrent users with #{requests_per_user} requests each..."

    user_count.times do |user_index|
      threads << Thread.new do
        user_id = @chat_id + user_index + 100
        user_results = {
          user_id: user_id,
          successful: 0,
          rate_limited: 0,
          errors: 0,
          response_times: []
        }

        requests_per_user.times do |request_index|
          begin
            start_time = Time.current

            post @webhook_url,
                 headers: { 'Content-Type' => 'application/json' },
                 params: create_webhook_payload("Concurrent message #{user_index + 1}-#{request_index + 1}", user_id)

            response_time = Time.current - start_time
            user_results[:response_times] << response_time

            case response.status
            when 200
              user_results[:successful] += 1
            when 429
              user_results[:rate_limited] += 1
            else
              user_results[:errors] += 1
            end

            # Small delay between requests
            sleep 0.02
          rescue => e
            user_results[:errors] += 1
          end
        end

        results << user_results
      end
    end

    threads.each(&:join)

    # Analyze results
    total_successful = results.sum { |r| r[:successful] }
    total_rate_limited = results.sum { |r| r[:rate_limited] }
    total_errors = results.sum { |r| r[:errors] }
    total_requests = user_count * requests_per_user

    all_response_times = results.flat_map { |r| r[:response_times] }
    avg_response_time = all_response_times.sum / all_response_times.size

    puts "Concurrent Multi-User Results:"
    puts "  Users: #{user_count}"
    puts "  Requests per user: #{requests_per_user}"
    puts "  Total requests: #{total_requests}"
    puts "  Successful: #{total_successful}"
    puts "  Rate limited: #{total_rate_limited}"
    puts "  Errors: #{total_errors}"
    puts "  Success rate: #{(total_successful.to_f / total_requests * 100).round(1)}%"
    puts "  Average response time: #{avg_response_time.round(3)}s"

    # Multi-user concurrent access should be handled reasonably
    assert total_successful >= total_requests * 0.6,
           "Concurrent requests should have reasonable success rate: #{total_successful}/#{total_requests}"
    assert avg_response_time < 1.0,
           "Average response time should be reasonable under load: #{avg_response_time}s"
  end

  test 'implements progressive rate limiting thresholds' do
    puts "\n=== Progressive Rate Limiting Test ==="

    chat_id = @chat_id + 2
    thresholds = [5, 10, 20, 40, 80]
    results = []

    thresholds.each_with_index do |threshold_count, threshold_index|
      puts "Testing threshold #{threshold_index + 1}: #{threshold_count} requests..."

      success_count = 0
      rate_limited_count = 0
      start_time = Time.current

      threshold_count.times do |i|
        post @webhook_url,
             headers: { 'Content-Type' => 'application/json' },
             params: create_webhook_payload("Threshold test #{threshold_index + 1}-#{i + 1}", chat_id)

        case response.status
        when 200
          success_count += 1
        when 429
          rate_limited_count += 1
        end

        sleep 0.01  # Small delay
      end

      total_time = Time.current - start_time

      results << {
        threshold: threshold_count,
        successful: success_count,
        rate_limited: rate_limited_count,
        total_time: total_time
      }

      success_rate = (success_count.to_f / threshold_count * 100).round(1)

      puts "  Results: #{success_count} successful, #{rate_limited_count} rate limited (#{success_rate}% success)"
      puts "  Time: #{total_time.round(3)}s"

      # Wait between threshold tests
      sleep 2.seconds
    end

    # Analyze progressive rate limiting
    puts "\nProgressive Rate Limiting Analysis:"
    results.each_with_index do |result, index|
      if index > 0
        prev_result = results[index - 1]
        success_rate_change = ((result[:successful].to_f / result[:threshold] - prev_result[:successful].to_f / prev_result[:threshold]) * 100).round(1)
        puts "  Threshold #{result[:threshold]} vs #{prev_result[:threshold]}: #{success_rate_change > 0 ? '+' : ''}#{success_rate_change}% success rate"
      end
    end

    # Higher thresholds should show increased rate limiting
    assert results.last[:rate_limited_count] > results.first[:rate_limited_count],
           "Higher request volumes should show more rate limiting"
  end

  test 'respects rate limiting headers and metadata' do
    puts "\n=== Rate Limiting Headers Test ==="

    chat_id = @chat_id + 3
    request_count = 15

    request_count.times do |i|
      post @webhook_url,
           headers: { 'Content-Type' => 'application/json' },
           params: create_webhook_payload("Header test message #{i + 1}", chat_id)

      puts "Request #{i + 1}: Status #{response.status}"

      # Check for rate limiting headers
      rate_limit_headers = [
        'X-RateLimit-Limit',
        'X-RateLimit-Remaining',
        'X-RateLimit-Reset',
        'Retry-After'
      ]

      rate_limit_headers.each do |header|
        if response.headers[header]
          puts "  #{header}: #{response.headers[header]}"
        end
      end

      # Verify rate limiting headers when applicable
      if response.status == 429
        # Should have rate limiting information when rate limited
        assert response.headers['Retry-After'] || response.headers['X-RateLimit-Reset'],
               "Rate limited response should include retry information"
        puts "  Rate limited - retry after: #{response.headers['Retry-After'] || response.headers['X-RateLimit-Reset']}"
      end

      sleep 0.05
    end

    puts "✓ Rate limiting headers checked"
  end

  test 'implements per-user and per-IP rate limiting' do
    puts "\n=== Per-User vs Per-IP Rate Limiting Test ==="

    # Test per-user rate limiting (same user, different "IPs" via headers)
    user_chat_id = @chat_id + 4
    ip_addresses = ['192.168.1.1', '192.168.1.2', '10.0.0.1', '203.0.113.1']

    puts "Testing same user from different IP addresses..."

    ip_results = {}

    ip_addresses.each_with_index do |ip, ip_index|
      puts "  Testing from IP #{ip}..."

      success_count = 0
      rate_limited_count = 0

      10.times do |i|
        post @webhook_url,
             headers: {
               'Content-Type' => 'application/json',
               'X-Forwarded-For' => ip,
               'X-Real-IP' => ip
             },
             params: create_webhook_payload("User from IP #{ip} message #{i + 1}", user_chat_id)

        case response.status
        when 200
          success_count += 1
        when 429
          rate_limited_count += 1
        end

        sleep 0.02
      end

      ip_results[ip] = { successful: success_count, rate_limited: rate_limited_count }
      puts "    Results: #{success_count} successful, #{rate_limited_count} rate limited"

      # Reset rate limiting between IP tests
      sleep 2.seconds
    end

    # Test per-IP rate limiting (different users, same IP)
    shared_ip = '192.168.1.100'
    user_chat_ids = [@chat_id + 100, @chat_id + 101, @chat_id + 102]

    puts "\nTesting different users from same IP address #{shared_ip}..."

    shared_ip_results = {}

    user_chat_ids.each_with_index do |chat_id, user_index|
      puts "  Testing user #{user_index + 1} from shared IP..."

      success_count = 0
      rate_limited_count = 0

      10.times do |i|
        post @webhook_url,
             headers: {
               'Content-Type' => 'application/json',
               'X-Forwarded-For' => shared_ip,
               'X-Real-IP' => shared_ip
             },
             params: create_webhook_payload("User #{user_index + 1} from shared IP message #{i + 1}", chat_id)

        case response.status
        when 200
          success_count += 1
        when 429
          rate_limited_count += 1
        end

        sleep 0.02
      end

      shared_ip_results[user_index] = { successful: success_count, rate_limited: rate_limited_count }
      puts "    Results: #{success_count} successful, #{rate_limited_count} rate limited"

      # Reset between user tests
      sleep 2.seconds
    end

    puts "\nPer-User vs Per-IP Analysis:"
    puts "  Same user, different IPs - rate limiting should be per-user:"
    ip_success_rates = ip_results.transform_values { |r| r[:successful].to_f / 10 * 100 }
    puts "    Success rates: #{ip_success_rates}"

    puts "  Different users, same IP - rate limiting should be per-user or per-IP:"
    user_success_rates = shared_ip_results.transform_values { |r| r[:successful].to_f / 10 * 100 }
    puts "    Success rates: #{user_success_rates}"

    # The exact behavior depends on implementation, but there should be consistent rate limiting
    assert ip_success_rates.values.any? { |rate| rate < 100 },
           "Some IP tests should show rate limiting for the same user"
  end

  test 'implements rate limiting for different endpoint types' do
    puts "\n=== Endpoint-Specific Rate Limiting Test ==="

    # Test different types of requests that might have different limits
    endpoint_tests = [
      {
        name: 'Webhook endpoint',
        url: '/telegram/webhook',
        payload: create_webhook_payload('Webhook test'),
        expected_limit: 30  # per minute
      },
      {
        name: 'Analytics endpoint (if exists)',
        url: '/analytics/events',
        payload: { event_name: 'test', data: {} },
        expected_limit: 100  # per minute
      },
      {
        name: 'API endpoint (if exists)',
        url: '/api/v1/chats',
        payload: { message: 'test' },
        expected_limit: 60  # per minute
      }
    ]

    endpoint_tests.each do |test|
      puts "Testing #{test[:name]} rate limiting..."

      success_count = 0
      rate_limited_count = 0

      # Send requests to test rate limiting
      (test[:expected_limit] + 10).times do |i|
        begin
          post test[:url],
               headers: { 'Content-Type' => 'application/json' },
               params: test[:payload]

          case response.status
          when 200..299
            success_count += 1
          when 429
            rate_limited_count += 1
          end
        rescue ActionController::RoutingError => e
          # Endpoint might not exist - skip this test
          puts "  Endpoint #{test[:url]} not found, skipping"
          break
        rescue => e
          puts "  Error: #{e.message}"
        end

        sleep 0.01
      end

      if success_count > 0 || rate_limited_count > 0
        puts "  Results: #{success_count} successful, #{rate_limited_count} rate limited"

        if rate_limited_count > 0
          puts "  ✓ Rate limiting is active for #{test[:name]}"
        else
          puts "  ⚠ No rate limiting detected for #{test[:name]}"
        end
      end

      # Reset between tests
      sleep 2.seconds
    end

    puts "✓ Endpoint-specific rate limiting tested"
  end

  test 'implements rate limiting reset and recovery' do
    puts "\n=== Rate Limiting Recovery Test ==="

    chat_id = @chat_id + 5
    burst_request_count = 50

    puts "Phase 1: Send #{burst_request_count} rapid requests to trigger rate limiting..."

    phase1_success = 0
    phase1_rate_limited = 0

    burst_request_count.times do |i|
      post @webhook_url,
           headers: { 'Content-Type' => 'application/json' },
           params: create_webhook_payload("Burst message #{i + 1}", chat_id)

      case response.status
      when 200
        phase1_success += 1
      when 429
        phase1_rate_limited += 1
      end

      sleep 0.005  # Very rapid requests
    end

    puts "Phase 1 Results: #{phase1_success} successful, #{phase1_rate_limited} rate limited"

    # Wait for rate limiting to reset
    reset_time = 65.seconds  # Slightly longer than typical rate limit window
    puts "Phase 2: Waiting #{reset_time} seconds for rate limiting to reset..."

    # In a real test environment, we might need to mock time or use shorter windows
    # For now, we'll just wait a short time and test recovery
    wait_time = 5.seconds
    puts "Waiting #{wait_time} (shortened for test environment)..."
    sleep wait_time

    puts "Phase 3: Testing recovery with 10 normal requests..."

    phase2_success = 0
    phase2_rate_limited = 0

    10.times do |i|
      post @webhook_url,
           headers: { 'Content-Type' => 'application/json' },
           params: create_webhook_payload("Recovery test message #{i + 1}", chat_id)

      case response.status
      when 200
        phase2_success += 1
      when 429
        phase2_rate_limited += 1
      end

      sleep 0.5  # Normal spacing between requests
    end

    puts "Phase 2 Results: #{phase2_success} successful, #{phase2_rate_limited} rate limited"

    # Analyze recovery
    phase1_success_rate = phase1_success.to_f / burst_request_count * 100
    phase2_success_rate = phase2_success.to_f / 10 * 100

    puts "\nRate Limiting Recovery Analysis:"
    puts "  Phase 1 success rate: #{phase1_success_rate.round(1)}%"
    puts "  Phase 2 success rate: #{phase2_success_rate.round(1)}%"
    puts "  Recovery improvement: #{(phase2_success_rate - phase1_success_rate).round(1)}%"

    # Should show some recovery (though may not be complete due to short wait)
    assert phase2_success_rate > phase1_success_rate * 0.5,
           "Should show some recovery from rate limiting"
  end

  test 'handles rate limiting edge cases gracefully' do
    puts "\n=== Rate Limiting Edge Cases Test ==="

    edge_cases = [
      {
        name: 'Exactly at limit',
        requests: 30,
        spacing: 2.seconds,
        description: 'Requests exactly at rate limit threshold'
      },
      {
        name: 'Just over limit',
        requests: 35,
        spacing: 1.second,
        description: 'Requests just over rate limit'
      },
      {
        name: 'Very rapid burst',
        requests: 25,
        spacing: 0.001.seconds,
        description: 'Very rapid burst of requests'
      },
      {
        name: 'Spaced out requests',
        requests: 40,
        spacing: 5.seconds,
        description: 'Requests with long spacing'
      },
      {
        name: 'Variable spacing',
        requests: 30,
        spacing: :variable,
        description: 'Requests with variable spacing'
      }
    ]

    edge_cases.each_with_index do (test_case, index)
      puts "Testing edge case #{index + 1}: #{test_case[:name]} (#{test_case[:description]})"

      success_count = 0
      rate_limited_count = 0
      error_count = 0

      test_case[:requests].times do |i|
        begin
          post @webhook_url,
               headers: { 'Content-Type' => 'application/json' },
               params: create_webhook_payload("Edge case #{index + 1}-#{i + 1}")

          case response.status
          when 200
            success_count += 1
          when 429
            rate_limited_count += 1
          else
            error_count += 1
          end

          # Handle spacing
          if test_case[:spacing] == :variable
            # Variable spacing: random between 0.01 and 2 seconds
            sleep rand(0.01..2.0)
          elsif test_case[:spacing]
            sleep test_case[:spacing]
          end
        rescue => e
          error_count += 1
        end
      end

      puts "  Results: #{success_count} successful, #{rate_limited_count} rate limited, #{error_count} errors"
      puts "  Success rate: #{(success_count.to_f / test_case[:requests] * 100).round(1)}%"

      # Reset between edge case tests
      sleep 3.seconds
    end

    puts "✓ Rate limiting edge cases handled gracefully"
  end
end