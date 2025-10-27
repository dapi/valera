# frozen_string_literal: true

require 'test_helper'
require 'benchmark'

class AIResponseBenchmarkTest < ActiveSupport::TestCase
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
    @timeout_threshold = 30.seconds
    @performance_threshold = 10.seconds
  end

  def telegram_message(text = 'test message')
    from = { id: @chat_id, is_bot: false, first_name: 'Test', last_name: 'User', username: 'testuser' }
    chat = { id: @chat_id, first_name: 'Test', last_name: 'User', username: 'testuser', type: 'private' }
    {
      update_id: 123456789,
      message: { message_id: 1, from: from, chat: chat, date: Time.current.to_i, text: text }
    }
  end

  test 'AI response time benchmark for simple queries' do
    puts "\n=== AI Response Time Benchmark: Simple Queries ==="

    simple_queries = [
      'Здравствуйте',
      'Спасибо',
      'Пока',
      'Да',
      'Нет',
      'Хорошо',
      'Понятно',
      'Когда открыто?'
    ]

    response_times = []
    success_count = 0
    failure_count = 0

    simple_queries.each_with_index do |query, index|
      puts "Testing query #{index + 1}/#{simple_queries.length}: '#{query}'"

      begin
        VCR.use_cassette "ai_benchmark_simple_#{index}", record: :new_episodes do
          start_time = Time.current

          post telegram_webhook_path, params: telegram_message(query)

          response_time = Time.current - start_time
          response_times << response_time

          if response.successful?
            success_count += 1
            puts "  ✓ Response time: #{response_time.round(3)}s"
          else
            failure_count += 1
            puts "  ✗ Failed with status: #{response.status}"
          end

          # Performance assertion
          assert response_time < @performance_threshold,
                 "Query '#{query}' too slow: #{response_time}s > #{@performance_threshold}s"
        end
      rescue => e
        failure_count += 1
        puts "  ✗ Error: #{e.message}"
      end
    end

    # Analyze results
    avg_response_time = (response_times.sum / response_times.size).round(3)
    min_response_time = response_times.min.round(3)
    max_response_time = response_times.max.round(3)

    puts "\nSimple Queries Results:"
    puts "  Total Queries: #{simple_queries.length}"
    puts "  Successful: #{success_count}"
    puts "  Failed: #{failure_count}"
    puts "  Success Rate: #{(success_count.to_f / simple_queries.length * 100).round(1)}%"
    puts "  Average Response Time: #{avg_response_time}s"
    puts "  Min Response Time: #{min_response_time}s"
    puts "  Max Response Time: #{max_response_time}s"

    assert success_count >= simple_queries.length * 0.8,
           "Too many failures: #{failure_count}/#{simple_queries.length}"
    assert avg_response_time < 5.0,
           "Average response time too high: #{avg_response_time}s"
  end

  test 'AI response time benchmark for complex booking queries' do
    puts "\n=== AI Response Time Benchmark: Complex Booking Queries ==="

    complex_queries = [
      'Здравствуйте, хочу записаться на диагностику двигателя на завтра в 10 утра, у меня Toyota Camry 2018 года',
      'Мне нужен ремонт тормозной системы, замена колодок спереди, возможно ли записаться на выходные?',
      'Сколько будет стоить полное ТО с заменой масла, фильтров и диагностикой подвески для Lada Vesta?',
      'У меня течет радиатор, нужно срочное вмешательство, когда вы можете принять?',
      'Хочу сделать полировку кузова и химчистку салона, сколько времени это займет и какая стоимость?',
      'Нужно заменить диски на автомобиле BMW X5, какие есть варианты и в какие сроки?',
      'Прошла диагностика, сказали что нужно менять сцепление, запишитесь на ремонт',
      'Проверьте пожалуйста уровень масла и охлаждающей жидкости, сделайте полную диагностику'
    ]

    response_times = []
    success_count = 0
    failure_count = 0
    tool_calls_count = 0

    complex_queries.each_with_index do |query, index|
      puts "Testing complex query #{index + 1}/#{complex_queries.length}..."

      begin
        VCR.use_cassette "ai_benchmark_complex_#{index}", record: :new_episodes do
          start_time = Time.current
          initial_tool_calls = ToolCall.count

          post telegram_webhook_path, params: telegram_message(query)

          response_time = Time.current - start_time
          new_tool_calls = ToolCall.count - initial_tool_calls
          tool_calls_count += new_tool_calls

          if response.successful?
            success_count += 1
            response_times << response_time
            puts "  ✓ Response time: #{response_time.round(3)}s, Tool calls: #{new_tool_calls}"
          else
            failure_count += 1
            puts "  ✗ Failed with status: #{response.status}"
          end

          # Performance assertion for complex queries (allow more time)
          assert response_time < @timeout_threshold,
                 "Complex query too slow: #{response_time}s > #{@timeout_threshold}s"
        end
      rescue => e
        failure_count += 1
        puts "  ✗ Error: #{e.message}"
      end
    end

    # Analyze results
    if response_times.any?
      avg_response_time = (response_times.sum / response_times.size).round(3)
      min_response_time = response_times.min.round(3)
      max_response_time = response_times.max.round(3)
    else
      avg_response_time = min_response_time = max_response_time = 0
    end

    puts "\nComplex Queries Results:"
    puts "  Total Queries: #{complex_queries.length}"
    puts "  Successful: #{success_count}"
    puts "  Failed: #{failure_count}"
    puts "  Success Rate: #{(success_count.to_f / complex_queries.length * 100).round(1)}%"
    puts "  Average Response Time: #{avg_response_time}s"
    puts "  Min Response Time: #{min_response_time}s"
    puts "  Max Response Time: #{max_response_time}s"
    puts "  Total Tool Calls: #{tool_calls_count}"
    puts "  Average Tool Calls per Query: #{(tool_calls_count.to_f / success_count).round(1)}"

    assert success_count >= complex_queries.length * 0.7,
           "Too many complex query failures: #{failure_count}/#{complex_queries.length}"
    assert avg_response_time < 15.0,
           "Average complex response time too high: #{avg_response_time}s" if response_times.any?
  end

  test 'AI response time under concurrent load' do
    puts "\n=== AI Response Time Under Concurrent Load ==="

    concurrent_requests = 5
    test_queries = [
      'Запиши на диагностику',
      'Сколько стоит ремонт?',
      'Когда открыто?',
      'Спасибо',
      'Пока'
    ]

    threads = []
    results = []

    concurrent_requests.times do |i|
      threads << Thread.new do
        thread_results = {
          thread_id: i,
          successful_requests: 0,
          failed_requests: 0,
          response_times: [],
          total_time: 0
        }

        test_queries.each_with_index do |query, query_index|
          begin
            VCR.use_cassette "ai_concurrent_#{i}_#{query_index}", record: :new_episodes do
              start_time = Time.current

              post telegram_webhook_path, params: telegram_message(query)

              response_time = Time.current - start_time
              thread_results[:response_times] << response_time
              thread_results[:total_time] += response_time

              if response.successful?
                thread_results[:successful_requests] += 1
              else
                thread_results[:failed_requests] += 1
              end
            end
          rescue => e
            thread_results[:failed_requests] += 1
            puts "Thread #{i} query #{query_index} failed: #{e.message}"
          end
        end

        results << thread_results
      end
    end

    threads.each(&:join)

    # Analyze concurrent performance
    total_successful = results.sum { |r| r[:successful_requests] }
    total_failed = results.sum { |r| r[:failed_requests] }
    all_response_times = results.flat_map { |r| r[:response_times] }

    if all_response_times.any?
      avg_response_time = (all_response_times.sum / all_response_times.size).round(3)
      max_response_time = all_response_times.max.round(3)
      min_response_time = all_response_times.min.round(3)
    else
      avg_response_time = max_response_time = min_response_time = 0
    end

    puts "\nConcurrent Load Results:"
    puts "  Concurrent Threads: #{concurrent_requests}"
    puts "  Requests per Thread: #{test_queries.length}"
    puts "  Total Successful: #{total_successful}"
    puts "  Total Failed: #{total_failed}"
    puts "  Success Rate: #{(total_successful.to_f / (total_successful + total_failed) * 100).round(1)}%"
    puts "  Average Response Time: #{avg_response_time}s"
    puts "  Min Response Time: #{min_response_time}s"
    puts "  Max Response Time: #{max_response_time}s"

    assert total_successful >= concurrent_requests * test_queries.length * 0.7,
           "Too many concurrent failures: #{total_failed}"
    assert avg_response_time < 10.0,
           "Concurrent average response time too high: #{avg_response_time}s" if all_response_times.any?
  end

  test 'AI response quality vs performance trade-off' do
    puts "\n=== AI Response Quality vs Performance Trade-off ==="

    # Test with different system prompts or configurations
    test_scenarios = [
      { name: 'Fast Response', message: 'Да', expected_max_time: 2.0 },
      { name: 'Simple Question', message: 'Когда открыто?', expected_max_time: 5.0 },
      { name: 'Complex Booking', message: 'Запиши на диагностику Toyota на завтра в 10 утра', expected_max_time: 15.0 },
      { name: 'Price Inquiry', message: 'Сколько стоит полный ТО для ВАЗ 2114?', expected_max_time: 10.0 }
    ]

    performance_results = []

    test_scenarios.each_with_index do |scenario, index|
      puts "Testing scenario: #{scenario[:name]}"

      response_times = []
      success_count = 0

      # Test each scenario multiple times for consistency
      3.times do |attempt|
        begin
          VCR.use_cassette "ai_quality_performance_#{index}_#{attempt}", record: :new_episodes do
            start_time = Time.current

            post telegram_webhook_path, params: telegram_message(scenario[:message])

            response_time = Time.current - start_time
            response_times << response_time

            if response.successful?
              success_count += 1
            end
          end
        rescue => e
          puts "  Attempt #{attempt + 1} failed: #{e.message}"
        end
      end

      if response_times.any?
        avg_time = (response_times.sum / response_times.size).round(3)
        max_time = response_times.max.round(3)

        within_threshold = avg_time <= scenario[:expected_max_time]

        performance_results << {
          scenario: scenario[:name],
          avg_time: avg_time,
          max_time: max_time,
          success_rate: success_count,
          expected_max: scenario[:expected_max_time],
          within_threshold: within_threshold
        }

        puts "  Average Time: #{avg_time}s (expected: ≤#{scenario[:expected_max_time]}s)"
        puts "  Max Time: #{max_time}s"
        puts "  Success Rate: #{success_count}/3"
        puts "  Within Threshold: #{within_threshold ? '✓' : '✗'}"
      end
    end

    # Analyze quality vs performance
    within_threshold_count = performance_results.count { |r| r[:within_threshold] }
    performance_score = (within_threshold_count.to_f / performance_results.size * 100).round(1)

    puts "\nQuality vs Performance Results:"
    puts "  Scenarios Within Threshold: #{within_threshold_count}/#{performance_results.length}"
    puts "  Performance Score: #{performance_score}%"

    assert performance_score >= 75.0,
           "Performance score too low: #{performance_score}%"
  end

  test 'AI response time stability over multiple requests' do
    puts "\n=== AI Response Time Stability Test ==="

    test_message = 'Хочу записаться на диагностику'
    response_times = []
    failure_count = 0

    # Send same message multiple times to test consistency
    20.times do |i|
      begin
        VCR.use_cassette "ai_stability_#{i}", record: :new_episodes do
          start_time = Time.current

          post telegram_webhook_path, params: telegram_message(test_message)

          response_time = Time.current - start_time

          if response.successful?
            response_times << response_time
            print "." if (i + 1) % 5 == 0
          else
            failure_count += 1
            print "F"
          end
        end
      rescue => e
        failure_count += 1
        print "E"
      end
    end
    puts

    # Calculate stability metrics
    if response_times.any?
      avg_time = (response_times.sum / response_times.size).round(3)
      min_time = response_times.min.round(3)
      max_time = response_times.max.round(3)

      # Calculate standard deviation
      variance = response_times.sum { |time| (time - avg_time) ** 2 } / response_times.size
      std_dev = Math.sqrt(variance).round(3)

      # Calculate coefficient of variation (CV = std_dev / mean)
      cv = (std_dev / avg_time * 100).round(1)

      # Determine outliers (more than 2 standard deviations from mean)
      outliers = response_times.select { |time| (time - avg_time).abs > 2 * std_dev }
      outlier_percentage = (outliers.length.to_f / response_times.size * 100).round(1)
    else
      avg_time = min_time = max_time = std_dev = cv = outlier_percentage = 0
    end

    puts "Stability Test Results:"
    puts "  Total Requests: #{20}"
    puts "  Successful: #{response_times.length}"
    puts "  Failed: #{failure_count}"
    puts "  Average Response Time: #{avg_time}s"
    puts "  Min Response Time: #{min_time}s"
    puts "  Max Response Time: #{max_time}s"
    puts "  Standard Deviation: #{std_dev}s"
    puts "  Coefficient of Variation: #{cv}%"
    puts "  Outliers (>2σ): #{outliers.length} (#{outlier_percentage}%)"

    # Stability assertions
    assert response_times.length >= 15,
           "Too many failures: #{failure_count}/20"
    assert cv < 50.0,
           "Response times too variable (CV: #{cv}%)" if response_times.any?
    assert outlier_percentage < 20.0,
           "Too many outliers: #{outlier_percentage}%" if response_times.any?
    assert max_time < 20.0,
           "Maximum response time too high: #{max_time}s" if response_times.any?
  end

  test 'AI response time degradation under system load' do
    puts "\n=== AI Response Time Degradation Test ==="

    # Test response times with increasing background load
    load_levels = [
      { name: 'No Load', concurrent_bg_requests: 0 },
      { name: 'Light Load', concurrent_bg_requests: 5 },
      { name: 'Medium Load', concurrent_bg_requests: 10 },
      { name: 'Heavy Load', concurrent_bg_requests: 20 }
    ]

    degradation_results = []

    load_levels.each do |load_level|
      puts "Testing under #{load_level[:name]} (#{load_level[:concurrent_bg_requests]} background requests)"

      # Create background load
      bg_threads = []
      load_level[:concurrent_bg_requests].times do |i|
        bg_threads << Thread.new do
          # Simulate background processing
          5.times do |j|
            AnalyticsJob.perform_now({
              event_name: AnalyticsService::Events::RESPONSE_TIME,
              chat_id: 999999 + i * 100 + j,
              properties: { test: 'background_load' },
              occurred_at: Time.current,
              session_id: "bg_session_#{i}_#{j}"
            })
            sleep 0.1
          end
        end
      end

      # Test main AI response under load
      response_times = []
      test_query = 'Хочу записаться на ТО'

      3.times do |attempt|
        begin
          VCR.use_cassette "ai_degradation_#{load_level[:name].downcase.gsub(' ', '_')}_#{attempt}", record: :new_episodes do
            start_time = Time.current

            post telegram_webhook_path, params: telegram_message(test_query)

            response_time = Time.current - start_time
            response_times << response_time if response.successful?
          end
        rescue => e
          puts "    Attempt #{attempt + 1} failed: #{e.message}"
        end
      end

      # Wait for background threads to complete
      bg_threads.each(&:join)

      if response_times.any?
        avg_time = (response_times.sum / response_times.size).round(3)
        max_time = response_times.max.round(3)

        degradation_results << {
          load_level: load_level[:name],
          bg_requests: load_level[:concurrent_bg_requests],
          avg_time: avg_time,
          max_time: max_time,
          success_count: response_times.length
        }

        puts "  Average Response Time: #{avg_time}s"
        puts "  Max Response Time: #{max_time}s"
        puts "  Success Rate: #{response_times.length}/3"
      else
        puts "  All requests failed"
      end
    end

    # Analyze degradation
    if degradation_results.length >= 2
      baseline_avg = degradation_results.first[:avg_time]
      heavy_load_avg = degradation_results.last[:avg_time]

      if baseline_avg > 0
        degradation_percentage = ((heavy_load_avg - baseline_avg) / baseline_avg * 100).round(1)

        puts "\nDegradation Analysis:"
        puts "  Baseline Avg Time: #{baseline_avg}s"
        puts "  Heavy Load Avg Time: #{heavy_load_avg}s"
        puts "  Performance Degradation: #{degradation_percentage}%"

        # Performance should not degrade too much
        assert degradation_percentage < 100.0,
               "Excessive performance degradation: #{degradation_percentage}%"
      end
    end

    # All scenarios should have some successful responses
    assert degradation_results.all? { |r| r[:success_count] > 0 },
           "All load scenarios should have at least some successful responses"
  end
end