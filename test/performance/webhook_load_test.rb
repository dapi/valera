# frozen_string_literal: true

require 'test_helper'
require 'benchmark'

class WebhookLoadTest < ActiveSupport::TestCase
  include TelegramSupport

  setup do
    @webhook_url = '/telegram/webhook'
    @concurrent_users = 20
    @requests_per_user = 10
    @timeout_threshold = 10.seconds
  end

  def create_webhook_payload(message_text = 'load test message', chat_id = nil)
    chat_id ||= rand(1000000..9999999)
    from = { id: chat_id, is_bot: false, first_name: 'Load', last_name: 'Test', username: "loadtest#{chat_id}" }
    chat = { id: chat_id, first_name: 'Load', last_name: 'Test', username: "loadtest#{chat_id}", type: 'private' }
    {
      update_id: rand(100000000..999999999),
      message: { message_id: rand(1..1000), from: from, chat: chat, date: Time.current.to_i, text: message_text }
    }
  end

  test 'webhook endpoint handles high concurrent load' do
    puts "\n=== Webhook Load Test: Concurrent Users ==="
    puts "Testing #{@concurrent_users} concurrent users with #{@requests_per_user} requests each"

    # Clean up before test
    AnalyticsEvent.delete_all
    Message.delete_all

    threads = []
    results = []
    start_time = Time.current

    @concurrent_users.times do |user_id|
      threads << Thread.new do
        user_results = {
          user_id: user_id,
          successful_requests: 0,
          failed_requests: 0,
          total_time: 0,
          response_times: []
        }

        @requests_per_user.times do |req_id|
          request_start = Time.current
          chat_id = user_id * 1000 + req_id

          begin
            post @webhook_url,
                 headers: { 'Content-Type' => 'application/json' },
                 params: create_webhook_payload("Load test #{user_id}-#{req_id}", chat_id)

            request_time = Time.current - request_start
            user_results[:response_times] << request_time
            user_results[:total_time] += request_time

            if response.status == 200
              user_results[:successful_requests] += 1
            else
              user_results[:failed_requests] += 1
            end
          rescue => e
            user_results[:failed_requests] += 1
            puts "User #{user_id} request #{req_id} failed: #{e.message}"
          end
        end

        results << user_results
      end
    end

    threads.each(&:join)
    total_duration = Time.current - start_time

    # Analyze results
    total_requests = @concurrent_users * @requests_per_user
    successful_requests = results.sum { |r| r[:successful_requests] }
    failed_requests = results.sum { |r| r[:failed_requests] }
    success_rate = (successful_requests.to_f / total_requests * 100).round(2)

    all_response_times = results.flat_map { |r| r[:response_times] }
    avg_response_time = (all_response_times.sum / all_response_times.size).round(3)
    max_response_time = all_response_times.max.round(3)
    min_response_time = all_response_times.min.round(3)

    requests_per_second = (total_requests / total_duration).round(2)

    puts "Total Duration: #{total_duration.round(2)} seconds"
    puts "Total Requests: #{total_requests}"
    puts "Successful: #{successful_requests} (#{success_rate}%)"
    puts "Failed: #{failed_requests}"
    puts "Requests/Second: #{requests_per_second}"
    puts "Average Response Time: #{avg_response_time}s"
    puts "Min Response Time: #{min_response_time}s"
    puts "Max Response Time: #{max_response_time}s"

    # Assertions
    assert total_duration < @timeout_threshold, "Test completed too slowly: #{total_duration}s"
    assert success_rate >= 95.0, "Success rate too low: #{success_rate}%"
    assert avg_response_time < 1.0, "Average response time too high: #{avg_response_time}s"
    assert max_response_time < 5.0, "Max response time too high: #{max_response_time}s"

    # Verify data integrity
    assert AnalyticsEvent.count >= successful_requests / 2, "Analytics events should be created for most requests"
    assert Message.count >= successful_requests / 2, "Messages should be stored for most requests"
  end

  test 'webhook performance under sustained load' do
    puts "\n=== Webhook Sustained Load Test ==="

    AnalyticsEvent.delete_all
    Message.delete_all

    total_requests = 100
    batch_size = 10
    request_times = []

    (total_requests / batch_size).times do |batch|
      puts "Processing batch #{batch + 1}/#{total_requests / batch_size}"

      batch_start = Time.current

      batch_size.times do |i|
        request_start = Time.current
        request_id = batch * batch_size + i

        post @webhook_url,
             headers: { 'Content-Type' => 'application/json' },
             params: create_webhook_payload("Sustained test #{request_id}")

        request_times << (Time.current - request_start)
      end

      batch_duration = Time.current - batch_start
      puts "  Batch completed in #{batch_duration.round(3)}s"

      # Small delay to simulate realistic usage patterns
      sleep 0.1
    end

    avg_time = (request_times.sum / request_times.size).round(3)
    max_time = request_times.max.round(3)
    min_time = request_times.min.round(3)

    puts "Sustained Load Results:"
    puts "  Total Requests: #{total_requests}"
    puts "  Average Response Time: #{avg_time}s"
    puts "  Min Response Time: #{min_time}s"
    puts "  Max Response Time: #{max_time}s"

    assert avg_time < 0.5, "Average response time too high under sustained load: #{avg_time}s"
    assert max_time < 2.0, "Max response time too high under sustained load: #{max_time}s"
  end

  test 'webhook memory usage under load' do
    puts "\n=== Webhook Memory Usage Test ==="

    initial_memory = get_memory_usage
    puts "Initial Memory Usage: #{initial_memory}MB"

    requests_count = 200
    requests_count.times do |i|
      post @webhook_url,
           headers: { 'Content-Type' => 'application/json' },
           params: create_webhook_payload("Memory test #{i}")

      # Check memory every 50 requests
      if (i + 1) % 50 == 0
        current_memory = get_memory_usage
        memory_increase = current_memory - initial_memory
        puts "After #{i + 1} requests: #{current_memory}MB (+#{memory_increase}MB)"

        # Memory increase should be reasonable
        assert memory_increase < 100, "Memory increased too much: #{memory_increase}MB"
      end
    end

    # Force garbage collection
    GC.start
    final_memory = get_memory_usage
    total_increase = final_memory - initial_memory

    puts "Final Memory Usage: #{final_memory}MB (+#{total_increase}MB)"
    puts "Total Requests Processed: #{requests_count}"

    # Memory increase should be minimal after GC
    assert total_increase < 50, "Excessive memory retention: #{total_increase}MB"
  end

  test 'webhook database performance under load' do
    puts "\n=== Database Performance Test ==="

    AnalyticsEvent.delete_all
    Message.delete_all

    # Measure database performance
    db_stats = {
      analytics_creation_times: [],
      message_creation_times: [],
      query_times: []
    }

    100.times do |i|
      # Time the webhook request
      request_start = Time.current

      post @webhook_url,
           headers: { 'Content-Type' => 'application/json' },
           params: create_webhook_payload("DB test #{i}")

      request_time = Time.current - request_start

      # Time database queries
      query_start = Time.current
      analytics_count = AnalyticsEvent.where(chat_id: rand(1000000..9999999)).count
      query_time = Time.current - query_start
      db_stats[:query_times] << query_time

      if (i + 1) % 20 == 0
        avg_query_time = (db_stats[:query_times].sum / db_stats[:query_times].size).round(4)
        puts "After #{i + 1} requests - Avg Query Time: #{avg_query_time}s"
      end
    end

    # Analyze database performance
    avg_query_time = (db_stats[:query_times].sum / db_stats[:query_times].size).round(4)
    max_query_time = db_stats[:query_times].max.round(4)

    puts "Database Performance Results:"
    puts "  Total Requests: #{100}"
    puts "  Average Query Time: #{avg_query_time}s"
    puts "  Max Query Time: #{max_query_time}s"
    puts "  Analytics Events Created: #{AnalyticsEvent.count}"
    puts "  Messages Created: #{Message.count}"

    assert avg_query_time < 0.01, "Average query time too high: #{avg_query_time}s"
    assert max_query_time < 0.1, "Max query time too high: #{max_query_time}s"
  end

  test 'webhook error handling performance' do
    puts "\n=== Error Handling Performance Test ==="

    error_payloads = [
      {}, # Empty payload
      { invalid: 'structure' }, # Invalid structure
      { update_id: 123, message: nil }, # Missing message
      { update_id: 123, message: { from: nil } } # Missing required fields
    ]

    error_handling_times = []

    100.times do |i|
      error_payload = error_payloads[i % error_payloads.length]
      request_start = Time.current

      post @webhook_url,
           headers: { 'Content-Type' => 'application/json' },
           params: error_payload.to_json

      handling_time = Time.current - request_start
      error_handling_times << handling_time

      # Should still return quickly even for invalid requests
      assert handling_time < 0.1, "Error handling too slow: #{handling_time}s"
    end

    avg_error_time = (error_handling_times.sum / error_handling_times.size).round(4)
    max_error_time = error_handling_times.max.round(4)

    puts "Error Handling Results:"
    puts "  Average Error Response Time: #{avg_error_time}s"
    puts "  Max Error Response Time: #{max_error_time}s"

    assert avg_error_time < 0.01, "Average error handling too slow: #{avg_error_time}s"
  end

  test 'webhook rate limiting performance' do
    puts "\n=== Rate Limiting Performance Test ==="

    # Simulate rapid requests from same user
    chat_id = 999999999
    request_times = []

    50.times do |i|
      request_start = Time.current

      post @webhook_url,
           headers: { 'Content-Type' => 'application/json' },
           params: create_webhook_payload("Rate limit test #{i}", chat_id)

      request_time = Time.current - request_start
      request_times << request_time
    end

    avg_time = (request_times.sum / request_times.size).round(3)
    max_time = request_times.max.round(3)

    puts "Rate Limiting Test Results:"
    puts "  Requests from single user: #{50}"
    puts "  Average Response Time: #{avg_time}s"
    puts "  Max Response Time: #{max_time}s"

    # Should handle rapid requests without degradation
    assert avg_time < 0.5, "Average response time degraded under rapid requests: #{avg_time}s"
  end

  test 'webhook large payload performance' do
    puts "\n=== Large Payload Performance Test ==="

    small_payload_times = []
    large_payload_times = []

    # Test small payloads
    10.times do |i|
      request_start = Time.current
      post @webhook_url,
           headers: { 'Content-Type' => 'application/json' },
           params: create_webhook_payload("Small payload #{i}")
      small_payload_times << (Time.current - request_start)
    end

    # Test large payloads
    large_message = 'a' * 10000 # 10KB message
    10.times do |i|
      request_start = Time.current
      post @webhook_url,
           headers: { 'Content-Type' => 'application/json' },
           params: create_webhook_payload("#{large_message} Large payload #{i}")
      large_payload_times << (Time.current - request_start)
    end

    avg_small_time = (small_payload_times.sum / small_payload_times.size).round(3)
    avg_large_time = (large_payload_times.sum / large_payload_times.size).round(3)
    performance_impact = ((avg_large_time - avg_small_time) / avg_small_time * 100).round(1)

    puts "Large Payload Performance Results:"
    puts "  Average Small Payload Time: #{avg_small_time}s"
    puts "  Average Large Payload Time: #{avg_large_time}s"
    puts "  Performance Impact: #{performance_impact}%"

    # Large payloads shouldn't significantly impact performance
    assert performance_impact < 50, "Large payloads cause excessive performance degradation: #{performance_impact}%"
    assert avg_large_time < 1.0, "Large payload processing too slow: #{avg_large_time}s"
  end

  private

  def get_memory_usage
    # Get memory usage in MB (this is a simplified approach)
    if defined?(GC.stat)
      GC.stat[:heap_allocated_pages] * 0.016 # Approximate page size in MB
    else
      # Fallback for different Ruby versions
      `ps -o rss= -p #{Process.pid}`.to_i / 1024.0
    end
  rescue
    0 # Return 0 if unable to get memory usage
  end
end