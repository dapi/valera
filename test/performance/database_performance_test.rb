# frozen_string_literal: true

require 'test_helper'
require 'benchmark'

class DatabasePerformanceTest < ActiveSupport::TestCase
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

  test 'chat creation and retrieval performance' do
    puts "\n=== Chat Performance Test ==="

    creation_times = []
    retrieval_times = []
    batch_sizes = [1, 10, 50, 100]

    batch_sizes.each do |batch_size|
      puts "Testing batch size: #{batch_size}"

      # Test chat creation
      creation_start = Time.current
      new_chats = []

      batch_size.times do |i|
        user = TelegramUser.create!(
          id: @chat_id + i + 1000,
          first_name: "User#{i}",
          username: "user#{i}"
        )
        chat = Chat.create!(telegram_user: user)
        new_chats << chat
      end

      creation_time = Time.current - creation_start
      creation_times << { batch_size: batch_size, time: creation_time }

      # Test chat retrieval
      retrieval_start = Time.current

      new_chats.each do |chat|
        Chat.find(chat.id)
      end

      retrieval_time = Time.current - retrieval_start
      retrieval_times << { batch_size: batch_size, time: retrieval_time }

      avg_creation_time = (creation_time / batch_size).round(4)
      avg_retrieval_time = (retrieval_time / batch_size).round(4)

      puts "  Creation: #{creation_time.round(3)}s total, #{avg_creation_time}s per chat"
      puts "  Retrieval: #{retrieval_time.round(3)}s total, #{avg_retrieval_time}s per chat"

      # Performance assertions
      assert avg_creation_time < 0.01, "Chat creation too slow: #{avg_creation_time}s"
      assert avg_retrieval_time < 0.005, "Chat retrieval too slow: #{avg_retrieval_time}s"
    end

    # Analyze scalability
    creation_scalability = creation_times.last[:time] / creation_times.first[:time]
    retrieval_scalability = retrieval_times.last[:time] / retrieval_times.first[:time]

    puts "\nScalability Analysis:"
    puts "  Creation scalability (100x vs 1x): #{creation_scalability.round(2)}x"
    puts "  Retrieval scalability (100x vs 1x): #{retrieval_scalability.round(2)}x"

    # Should scale reasonably (not linear degradation)
    assert creation_scalability < 150, "Chat creation doesn't scale well: #{creation_scalability}x"
    assert retrieval_scalability < 50, "Chat retrieval doesn't scale well: #{retrieval_scalability}x"
  end

  test 'message storage and querying performance' do
    puts "\n=== Message Performance Test ==="

    # Create test messages
    message_counts = [100, 500, 1000, 2000]

    message_counts.each do |count|
      puts "Testing with #{count} messages"

      Message.delete_all

      # Test message insertion
      insertion_start = Time.current

      count.times do |i|
        Message.create!(
          chat: @chat,
          role: i.even? ? 'user' : 'assistant',
          content: "Test message #{i}",
          created_at: i.minutes.ago
        )
      end

      insertion_time = Time.current - insertion_start
      insertion_rate = (count / insertion_time).round(0)

      puts "  Insertion: #{insertion_time.round(3)}s, #{insertion_rate} messages/sec"

      # Test common queries
      queries = [
        { name: 'Recent messages', query: -> { Message.where(chat: @chat).order(created_at: :desc).limit(50) } },
        { name: 'User messages', query: -> { Message.where(chat: @chat, role: 'user') } },
        { name: 'Assistant messages', query: -> { Message.where(chat: @chat, role: 'assistant') } },
        { name: 'Messages by date range', query: -> { Message.where(chat: @chat).where(created_at: 1.hour.ago..Time.current) } },
        { name: 'Message count', query: -> { Message.where(chat: @chat).count } }
      ]

      query_times = []

      queries.each do |query_info|
        query_start = Time.current
        query_info[:query].call
        query_time = Time.current - query_start
        query_times << query_time

        puts "    #{query_info[:name]}: #{query_time.round(4)}s"
      end

      avg_query_time = (query_times.sum / query_times.size).round(4)
      max_query_time = query_times.max.round(4)

      puts "  Average query time: #{avg_query_time}s"
      puts "  Max query time: #{max_query_time}s"

      # Performance assertions
      assert insertion_rate > 100, "Message insertion too slow: #{insertion_rate} messages/sec"
      assert avg_query_time < 0.01, "Average query time too high: #{avg_query_time}s"
      assert max_query_time < 0.1, "Max query time too high: #{max_query_time}s"
    end
  end

  test 'analytics event storage and aggregation performance' do
    puts "\n=== Analytics Performance Test ==="

    event_counts = [1000, 5000, 10000]

    event_counts.each do |count|
      puts "Testing with #{count} analytics events"

      AnalyticsEvent.delete_all

      # Test event insertion (using job for realistic scenario)
      insertion_start = Time.current

      count.times do |i|
        AnalyticsJob.perform_now({
          event_name: [AnalyticsService::Events::DIALOG_STARTED,
                       AnalyticsService::Events::RESPONSE_TIME,
                       AnalyticsService::Events::BOOKING_CREATED].sample,
          chat_id: @chat_id + (i % 100),
          properties: {
            test_data: "data_#{i}",
            random_value: rand(1..100),
            timestamp: Time.current.to_f
          },
          occurred_at: i.minutes.ago,
          session_id: "session_#{i % 50}"
        })
      end

      insertion_time = Time.current - insertion_start
      insertion_rate = (count / insertion_time).round(0)

      puts "  Event insertion: #{insertion_time.round(3)}s, #{insertion_rate} events/sec"

      # Test analytics queries
      analytics_queries = [
        { name: 'Recent events', query: -> { AnalyticsEvent.where(occurred_at: 1.hour.ago..Time.current) } },
        { name: 'Events by type', query: -> { AnalyticsEvent.where(event_name: AnalyticsService::Events::DIALOG_STARTED) } },
        { name: 'Conversion funnel', query: -> { AnalyticsEvent.conversion_funnel(1.day.ago, Time.current) } },
        { name: 'Chat events', query: -> { AnalyticsEvent.where(chat_id: @chat_id) } },
        { name: 'Event count', query: -> { AnalyticsEvent.count } },
        { name: 'Session events', query: -> { AnalyticsEvent.where(session_id: 'session_0') } }
      ]

      query_times = []

      analytics_queries.each do |query_info|
        query_start = Time.current
        query_info[:query].call
        query_time = Time.current - query_start
        query_times << query_time

        puts "    #{query_info[:name]}: #{query_time.round(4)}s"
      end

      avg_query_time = (query_times.sum / query_times.size).round(4)
      max_query_time = query_times.max.round(4)

      puts "  Average query time: #{avg_query_time}s"
      puts "  Max query time: #{max_query_time}s"

      # Performance assertions
      assert insertion_rate > 200, "Analytics insertion too slow: #{insertion_rate} events/sec"
      assert avg_query_time < 0.05, "Average analytics query too high: #{avg_query_time}s"
      assert max_query_time < 0.5, "Max analytics query too high: #{max_query_time}s"
    end
  end

  test 'booking creation and searching performance' do
    puts "\n=== Booking Performance Test ==="

    booking_counts = [100, 500, 1000]

    booking_counts.each do |count|
      puts "Testing with #{count} bookings"

      Booking.delete_all

      # Test booking creation
      creation_start = Time.current

      count.times do |i|
        Booking.create!(
          chat: @chat,
          customer_name: "Customer #{i}",
          customer_phone: "+7(999)#{sprintf('%03d', i)}-#{sprintf('%02d', i % 100)}-#{sprintf('%02d', i % 100)}",
          car_brand: ['Toyota', 'Lada', 'BMW', 'Mercedes', 'Audi'].sample,
          car_model: "Model #{i}",
          required_services: "Service #{i}",
          cost_calculation: "#{1000 + i * 100} рублей",
          dialog_context: "Context #{i}",
          details: "Details for booking #{i}",
          status: ['pending', 'confirmed', 'completed'].sample,
          created_at: i.hours.ago
        )
      end

      creation_time = Time.current - creation_start
      creation_rate = (count / creation_time).round(0)

      puts "  Booking creation: #{creation_time.round(3)}s, #{creation_rate} bookings/sec"

      # Test booking queries
      booking_queries = [
        { name: 'Recent bookings', query: -> { Booking.where(created_at: 1.day.ago..Time.current) } },
        { name: 'Pending bookings', query: -> { Booking.where(status: 'pending') } },
        { name: 'Customer search', query: -> { Booking.where('customer_name ILIKE ?', '%Customer 1%') } },
        { name: 'Car brand search', query: -> { Booking.where(car_brand: 'Toyota') } },
        { name: 'Chat bookings', query: -> { Booking.where(chat: @chat) } },
        { name: 'Booking count', query: -> { Booking.count } }
      ]

      query_times = []

      booking_queries.each do |query_info|
        query_start = Time.current
        query_info[:query].call
        query_time = Time.current - query_start
        query_times << query_time

        puts "    #{query_info[:name]}: #{query_time.round(4)}s"
      end

      avg_query_time = (query_times.sum / query_times.size).round(4)
      max_query_time = query_times.max.round(4)

      puts "  Average query time: #{avg_query_time}s"
      puts "  Max query time: #{max_query_time}s"

      # Performance assertions
      assert creation_rate > 50, "Booking creation too slow: #{creation_rate} bookings/sec"
      assert avg_query_time < 0.01, "Average booking query too high: #{avg_query_time}s"
      assert max_query_time < 0.1, "Max booking query too high: #{max_query_time}s"
    end
  end

  test 'database connection pooling performance' do
    puts "\n=== Database Connection Pool Test ==="

    # Test concurrent database access
    thread_counts = [5, 10, 20]

    thread_counts.each do |thread_count|
      puts "Testing with #{thread_count} concurrent threads"

      threads = []
      results = []
      start_time = Time.current

      thread_count.times do |i|
        threads << Thread.new do
          thread_start = Time.current

          # Simulate database operations
          10.times do |j|
            # Create user and chat
            user = TelegramUser.create!(
              id: @chat_id + i * 1000 + j,
              first_name: "Thread#{i}User#{j}",
              username: "thread#{i}user#{j}"
            )
            chat = Chat.create!(telegram_user: user)

            # Create messages
            5.times do |k|
              Message.create!(
                chat: chat,
                role: k.even? ? 'user' : 'assistant',
                content: "Message #{i}-#{j}-#{k}"
              )
            end

            # Create analytics event
            AnalyticsJob.perform_now({
              event_name: AnalyticsService::Events::DIALOG_STARTED,
              chat_id: user.id,
              properties: { thread_id: i, user_index: j },
              occurred_at: Time.current,
              session_id: "thread_#{i}_session_#{j}"
            })
          end

          thread_time = Time.current - thread_start
          results << { thread_id: i, time: thread_time }
        end
      end

      threads.each(&:join)
      total_time = Time.current - start_time

      avg_thread_time = (results.sum { |r| r[:time] } / results.size).round(3)
      max_thread_time = results.map { |r| r[:time] }.max.round(3)
      min_thread_time = results.map { |r| r[:time] }.min.round(3)

      total_operations = thread_count * 10 * (1 + 5 + 1) # users + messages + analytics
      operations_per_second = (total_operations / total_time).round(0)

      puts "  Total time: #{total_time.round(3)}s"
      puts "  Average thread time: #{avg_thread_time}s"
      puts "  Min thread time: #{min_thread_time}s"
      puts "  Max thread time: #{max_thread_time}s"
      puts "  Operations per second: #{operations_per_second}"

      # Performance assertions
      assert total_time < 30, "Concurrent operations too slow: #{total_time}s"
      assert avg_thread_time < 10, "Average thread time too high: #{avg_thread_time}s"
      assert operations_per_second > 100, "Operations per second too low: #{operations_per_second}"
    end
  end

  test 'database query optimization with indexes' do
    puts "\n=== Database Index Performance Test ==="

    # Create test data
    AnalyticsEvent.delete_all
    Message.delete_all

    data_size = 10000
    puts "Creating #{data_size} test records..."

    # Create analytics events
    data_size.times do |i|
      AnalyticsEvent.create!(
        event_name: [AnalyticsService::Events::DIALOG_STARTED,
                     AnalyticsService::Events::RESPONSE_TIME,
                     AnalyticsService::Events::BOOKING_CREATED].sample,
        chat_id: @chat_id + (i % 1000),
        properties: { test: "data_#{i}", value: i % 100 },
        occurred_at: i.minutes.ago,
        session_id: "session_#{i % 500}"
      )
    end

    # Create messages
    @chat_id.upto(@chat_id + 999) do |chat_id|
      10.times do |i|
        Message.create!(
          chat_id: chat_id,
          role: i.even? ? 'user' : 'assistant',
          content: "Message #{chat_id}-#{i}",
          created_at: i.minutes.ago
        )
      end
    end

    puts "Test data created. Testing query performance..."

    # Test indexed vs non-indexed queries
    query_tests = [
      {
        name: 'Analytics by chat_id (indexed)',
        query: -> { AnalyticsEvent.where(chat_id: @chat_id).count },
        expected_time: 0.01
      },
      {
        name: 'Analytics by event_name (indexed)',
        query: -> { AnalyticsEvent.where(event_name: AnalyticsService::Events::DIALOG_STARTED).count },
        expected_time: 0.01
      },
      {
        name: 'Analytics by occurred_at range (indexed)',
        query: -> { AnalyticsEvent.where(occurred_at: 1.hour.ago..Time.current).count },
        expected_time: 0.05
      },
      {
        name: 'Analytics complex query (composite index)',
        query: -> { AnalyticsEvent.where(chat_id: @chat_id, event_name: AnalyticsService::Events::DIALOG_STARTED).where(occurred_at: 1.day.ago..Time.current).count },
        expected_time: 0.01
      },
      {
        name: 'Messages by chat_id (indexed)',
        query: -> { Message.where(chat_id: @chat_id).count },
        expected_time: 0.005
      },
      {
        name: 'Messages by role (indexed)',
        query: -> { Message.where(role: 'user').count },
        expected_time: 0.01
      },
      {
        name: 'Conversion funnel query (optimized)',
        query: -> { AnalyticsEvent.conversion_funnel(1.day.ago, Time.current) },
        expected_time: 0.1
      }
    ]

    performance_results = []

    query_tests.each do |test|
      times = []

      # Run each query multiple times for accuracy
      5.times do
        query_start = Time.current
        test[:query].call
        query_time = Time.current - query_start
        times << query_time
      end

      avg_time = (times.sum / times.size).round(4)
      max_time = times.max.round(4)
      min_time = times.min.round(4)

      performance_results << {
        name: test[:name],
        avg_time: avg_time,
        max_time: max_time,
        min_time: min_time,
        expected_time: test[:expected_time],
        within_expectation: avg_time <= test[:expected_time]
      }

      status = avg_time <= test[:expected_time] ? "✓" : "✗"
      puts "  #{test[:name]}: #{avg_time}s (expected ≤#{test[:expected_time]}s) #{status}"
    end

    # Analyze results
    within_expectation_count = performance_results.count { |r| r[:within_expectation] }
    performance_score = (within_expectation_count.to_f / performance_results.size * 100).round(1)

    puts "\nIndex Performance Results:"
    puts "  Queries within expectation: #{within_expectation_count}/#{performance_results.size}"
    puts "  Performance score: #{performance_score}%"

    # Assertions
    assert performance_score >= 80.0,
           "Database query performance below expectations: #{performance_score}%"
  end

  test 'database transaction performance' do
    puts "\n=== Database Transaction Performance Test ==="

    transaction_sizes = [10, 50, 100, 500]

    transaction_sizes.each do |size|
      puts "Testing transaction with #{size} operations"

      # Test transaction performance
      transaction_time = Benchmark.realtime do
        Chat.transaction do
          size.times do |i|
            user = TelegramUser.create!(
              id: @chat_id + size * 100 + i,
              first_name: "TxUser#{i}",
              username: "txuser#{i}"
            )
            chat = Chat.create!(telegram_user: user)

            Message.create!(
              chat: chat,
              role: 'user',
              content: "Transaction message #{i}"
            )

            AnalyticsJob.perform_now({
              event_name: AnalyticsService::Events::DIALOG_STARTED,
              chat_id: user.id,
              properties: { transaction: true, index: i },
              occurred_at: Time.current,
              session_id: "tx_session_#{i}"
            })
          end
        end
      end

      # Test individual operations for comparison
      individual_time = Benchmark.realtime do
        size.times do |i|
          user = TelegramUser.create!(
            id: @chat_id + size * 200 + i,
            first_name: "IndUser#{i}",
            username: "induser#{i}"
          )
          chat = Chat.create!(telegram_user: user)

          Message.create!(
            chat: chat,
            role: 'user',
            content: "Individual message #{i}"
          )

          AnalyticsJob.perform_now({
            event_name: AnalyticsService::Events::DIALOG_STARTED,
            chat_id: user.id,
            properties: { transaction: false, index: i },
            occurred_at: Time.current,
            session_id: "ind_session_#{i}"
          })
        end
      end

      transaction_rate = (size / transaction_time).round(0)
      individual_rate = (size / individual_time).round(0)
      performance_improvement = ((individual_rate - transaction_rate) / transaction_rate * 100).round(1)

      puts "  Transaction: #{transaction_time.round(3)}s (#{transaction_rate} ops/sec)"
      puts "  Individual: #{individual_time.round(3)}s (#{individual_rate} ops/sec)"
      puts "  Performance improvement: #{performance_improvement}%"

      # Clean up for next test
      TelegramUser.where('username LIKE ?', 'txuser%').destroy_all
      TelegramUser.where('username LIKE ?', 'induser%').destroy_all

      # Transactions should be faster or at least not significantly slower
      assert performance_improvement >= -50,
             "Transaction performance too poor: #{performance_improvement}% improvement"
    end
  end
end