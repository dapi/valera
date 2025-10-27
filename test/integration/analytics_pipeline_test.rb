# frozen_string_literal: true

require 'test_helper'

# Интеграционные тесты для проверки полного pipeline аналитики
#
# Проверяет полный цикл работы аналитики:
# - Получение webhook от Telegram
# - Обработка сообщения AI
# - Трекинг событий
# - Создание заявок
# - Сохранение в базу данных
class AnalyticsPipelineTest < ActionDispatch::IntegrationTest
  include TelegramSupport

  def telegram_message(text = 'test message')
    from = { id: 943_084_337, is_bot: false, first_name: 'Danil', last_name: 'Pismenny', username: 'pismenny',
             language_code: 'en', is_premium: true }
    chat = { id: 943_084_337, first_name: 'Danil', last_name: 'Pismenny', username: 'pismenny', type: 'private' }
    {
      update_id: 178_271_355,
      message: { message_id: 323, from: from, chat: chat, date: 1_761_379_722, text: text }
    }
  end

  setup do
    @help_chat = RubyLLM.chat
    @help_chat.with_instructions Rails.root.join('./test/user-system-prompt.txt').read
  end

  private

  def post_message(text)
    post telegram_webhook_path, params: telegram_message(text)
  end

  def cassete_name
    [
      self.class.name.to_s,
      name,
      ApplicationConfig.llm_provider,
      ApplicationConfig.llm_model,
      "system-prompt-#{ApplicationConfig.system_prompt_md5}"
    ].join('/')
  end

  test 'complete analytics pipeline from webhook to event storage' do
    # Ensure clean state
    AnalyticsEvent.delete_all

    VCR.use_cassette cassete_name, record: :new_episodes do
      # Send initial message to trigger dialog
      post_message 'Здравствуйте, хочу записаться на кузовной ремонт'

      # Process background jobs
      perform_enqueued_jobs

      # Check that dialog start event was tracked
      dialog_events = AnalyticsEvent.where(
        event_name: AnalyticsService::Events::DIALOG_STARTED,
        chat_id: 943_084_337
      )
      assert_equal 1, dialog_events.count

      dialog_event = dialog_events.first
      assert_equal 'telegram', dialog_event.properties['platform']
      assert_not_nil dialog_event.properties['message_type']
      assert_not_nil dialog_event.session_id

      # Check that response time was tracked
      response_events = AnalyticsEvent.where(
        event_name: AnalyticsService::Events::RESPONSE_TIME,
        chat_id: 943_084_337
      )
      assert_equal 1, response_events.count

      response_event = response_events.first
      assert response_event.properties['duration_ms'].present?
      assert_equal 'deepseek-chat', response_event.properties['model_used']
    end
  end

  test 'analytics handles booking creation with conversion tracking' do
    # Create user and chat first
    user = TelegramUser.create!(
      id: 943_084_337,
      first_name: 'Danil',
      username: 'pismenny'
    )
    chat = Chat.create!(telegram_user: user)

    # Prepare booking tool data
    booking_data = {
      customer_name: 'Иван Иванов',
      customer_phone: '+7(999)123-45-67',
      car_brand: 'Toyota',
      car_model: 'Camry',
      required_services: 'Кузовной ремонт, покраска бампера',
      cost_calculation: '15000 рублей',
      dialog_context: 'Запись на диагностику',
      details: 'Заявка на кузовной ремонт'
    }

    # Execute booking tool
    tool = BookingTool.new(telegram_user: user, chat: chat)
    result = tool.execute(**booking_data)

    # Process background jobs
    perform_enqueued_jobs

    # Check analytics events
    booking_events = AnalyticsEvent.where(
      event_name: AnalyticsService::Events::BOOKING_CREATED,
      chat_id: 943_084_337
    )
    assert_equal 1, booking_events.count

    booking_event = booking_events.first
    assert booking_event.properties['booking_id'].present?
    assert booking_event.properties['services_count'].present?
    assert booking_event.properties['user_segment'].present?
    assert_equal 'Иван Иванов', booking_event.properties['customer_name']
    assert_equal 'Toyota', booking_event.properties['car_brand']
  end

  test 'analytics gracefully handles errors without breaking main functionality' do
    # Mock analytics to fail
    AnalyticsService.stubs(:track).raises(StandardError.new('Analytics failed'))

    # Main webhook should still work
    VCR.use_cassette cassete_name, record: :new_episodes do
      post_message 'Test message during analytics failure'
    end

    assert_response :success

    # Restore original method
    AnalyticsService.unstub(:track)
  end

  test 'performance test: handles multiple events efficiently' do
    AnalyticsEvent.delete_all

    start_time = Time.current

    # Simulate multiple concurrent requests
    VCR.use_cassette "#{cassete_name}_bulk", record: :new_episodes do
      5.times do |i|
        post_message "Тестовое сообщение #{i}"
      end
    end

    # Process all background jobs
    perform_enqueued_jobs

    total_time = Time.current - start_time

    # Should complete within reasonable time (less than 10 seconds for 5 requests)
    assert total_time < 10.seconds, "Too slow: #{total_time} seconds for 5 requests"

    # Check that all events were created
    dialog_events = AnalyticsEvent.where(
      event_name: AnalyticsService::Events::DIALOG_STARTED
    )
    response_events = AnalyticsEvent.where(
      event_name: AnalyticsService::Events::RESPONSE_TIME
    )

    assert_equal 5, dialog_events.count
    assert_equal 5, response_events.count
  end

  test 'analytics respects session tracking across multiple messages' do
    AnalyticsEvent.delete_all

    # Send first message
    VCR.use_cassette "#{cassete_name}_session1", record: :new_episodes do
      post_message 'Первое сообщение'
    end
    perform_enqueued_jobs

    first_event = AnalyticsEvent.where(
      event_name: AnalyticsService::Events::DIALOG_STARTED,
      chat_id: 943_084_337
    ).first

    # Send second message (should not create new dialog start)
    VCR.use_cassette "#{cassete_name}_session2", record: :new_episodes do
      post_message 'Хочу узнать стоимость'
    end
    perform_enqueued_jobs

    # Should still have only one dialog start event
    dialog_events = AnalyticsEvent.where(
      event_name: AnalyticsService::Events::DIALOG_STARTED,
      chat_id: 943_084_337
    )
    assert_equal 1, dialog_events.count

    # Response time events should be different
    response_events = AnalyticsEvent.where(
      event_name: AnalyticsService::Events::RESPONSE_TIME,
      chat_id: 943_084_337
    )
    assert_equal 2, response_events.count
  end

  test 'analytics correctly categorizes message types' do
    AnalyticsEvent.delete_all

    # Test booking intent message
    VCR.use_cassette "#{cassete_name}_booking_intent", record: :new_episodes do
      post_message 'Хочу записаться на осмотр'
    end

    dialog_event = AnalyticsEvent.where(
      chat_id: 943_084_337,
      event_name: AnalyticsService::Events::DIALOG_STARTED
    ).first

    assert_not_nil dialog_event, "Dialog event should be created"
    assert_equal 'booking_intent', dialog_event.properties['message_type']
  end

  test 'analytics handles VCR cassettes with proper data filtering' do
    AnalyticsEvent.delete_all

    cassette_name = 'test_vcr_filtering'

    VCR.use_cassette cassette_name, record: :new_episodes do
      post_message 'Тестовое сообщение для VCR'
    end

    perform_enqueued_jobs

    # Verify events were created during VCR recording
    assert AnalyticsEvent.where(
      chat_id: 943_084_337,
      event_name: AnalyticsService::Events::DIALOG_STARTED
    ).exists?

    # Verify sensitive data is filtered from cassette
    cassette_path = Rails.root.join('test', 'cassettes', "#{cassette_name}.yml")
    if File.exist?(cassette_path)
      cassette_content = File.read(cassette_path)
      refute_includes cassette_content, 'Bearer', 'Sensitive data should be filtered from cassette'
    end
  end

  test 'analytics tracks conversion funnel properly' do
    AnalyticsEvent.delete_all

    VCR.use_cassette "#{cassete_name}_funnel", record: :new_episodes do
      # Initial booking intent
      post_message 'Хочу записаться на ремонт'
      perform_enqueued_jobs

      # Follow-up question
      post_message 'На завтра, в 10 утра'
      perform_enqueued_jobs
    end

    # Check funnel progression
    dialog_started = AnalyticsEvent.where(
      event_name: AnalyticsService::Events::DIALOG_STARTED,
      chat_id: 943_084_337
    ).count

    response_times = AnalyticsEvent.where(
      event_name: AnalyticsService::Events::RESPONSE_TIME,
      chat_id: 943_084_337
    ).count

    assert dialog_started >= 1
    assert response_times >= 2

    # Test conversion funnel query
    funnel_data = AnalyticsEvent.conversion_funnel(1.hour.ago, Time.current)
    assert funnel_data.present?
  end

  test 'analytics handles concurrent requests with proper session isolation' do
    AnalyticsEvent.delete_all

    threads = []
    chat_ids = [111111111, 222222222, 333333333]

    threads << Thread.new do
      VCR.use_cassette "#{cassette_name}_thread1", record: :new_episodes do
        post_with_chat_id(chat_ids[0], 'Thread 1 message')
      end
    end

    threads << Thread.new do
      VCR.use_cassette "#{cassette_name}_thread2", record: :new_episodes do
        post_with_chat_id(chat_ids[1], 'Thread 2 message')
      end
    end

    threads << Thread.new do
      VCR.use_cassette "#{cassette_name}_thread3", record: :new_episodes do
        post_with_chat_id(chat_ids[2], 'Thread 3 message')
      end
    end

    threads.each(&:join)
    perform_enqueued_jobs

    # Each chat should have its own session
    chat_ids.each do |chat_id|
      events = AnalyticsEvent.where(chat_id: chat_id)
      assert events.count >= 1, "Chat #{chat_id} should have events"
      assert events.pluck(:session_id).uniq.count == 1, "Chat #{chat_id} should have single session"
    end
  end

  private

  def post_with_chat_id(chat_id, message_text)
    from = { id: chat_id, is_bot: false, first_name: 'Test', last_name: 'User', username: 'testuser' }
    chat = { id: chat_id, first_name: 'Test', last_name: 'User', username: 'testuser', type: 'private' }
    message = {
      update_id: 178271355 + chat_id,
      message: { message_id: 323, from: from, chat: chat, date: Time.current.to_i, text: message_text }
    }
    post telegram_webhook_path, params: message
  end
end
