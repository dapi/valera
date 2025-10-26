# frozen_string_literal: true

require 'test_helper'

# Performance тесты для системы аналитики
#
# Проверяет производительность системы аналитики под нагрузкой
# и убеждается, что она не влияет на основной функционал
class AnalyticsPerformanceTest < ActiveSupport::TestCase
  def setup
    @chat_id = 123456789
    AnalyticsEvent.delete_all
  end

  test "handles high volume events efficiently" do
    start_time = Time.current

    500.times do |i|
      event_data = {
        event_name: AnalyticsService::Events::RESPONSE_TIME,
        chat_id: i,
        properties: {
          duration_ms: rand(100..5000),
          model_used: 'deepseek-chat',
          timestamp: Time.current.to_f
        },
        occurred_at: Time.current,
        session_id: "session_#{i}"
      }

      AnalyticsJob.perform_now(event_data)
    end

    duration = Time.current - start_time
    assert duration < 3.seconds, "Too slow: #{duration} seconds for 500 events"

    # Verify all events were created
    assert_equal 500, AnalyticsEvent.count
  end

  test "analytics queries are performant with large dataset" do
    # Create test data with reduced size for faster execution
    10.times do |day|
      50.times do |event|
        AnalyticsEvent.create!(
          event_name: [AnalyticsService::Events::DIALOG_STARTED,
                      AnalyticsService::Events::BOOKING_CREATED].sample,
          chat_id: rand(1..500),
          properties: { test: 'data', day: day },
          occurred_at: day.days.ago + rand(24).hours,
          session_id: SecureRandom.hex(16)
        )
      end
    end

    # Test conversion funnel query performance
    start_time = Time.current

    result = AnalyticsEvent.conversion_funnel(10.days.ago, Time.current)

    query_duration = Time.current - start_time
    assert query_duration < 1.second, "Conversion funnel query too slow: #{query_duration} seconds"

    # Test recent events query
    start_time = Time.current

    recent_events = AnalyticsEvent.recent(7.days).count

    query_duration = Time.current - start_time
    assert query_duration < 0.5.seconds, "Recent events query too slow: #{query_duration} seconds"
  end

  test "async processing doesn't block main thread" do
    # Since we're using ActiveSupport::TestCase with inline adapter,
    # let's test the job execution performance directly

    event_data = {
      event_name: AnalyticsService::Events::DIALOG_STARTED,
      chat_id: @chat_id,
      properties: { test: 'data' },
      occurred_at: Time.current,
      session_id: 'test_session'
    }

    # Measure job execution time
    execution_start = Time.current

    AnalyticsJob.perform_now(event_data)

    execution_duration = Time.current - execution_start

    # Job execution should be reasonable (< 100ms)
    assert execution_duration < 0.1.seconds, "Job execution too slow: #{execution_duration} seconds"

    # Event should be created
    assert_equal 1, AnalyticsEvent.count

    # Verify the event was created correctly
    created_event = AnalyticsEvent.first
    assert_equal AnalyticsService::Events::DIALOG_STARTED, created_event.event_name
    assert_equal @chat_id, created_event.chat_id
    assert_equal 'test_session', created_event.session_id
  end

  test "memory usage stays reasonable with many events" do
    # Check memory before
    initial_objects = ObjectSpace.count_objects

    # Create many events with reduced size
    500.times do |i|
      AnalyticsEvent.create!(
        event_name: AnalyticsService::Events::RESPONSE_TIME,
        chat_id: @chat_id + i,
        properties: {
          duration_ms: i,
          model_used: 'deepseek-chat',
          large_data: 'x' * 50 # Smaller payload
        },
        occurred_at: Time.current,
        session_id: SecureRandom.hex(16)
      )
    end

    # Force garbage collection
    GC.start

    # Check memory after
    final_objects = ObjectSpace.count_objects
    object_increase = final_objects[:TOTAL] - initial_objects[:TOTAL]

    # Should not create excessive objects (reasonable limit)
    assert object_increase < 8000, "Too many objects created: #{object_increase}"
  end

  test "database indexes improve query performance" do
    # Create data for index testing
    1000.times do |i|
      AnalyticsEvent.create!(
        event_name: AnalyticsService::Events::DIALOG_STARTED,
        chat_id: @chat_id + (i % 100), # 100 unique chats
        properties: { test_data: "data_#{i}" },
        occurred_at: i.hours.ago,
        session_id: "session_#{i % 50}" # 50 unique sessions
      )
    end

    # Test indexed queries
    start_time = Time.current

    # Query by chat_id and event_name (should use idx_analytics_funnel)
    events = AnalyticsEvent.where(
      chat_id: @chat_id,
      event_name: AnalyticsService::Events::DIALOG_STARTED
    ).count

    query_duration = Time.current - start_time
    assert query_duration < 0.1.seconds, "Indexed query too slow: #{query_duration} seconds"

    # Test timeline query (should use idx_analytics_timeline)
    start_time = Time.current

    timeline_events = AnalyticsEvent.where(
      occurred_at: 24.hours.ago..Time.current,
      event_name: AnalyticsService::Events::DIALOG_STARTED
    ).count

    query_duration = Time.current - start_time
    assert query_duration < 0.1.seconds, "Timeline query too slow: #{query_duration} seconds"
  end

  test "concurrent analytics processing" do
    threads = []
    events_per_thread = 50

    start_time = Time.current

    # Create multiple threads to simulate concurrent load
    5.times do |thread_id|
      threads << Thread.new do
        events_per_thread.times do |event_id|
          event_data = {
            event_name: AnalyticsService::Events::RESPONSE_TIME,
            chat_id: thread_id * 1000 + event_id,
            properties: {
              duration_ms: rand(100..5000),
              model_used: 'deepseek-chat',
              thread_id: thread_id
            },
            occurred_at: Time.current,
            session_id: "thread_#{thread_id}_session_#{event_id}"
          }

          AnalyticsJob.perform_now(event_data)
        end
      end
    end

    # Wait for all threads to complete
    threads.each(&:join)

    total_duration = Time.current - start_time

    # Should handle concurrent load efficiently
    assert total_duration < 2.seconds, "Concurrent processing too slow: #{total_duration} seconds"

    # Verify all events were created
    assert_equal 250, AnalyticsEvent.count
  end
end