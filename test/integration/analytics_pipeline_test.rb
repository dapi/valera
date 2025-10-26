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

  test "complete analytics pipeline from webhook to event storage" do
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

  # test "analytics handles booking creation with conversion tracking" do
  #   # Create user and chat first
  #   user = TelegramUser.create!(
  #     id: @chat_id,
  #     first_name: 'Test',
  #     username: 'testuser'
  #   )
  #   chat = Chat.create!(telegram_user: user)

  #   # Prepare booking tool data
  #   booking_data = {
  #     customer_name: 'Иван Иванов',
  #     customer_phone: '+7(999)123-45-67',
  #     car_brand: 'Toyota',
  #     car_model: 'Camry',
  #     required_services: 'Кузовной ремонт, покраска бампера',
  #     cost_calculation: '15000 рублей',
  #     dialog_context: 'Запись на диагностику',
  #     details: 'Заявка на кузовной ремонт'
  #   }

  #   # Execute booking tool
  #   tool = BookingTool.new(telegram_user: user, chat: chat)
  #   result = tool.execute(**booking_data)

  #   # Process background jobs
  #   perform_enqueued_jobs

  #   # Check analytics events
  #   booking_events = AnalyticsEvent.where(
  #     event_name: AnalyticsService::Events::BOOKING_CREATED,
  #     chat_id: @chat_id
  #   )
  #   assert_equal 1, booking_events.count

  #   booking_event = booking_events.first
  #   assert booking_event.properties['booking_id'].present?
  #   assert booking_event.properties['services_count'].present?
  #   assert booking_event.properties['user_segment'].present?
  #   assert_equal 'Иван Иванов', booking_event.properties['customer_name']
  #   assert_equal 'Toyota', booking_event.properties['car_brand']
  # end

  # test "analytics gracefully handles errors without breaking main functionality" do
  #   # Mock analytics to fail
  #   AnalyticsService.stubs(:track).raises(StandardError.new('Analytics failed'))

  #   # Main webhook should still work
  #   post telegram_webhook_url, params: @sample_message, as: :json

  #   assert_response :success

  #   # Restore original method
  #   AnalyticsService.unstub(:track)
  # end

  # test "performance test: handles multiple events efficiently" do
  #   AnalyticsEvent.delete_all

  #   start_time = Time.current

  #   # Simulate multiple concurrent requests
  #   10.times do |i|
  #     message = @sample_message.dup
  #     message['text'] = "Тестовое сообщение #{i}"

  #     post telegram_webhook_url, params: message, as: :json
  #   end

  #   # Process all background jobs
  #   perform_enqueued_jobs

  #   total_time = Time.current - start_time

  #   # Should complete within reasonable time (less than 5 seconds for 10 requests)
  #   assert total_time < 5.seconds, "Too slow: #{total_time} seconds for 10 requests"

  #   # Check that all events were created
  #   dialog_events = AnalyticsEvent.where(
  #     event_name: AnalyticsService::Events::DIALOG_STARTED
  #   )
  #   response_events = AnalyticsEvent.where(
  #     event_name: AnalyticsService::Events::RESPONSE_TIME
  #   )

  #   assert_equal 10, dialog_events.count
  #   assert_equal 10, response_events.count
  # end

  # test "analytics respects session tracking across multiple messages" do
  #   AnalyticsEvent.delete_all

  #   # Send first message
  #   post telegram_webhook_url, params: @sample_message, as: :json
  #   perform_enqueued_jobs

  #   first_event = AnalyticsEvent.where(
  #     event_name: AnalyticsService::Events::DIALOG_STARTED,
  #     chat_id: @chat_id
  #   ).first

  #   # Send second message (should not create new dialog start)
  #   second_message = @sample_message.dup
  #   second_message['text'] = 'Хочу узнать стоимость'
  #   second_message['message_id'] = 124

  #   post telegram_webhook_url, params: second_message, as: :json
  #   perform_enqueued_jobs

  #   # Should still have only one dialog start event
  #   dialog_events = AnalyticsEvent.where(
  #     event_name: AnalyticsService::Events::DIALOG_STARTED,
  #     chat_id: @chat_id
  #   )
  #   assert_equal 1, dialog_events.count

  #   # Response time events should be different
  #   response_events = AnalyticsEvent.where(
  #     event_name: AnalyticsService::Events::RESPONSE_TIME,
  #     chat_id: @chat_id
  #   )
  #   assert_equal 2, response_events.count
  # end

  # test "analytics correctly categorizes message types" do
  #   AnalyticsEvent.delete_all

  #   # Test different message types
  #   booking_message = @sample_message.dup
  #   booking_message['text'] = 'Хочу записаться на осмотр'
  #   booking_message['message_id'] = 201

  #   post telegram_webhook_url, params: booking_message, as: :json

  #   dialog_event = AnalyticsEvent.where(
  #     chat_id: @chat_id,
  #     event_name: AnalyticsService::Events::DIALOG_STARTED
  #   ).first

  #   assert_not_nil dialog_event, "Dialog event should be created"
  #   assert_equal 'booking_intent', dialog_event.properties['message_type']
  # end
end