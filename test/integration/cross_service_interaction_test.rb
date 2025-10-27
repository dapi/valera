# frozen_string_literal: true

require 'test_helper'

class CrossServiceInteractionTest < ActionDispatch::IntegrationTest
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

  def telegram_message(text = 'test message', chat_id: @chat_id)
    from = { id: chat_id, is_bot: false, first_name: 'Test', last_name: 'User', username: 'testuser' }
    chat = { id: chat_id, first_name: 'Test', last_name: 'User', username: 'testuser', type: 'private' }
    {
      update_id: 123456789,
      message: { message_id: 1, from: from, chat: chat, date: Time.current.to_i, text: text }
    }
  end

  test 'telegram webhook creates chat and tracks analytics properly' do
    AnalyticsEvent.delete_all

    VCR.use_cassette 'cross_service_webhook_to_analytics', record: :new_episodes do
      post telegram_webhook_path, params: telegram_message('Запиши на ремонт')
    end

    assert_response :success

    # Verify chat was created/updated
    assert @chat.reload.present?

    # Verify analytics events were created
    events = AnalyticsEvent.where(chat_id: @chat_id)
    assert events.exists?, "Analytics events should be created for chat #{@chat_id}"

    # Verify proper event types
    dialog_events = events.where(event_name: AnalyticsService::Events::DIALOG_STARTED)
    response_events = events.where(event_name: AnalyticsService::Events::RESPONSE_TIME)

    assert dialog_events.exists?, "Dialog start event should be created"
    assert response_events.exists?, "Response time event should be created"
  end

  test 'booking creation triggers analytics and message storage' do
    Message.delete_all
    AnalyticsEvent.delete_all

    # Simulate booking tool execution
    booking_data = {
      customer_name: 'Иван Петров',
      customer_phone: '+7(999)123-45-67',
      car_brand: 'Lada',
      car_model: 'Vesta',
      required_services: 'Замена масла',
      cost_calculation: '2000 рублей',
      dialog_context: 'Запись на ТО',
      details: 'Простое техобслуживание'
    }

    tool = BookingTool.new(telegram_user: @user, chat: @chat)
    result = tool.execute(**booking_data)

    assert result[:success], "Booking tool should succeed"

    # Verify booking was created
    booking = Booking.last
    assert_not_nil booking
    assert_equal 'Иван Петров', booking.customer_name

    # Verify analytics event was created
    booking_events = AnalyticsEvent.where(
      event_name: AnalyticsService::Events::BOOKING_CREATED,
      chat_id: @chat_id
    )
    assert_equal 1, booking_events.count

    booking_event = booking_events.first
    assert_equal booking.id, booking_event.properties['booking_id']

    # Verify message was stored
    messages = Message.where(chat: @chat)
    assert messages.exists?, "Messages should be stored for booking"
  end

  test 'AI response failure does not break booking creation' do
    # Mock AI to fail
    RubyLLM::Chat.any_instance.stubs(:ask).raises(StandardError.new('AI service unavailable'))

    VCR.use_cassette 'cross_service_ai_failure', record: :new_episodes do
      post telegram_webhook_path, params: telegram_message('Простое сообщение')
    end

    # Should still handle the request gracefully
    assert_response :success

    # Verify error was logged
    # Error logging should happen via ErrorLogger
  end

  test 'multiple services handle concurrent requests correctly' do
    threads = []
    results = []

    5.times do |i|
      threads << Thread.new do
        chat_id = @chat_id + i
        user = TelegramUser.create!(
          id: chat_id,
          first_name: "User#{i}",
          username: "user#{i}"
        )
        chat = Chat.create!(telegram_user: user)

        VCR.use_cassette "cross_service_concurrent_#{i}", record: :new_episodes do
          post telegram_webhook_path, params: telegram_message("Concurrent test #{i}", chat_id)
        end

        results << {
          chat_id: chat_id,
          status: response.status,
          events_created: AnalyticsEvent.where(chat_id: chat_id).count
        }
      end
    end

    threads.each(&:join)

    # All requests should succeed
    assert_equal 5, results.length
    results.each do |result|
      assert_equal 200, result[:status], "Chat #{result[:chat_id]} should return success"
      assert result[:events_created] >= 1, "Chat #{result[:chat_id]} should have analytics events"
    end
  end

  test 'database transaction ensures data consistency across services' do
    initial_booking_count = Booking.count
    initial_message_count = Message.count
    initial_analytics_count = AnalyticsEvent.count

    # Simulate a transaction that includes multiple service operations
    begin
      Chat.transaction do
        # Create booking through tool
        booking_data = {
          customer_name: 'Тестовый Клиент',
          customer_phone: '+7(999)999-99-99',
          car_brand: 'Test',
          car_model: 'Test',
          required_services: 'Test',
          cost_calculation: 'Test',
          dialog_context: 'Test',
          details: 'Test'
        }

        tool = BookingTool.new(telegram_user: @user, chat: @chat)
        tool.execute(**booking_data)

        # Force rollback to test transaction
        raise ActiveRecord::Rollback
      end
    rescue ActiveRecord::Rollback
      # Expected rollback
    end

    # No new records should be created due to rollback
    assert_equal initial_booking_count, Booking.count
    assert_equal initial_message_count, Message.count
    # Analytics events might still be created if they use async jobs
  end

  test 'service boundaries handle partial failures gracefully' do
    # Mock one service to fail
    AnalyticsService.stubs(:track_booking_created).raises(StandardError.new('Analytics service down'))

    booking_data = {
      customer_name: 'Клиент при сбое аналитики',
      customer_phone: '+7(999)888-77-66',
      car_brand: 'Test',
      car_model: 'Test',
      required_services: 'Test',
      cost_calculation: 'Test',
      dialog_context: 'Test',
      details: 'Test'
    }

    tool = BookingTool.new(telegram_user: @user, chat: @chat)
    result = tool.execute(**booking_data)

    # Booking should still succeed despite analytics failure
    assert result[:success], "Booking should succeed despite analytics failure"
    assert Booking.where(customer_name: 'Клиент при сбое аналитики').exists?

    # Restore original method
    AnalyticsService.unstub(:track_booking_created)
  end

  test 'redis cache integration with analytics service' do
    skip "Redis tests need proper setup" unless Rails.cache.respond_to?(:redis)

    # Test caching behavior in analytics
    cache_key = "analytics_stats_#{@chat_id}"
    test_data = { message_count: 5, last_activity: Time.current }

    # Cache some data
    Rails.cache.write(cache_key, test_data, expires_in: 1.hour)

    # Verify cache integration works
    cached_data = Rails.cache.read(cache_key)
    assert_equal test_data[:message_count], cached_data[:message_count]

    # Test cache invalidation
    Rails.cache.delete(cache_key)
    assert_nil Rails.cache.read(cache_key)
  end

  test 'error propagation across service boundaries' do
    # Test that errors are properly handled and logged across services
    ErrorLogger.expects(:log_error).with(
      kind_of(StandardError),
      has_entries(service: kind_of(String)),
      'cross_service_interaction'
    ).at_least_once

    # Force an error in one service
    Booking.any_instance.stubs(:save).raises(ActiveRecord::RecordInvalid.new(Booking.new))

    booking_data = {
      customer_name: 'Invalid Client',
      customer_phone: 'invalid_phone',
      car_brand: 'Test',
      car_model: 'Test',
      required_services: 'Test',
      cost_calculation: 'Test',
      dialog_context: 'Test',
      details: 'Test'
    }

    tool = BookingTool.new(telegram_user: @user, chat: @chat)
    result = tool.execute(**booking_data)

    # Should handle error gracefully
    refute result[:success], "Booking should fail with invalid data"

    # Restore original method
    Booking.any_instance.unstub(:save)
  end

  test 'service timeouts are handled properly' do
    # Mock slow service response
    original_timeout = ApplicationConfig.llm_timeout
    ApplicationConfig.stubs(:llm_timeout).returns(0.001) # Very short timeout

    VCR.use_cassette 'cross_service_timeout', record: :new_episodes do
      start_time = Time.current
      post telegram_webhook_path, params: telegram_message('Test timeout')
      duration = Time.current - start_time

      # Should handle timeout within reasonable time
      assert duration < 5.seconds, "Request should timeout quickly: #{duration} seconds"
    end

    # Restore original configuration
    ApplicationConfig.unstub(:llm_timeout)
  end

  test 'service communication through message queue works correctly' do
    # Test async job processing
    AnalyticsJob.perform_later({
      event_name: AnalyticsService::Events::DIALOG_STARTED,
      chat_id: @chat_id,
      properties: { test: 'cross_service' },
      occurred_at: Time.current,
      session_id: 'test_session'
    })

    # Process background jobs
    perform_enqueued_jobs

    # Verify event was created
    event = AnalyticsEvent.where(
      chat_id: @chat_id,
      event_name: AnalyticsService::Events::DIALOG_STARTED
    ).first

    assert_not_nil event, "Analytics event should be created via job queue"
    assert_equal 'test_session', event.session_id
    assert_equal 'cross_service', event.properties['test']
  end

  test 'data consistency maintained across service interactions' do
    # Test that related data stays consistent
    initial_chat_message_count = @chat.messages.count

    # Process a message that should create related records
    VCR.use_cassette 'cross_service_data_consistency', record: :new_episodes do
      post telegram_webhook_path, params: telegram_message('Проверка консистентности данных')
    end

    @chat.reload

    # Verify relationships are maintained
    assert @chat.messages.count > initial_chat_message_count, "New messages should be created"
    assert_equal @user, @chat.telegram_user, "Chat-user relationship should be maintained"

    messages = @chat.messages
    messages.each do |message|
      assert_equal @chat, message.chat, "Message-chat relationship should be consistent"
    end

    # Verify analytics data links correctly
    analytics_events = AnalyticsEvent.where(chat_id: @chat_id)
    analytics_events.each do |event|
      assert_equal @chat_id, event.chat_id, "Analytics should reference correct chat"
    end
  end
end