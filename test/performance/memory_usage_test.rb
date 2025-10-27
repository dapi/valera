# frozen_string_literal: true

require 'test_helper'
require 'benchmark'

class MemoryUsageTest < ActiveSupport::TestCase
  include TelegramSupport

  setup do
    @chat_id = 123456789
    @user = TelegramUser.create!(
      id: @chat_id,
      first_name: 'Test',
      last_name: 'User',
      username: 'testuser'
    )
    @chat = Chat.create!(telegram_user: @user)
  end

  def get_memory_usage
    # Get memory usage in MB
    if defined?(GC.stat)
      # Ruby 2.1+ method using GC statistics
      GC.stat[:heap_allocated_pages] * 0.016 # Approximate page size
    else
      # Fallback to system command
      `ps -o rss= -p #{Process.pid}`.to_i / 1024.0
    end
  rescue
    0
  end

  def get_detailed_memory_stats
    if defined?(GC.stat)
      GC.stat.slice(:heap_allocated_pages, :heap_sorted_length, :heap_allocatable_pages,
                    :heap_available_slots, :heap_live_slots, :heap_free_slots,
                    :heap_final_slots, :heap_marked_slots, :heap_swept_slots,
                    :total_allocated_objects, :total_freed_objects,
                    :minor_gc_count, :major_gc_count)
    else
      {}
    end
  end

  def force_garbage_collection
    GC.start
    sleep 0.1 # Give GC time to complete
    GC.start # Double collection for thoroughness
  end

  test 'baseline memory usage measurement' do
    puts "\n=== Baseline Memory Usage Test ==="

    initial_memory = get_memory_usage
    initial_stats = get_detailed_memory_stats

    puts "Initial Memory Usage: #{initial_memory.round(2)}MB"
    puts "Initial GC Stats: #{initial_stats.inspect}" if initial_stats.any?

    # Memory should be reasonable for a Rails test environment
    assert initial_memory < 500, "Initial memory usage too high: #{initial_memory}MB"

    # Memory stats should be available
    assert initial_stats.any?, "GC statistics should be available"
  end

  test 'memory usage during webhook processing' do
    puts "\n=== Webhook Memory Usage Test ==="

    Message.delete_all
    AnalyticsEvent.delete_all

    initial_memory = get_memory_usage
    memory_samples = [initial_memory]

    puts "Starting memory: #{initial_memory.round(2)}MB"

    # Process multiple webhook requests
    100.times do |i|
      VCR.use_cassette "memory_webhook_#{i}", record: :new_episodes do
        post telegram_webhook_path, params: telegram_message("Memory test message #{i}")
      end

      # Sample memory every 10 requests
      if (i + 1) % 10 == 0
        current_memory = get_memory_usage
        memory_increase = current_memory - initial_memory
        memory_samples << current_memory

        puts "After #{i + 1} requests: #{current_memory.round(2)}MB (+#{memory_increase.round(2)}MB)"

        # Memory increase should be reasonable
        assert memory_increase < 100, "Memory increased too much after #{i + 1} requests: #{memory_increase}MB"
      end
    end

    final_memory = get_memory_usage
    total_increase = final_memory - initial_memory

    puts "Final memory: #{final_memory.round(2)}MB (+#{total_increase.round(2)}MB)"
    puts "Peak memory: #{memory_samples.max.round(2)}MB"

    # Memory should not grow excessively
    assert total_increase < 200, "Excessive memory growth: #{total_increase}MB"
    assert memory_samples.max - memory_samples.min < 150, "Memory variance too high: #{memory_samples.max - memory_samples.min}MB"

    # Verify data was created properly
    assert Message.count > 0, "Messages should be created"
    assert AnalyticsEvent.count > 0, "Analytics events should be created"
  end

  test 'memory usage during AI response processing' do
    puts "\n=== AI Processing Memory Usage Test ==="

    initial_memory = get_memory_usage
    initial_stats = get_detailed_memory_stats

    puts "Initial memory: #{initial_memory.round(2)}MB"

    complex_queries = [
      'Здравствуйте, хочу записаться на комплексную диагностику автомобиля Toyota Camry 2018 года выпуска',
      'Мне нужна замена тормозных колодок, дисков, полный ремонт подвески и диагностика двигателя',
      'Рассчитайте стоимость полного технического обслуживания с заменой масла всех фильтров и жидкостей',
      'У меня проблема с коробкой передач, не переключаются передачи, нужно срочное вмешательство',
      'Хочу сделать полный кузовной ремонт, покраску, полировку и защиту кузова'
    ]

    memory_snapshots = [initial_memory]
    object_count_snapshots = [initial_stats[:total_allocated_objects] || 0]

    complex_queries.each_with_index do |query, index|
      puts "Processing query #{index + 1}: #{query[0..50]}..."

      pre_query_memory = get_memory_usage
      pre_query_stats = get_detailed_memory_stats

      VCR.use_cassette "memory_ai_#{index}", record: :new_episodes do
        post telegram_webhook_path, params: telegram_message(query)
      end

      post_query_memory = get_memory_usage
      post_query_stats = get_detailed_memory_stats

      memory_diff = post_query_memory - pre_query_memory
      objects_diff = (post_query_stats[:total_allocated_objects] || 0) - (pre_query_stats[:total_allocated_objects] || 0)

      memory_snapshots << post_query_memory
      object_count_snapshots << post_query_stats[:total_allocated_objects] || 0

      puts "  Memory change: #{memory_diff.round(2)}MB"
      puts "  Objects allocated: #{objects_diff}"

      # Single query should not use excessive memory
      assert memory_diff < 50, "Single query used too much memory: #{memory_diff}MB"
    end

    final_memory = memory_snapshots.last
    total_memory_increase = final_memory - initial_memory
    total_objects_created = object_count_snapshots.last - object_count_snapshots.first

    puts "Total memory increase: #{total_memory_increase.round(2)}MB"
    puts "Total objects created: #{total_objects_created}"
    puts "Peak memory: #{memory_snapshots.max.round(2)}MB"

    # AI processing should not leak significant memory
    assert total_memory_increase < 100, "AI processing leaked too much memory: #{total_memory_increase}MB"
  end

  test 'memory usage during bulk data operations' do
    puts "\n=== Bulk Operations Memory Usage Test ==="

    AnalyticsEvent.delete_all
    Message.delete_all

    initial_memory = get_memory_usage
    memory_samples = [initial_memory]

    # Test bulk analytics event creation
    event_count = 1000
    puts "Creating #{event_count} analytics events..."

    event_creation_memory = Benchmark.realtime do
      event_count.times do |i|
        AnalyticsJob.perform_now({
          event_name: AnalyticsService::Events::RESPONSE_TIME,
          chat_id: @chat_id + (i % 100),
          properties: {
            duration_ms: rand(100..5000),
            test_data: "bulk_test_#{i}",
            large_payload: 'x' * (rand(100..1000)) # Variable size payload
          },
          occurred_at: i.minutes.ago,
          session_id: "bulk_session_#{i % 50}"
        })

        if (i + 1) % 200 == 0
          current_memory = get_memory_usage
          memory_samples << current_memory
          memory_increase = current_memory - initial_memory

          puts "  After #{i + 1} events: #{current_memory.round(2)}MB (+#{memory_increase.round(2)}MB)"
        end
      end
    end

    puts "Event creation time: #{event_creation_memory.round(3)}s"

    # Test bulk message creation
    message_count = 500
    puts "Creating #{message_count} messages..."

    message_creation_memory = Benchmark.realtime do
      message_count.times do |i|
        Message.create!(
          chat: @chat,
          role: i.even? ? 'user' : 'assistant',
          content: "Bulk message #{i} with additional content to increase memory usage per record",
          created_at: i.minutes.ago
        )

        if (i + 1) % 100 == 0
          current_memory = get_memory_usage
          memory_increase = current_memory - initial_memory

          puts "  After #{i + 1} messages: #{current_memory.round(2)}MB (+#{memory_increase.round(2)}MB)"
        end
      end
    end

    puts "Message creation time: #{message_creation_memory.round(3)}s"

    final_memory = get_memory_usage
    total_memory_increase = final_memory - initial_memory
    peak_memory = memory_samples.max

    puts "Bulk Operations Results:"
    puts "  Initial memory: #{initial_memory.round(2)}MB"
    puts "  Final memory: #{final_memory.round(2)}MB"
    puts "  Total increase: #{total_memory_increase.round(2)}MB"
    puts "  Peak memory: #{peak_memory.round(2)}MB"
    puts "  Events created: #{AnalyticsEvent.count}"
    puts "  Messages created: #{Message.count}"

    # Bulk operations should be memory efficient
    assert total_memory_increase < 300, "Bulk operations used too much memory: #{total_memory_increase}MB"
    assert AnalyticsEvent.count == event_count, "Not all events were created"
    assert Message.count == message_count, "Not all messages were created"
  end

  test 'memory usage during concurrent operations' do
    puts "\n=== Concurrent Operations Memory Usage Test ==="

    initial_memory = get_memory_usage
    initial_stats = get_detailed_memory_stats

    puts "Initial memory: #{initial_memory.round(2)}MB"

    thread_count = 10
    operations_per_thread = 50
    threads = []

    thread_results = Array.new(thread_count) do |thread_id|
      Thread.new do
        thread_memory_start = get_memory_usage
        operations_completed = 0

        operations_per_thread.times do |i|
          chat_id = @chat_id + thread_id * 1000 + i

          # Create user and chat
          user = TelegramUser.create!(
            id: chat_id,
            first_name: "Concurrent#{thread_id}",
            username: "concurrent#{thread_id}#{i}"
          )
          chat = Chat.create!(telegram_user: user)

          # Create messages
          5.times do |j|
            Message.create!(
              chat: chat,
              role: j.even? ? 'user' : 'assistant',
              content: "Concurrent message #{thread_id}-#{i}-#{j}"
            )
          end

          # Create analytics events
          AnalyticsJob.perform_now({
            event_name: AnalyticsService::Events::DIALOG_STARTED,
            chat_id: chat_id,
            properties: { thread_id: thread_id, operation: i },
            occurred_at: Time.current,
            session_id: "concurrent_#{thread_id}_#{i}"
          )

          operations_completed += 1
        end

        thread_memory_end = get_memory_usage
        thread_memory_increase = thread_memory_end - thread_memory_start

        {
          thread_id: thread_id,
          memory_increase: thread_memory_increase,
          operations_completed: operations_completed
        }
      end
    end

    # Wait for all threads to complete
    thread_results.each(&:value)

    final_memory = get_memory_usage
    final_stats = get_detailed_memory_stats
    total_memory_increase = final_memory - initial_memory
    total_objects_created = (final_stats[:total_allocated_objects] || 0) - (initial_stats[:total_allocated_objects] || 0)

    puts "Concurrent Operations Results:"
    puts "  Threads: #{thread_count}"
    puts "  Operations per thread: #{operations_per_thread}"
    puts "  Total operations: #{thread_count * operations_per_thread}"
    puts "  Initial memory: #{initial_memory.round(2)}MB"
    puts "  Final memory: #{final_memory.round(2)}MB"
    puts "  Total memory increase: #{total_memory_increase.round(2)}MB"
    puts "  Objects created: #{total_objects_created}"

    # Analyze per-thread memory usage
    per_thread_results = thread_results.map(&:value)
    avg_thread_memory = per_thread_results.sum { |r| r[:memory_increase] } / per_thread_results.size
    max_thread_memory = per_thread_results.map { |r| r[:memory_increase] }.max

    puts "  Average thread memory increase: #{avg_thread_memory.round(2)}MB"
    puts "  Max thread memory increase: #{max_thread_memory.round(2)}MB"

    # Concurrent operations should not use excessive memory
    assert total_memory_increase < 400, "Concurrent operations used too much memory: #{total_memory_increase}MB"
    assert avg_thread_memory < 50, "Average thread memory usage too high: #{avg_thread_memory}MB"
  end

  test 'garbage collection effectiveness' do
    puts "\n=== Garbage Collection Effectiveness Test ==="

    # Disable automatic GC for this test
    original_gc_enabled = GC.enable
    GC.disable

    initial_memory = get_memory_usage
    initial_stats = get_detailed_memory_stats

    puts "Initial state:"
    puts "  Memory: #{initial_memory.round(2)}MB"
    puts "  Live objects: #{initial_stats[:heap_live_slots]}"
    puts "  Free slots: #{initial_stats[:heap_free_slots]}"

    # Create a lot of objects to fill memory
    object_creation_start = Time.current
    large_object_arrays = []

    1000.times do |i|
      # Create objects that will become garbage
      temp_objects = Array.new(100) { |j| "Large object string #{i}-#{j}" * 10 }
      large_object_arrays << temp_objects

      if i % 100 == 0
        current_memory = get_memory_usage
        puts "After #{i + 1} object arrays: #{current_memory.round(2)}MB"
      end
    end

    object_creation_time = Time.current - object_creation_start
    peak_memory = get_memory_usage
    peak_stats = get_detailed_memory_stats

    puts "\nAfter object creation:"
    puts "  Creation time: #{object_creation_time.round(3)}s"
    puts "  Peak memory: #{peak_memory.round(2)}MB"
    puts "  Peak live objects: #{peak_stats[:heap_live_slots]}"
    puts "  Memory increase: #{(peak_memory - initial_memory).round(2)}MB"

    # Clear references to make objects eligible for GC
    large_object_arrays.clear
    force_garbage_collection

    # Re-enable GC
    GC.enable if original_gc_enabled

    post_gc_memory = get_memory_usage
    post_gc_stats = get_detailed_memory_stats

    puts "\nAfter garbage collection:"
    puts "  Memory: #{post_gc_memory.round(2)}MB"
    puts "  Live objects: #{post_gc_stats[:heap_live_slots]}"
    puts "  Memory recovered: #{(peak_memory - post_gc_memory).round(2)}MB"
    puts "  Objects freed: #{(peak_stats[:heap_live_slots] || 0) - (post_gc_stats[:heap_live_slots] || 0)}"

    memory_recovered = peak_memory - post_gc_memory
    recovery_percentage = (memory_recovered / (peak_memory - initial_memory) * 100).round(1)

    puts "  Recovery efficiency: #{recovery_percentage}%"

    # GC should be effective
    assert recovery_percentage > 50, "Garbage collection not effective enough: #{recovery_percentage}%"
    assert post_gc_memory < peak_memory * 1.1, "Memory not properly cleaned up by GC"
  end

  test 'memory leak detection over extended operation' do
    puts "\n=== Extended Operation Memory Leak Test ==="

    initial_memory = get_memory_usage
    memory_readings = [initial_memory]

    puts "Starting extended operation test. Initial memory: #{initial_memory.round(2)}MB"

    # Simulate extended operation with periodic memory monitoring
    10.times do |cycle|
      puts "Cycle #{cycle + 1}/10"

      cycle_start_memory = get_memory_usage

      # Perform various operations
      20.times do |i|
        # Webhook processing
        VCR.use_cassette "leak_test_#{cycle}_#{i}", record: :new_episodes do
          post telegram_webhook_path, params: telegram_message("Leak test #{cycle}-#{i}")
        end

        # Data operations
        AnalyticsJob.perform_now({
          event_name: AnalyticsService::Events::RESPONSE_TIME,
          chat_id: @chat_id + cycle * 100 + i,
          properties: { cycle: cycle, iteration: i },
          occurred_at: Time.current,
          session_id: "leak_test_#{cycle}_#{i}"
        })

        Message.create!(
          chat: @chat,
          role: i.even? ? 'user' : 'assistant',
          content: "Leak test message #{cycle}-#{i}"
        )
      end

      # Force garbage collection
      force_garbage_collection

      cycle_end_memory = get_memory_usage
      memory_readings << cycle_end_memory

      cycle_memory_increase = cycle_end_memory - cycle_start_memory
      total_memory_increase = cycle_end_memory - initial_memory

      puts "  Cycle memory change: #{cycle_memory_increase.round(2)}MB"
      puts "  Total memory increase: #{total_memory_increase.round(2)}MB"

      # Each cycle should not accumulate significant memory
      assert total_memory_increase < 100, "Memory leak detected after #{cycle + 1} cycles: #{total_memory_increase}MB"
    end

    # Analyze memory trend
    final_memory = memory_readings.last
    total_increase = final_memory - initial_memory

    # Calculate memory growth trend
    if memory_readings.length > 2
      memory_trend = memory_readings.each_cons(2).map { |a, b| b - a }
      avg_growth_per_cycle = memory_trend.sum / memory_trend.size
      max_growth_cycle = memory_trend.max
    end

    puts "\nExtended Operation Results:"
    puts "  Initial memory: #{initial_memory.round(2)}MB"
    puts "  Final memory: #{final_memory.round(2)}MB"
    puts "  Total increase: #{total_increase.round(2)}MB"
    puts "  Average growth per cycle: #{avg_growth_per_cycle&.round(3)}MB" if avg_growth_per_cycle
    puts "  Max growth in single cycle: #{max_growth_cycle&.round(3)}MB" if max_growth_cycle

    # Check for memory leaks
    assert total_increase < 200, "Significant memory leak detected: #{total_increase}MB"
    assert avg_growth_per_cycle.nil? || avg_growth_per_cycle < 10, "Consistent memory growth detected: #{avg_growth_per_cycle}MB/cycle" if avg_growth_per_cycle

    # Verify data integrity
    assert Message.count >= 200, "Not all messages created: #{Message.count}"
    assert AnalyticsEvent.count >= 200, "Not all analytics events created: #{AnalyticsEvent.count}"
  end

  test 'memory usage during error conditions' do
    puts "\n=== Error Condition Memory Usage Test ==="

    initial_memory = get_memory_usage

    puts "Initial memory: #{initial_memory.round(2)}MB"

    # Test memory usage during various error conditions
    error_scenarios = [
      {
        name: 'Invalid webhook payload',
        action: -> { post telegram_webhook_path, params: { invalid: 'payload' }.to_json }
      },
      {
        name: 'Missing required fields',
        action: -> { post telegram_webhook_path, params: { update_id: 123 }.to_json }
      },
      {
        name: 'Malformed JSON',
        action: -> { post telegram_webhook_path, params: 'invalid json{' }
      },
      {
        name: 'Large payload',
        action: -> { post telegram_webhook_path, params: { text: 'x' * 50000 }.to_json }
      },
      {
        name: 'Database error simulation',
        action: -> do
          # This will be handled gracefully by the application
          Message.create!(content: nil) # Should fail validation
        rescue => e
          # Expected error
        end
      }
    ]

    error_scenarios.each_with_index do |scenario, index|
      puts "Testing #{scenario[:name]}..."

      pre_error_memory = get_memory_usage

      10.times do |i|
        begin
          scenario[:action].call
        rescue => e
          # Expected errors
        end
      end

      post_error_memory = get_memory_usage
      memory_increase = post_error_memory - pre_error_memory

      puts "  Memory change: #{memory_increase.round(2)}MB"

      # Error handling should not leak significant memory
      assert memory_increase < 20, "Error scenario '#{scenario[:name]}' leaked memory: #{memory_increase}MB"
    end

    final_memory = get_memory_usage
    total_memory_increase = final_memory - initial_memory

    puts "\nError Condition Results:"
    puts "  Initial memory: #{initial_memory.round(2)}MB"
    puts "  Final memory: #{final_memory.round(2)}MB"
    puts "  Total memory increase: #{total_memory_increase.round(2)}MB"

    assert total_memory_increase < 50, "Error conditions leaked too much memory: #{total_memory_increase}MB"
  end
end