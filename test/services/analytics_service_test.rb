# frozen_string_literal: true

require 'test_helper'

# Тесты для AnalyticsService
#
# Проверяет корректность трекинга аналитических событий
class AnalyticsServiceTest < ActiveSupport::TestCase
  setup do
    Rails.application.eager_load!
    @chat_id = 12346  # Используем другой ID чтобы избежать конфликтов
    @basic_properties = { platform: 'telegram', user_id: 2, message_type: 'text' }
    # Включаем аналитику для тестов
    Rails.application.config.analytics_enabled = true
    ENV['FORCE_ANALYTICS'] = 'true'
  end

  teardown do
    ENV.delete('FORCE_ANALYTICS')
    AnalyticsEvent.delete_all # Очищаем базу между тестами
  end

  test "tracks valid event successfully" do
    assert_difference 'AnalyticsJob.queue_adapter.enqueued_jobs.count', 1 do
      AnalyticsService.track(
        AnalyticsService::Events::DIALOG_STARTED,
        chat_id: @chat_id,
        properties: @basic_properties
      )
    end
  end

  test "does not track invalid event without required properties" do
    assert_no_difference 'AnalyticsEvent.count' do
      AnalyticsService.track(
        AnalyticsService::Events::BOOKING_CREATED,
        chat_id: @chat_id,
        properties: {} # Missing required booking_id
      )
    end
  end

  test "tracks response time event correctly" do
    assert_difference 'AnalyticsJob.queue_adapter.enqueued_jobs.count', 1 do
      AnalyticsService.track_response_time(@chat_id, 1500, 'deepseek-chat')
    end
  end

  test "tracks conversion event correctly" do
    conversion_data = {
      booking_id: 42,
      services_count: 2,
      estimated_total: 15000,
      processing_time_ms: 500,
      user_segment: 'premium'
    }

    assert_difference 'AnalyticsJob.queue_adapter.enqueued_jobs.count', 1 do
      AnalyticsService.track_conversion(
        AnalyticsService::Events::BOOKING_CREATED,
        @chat_id,
        conversion_data
      )
    end
  end

  test "tracks error event correctly" do
    error = StandardError.new('Test error')
    context = { chat_id: @chat_id, context: 'test_context' }

    assert_difference 'AnalyticsJob.queue_adapter.enqueued_jobs.count', 1 do
      AnalyticsService.track_error(error, context)
    end
  end

  test "validates event properties correctly" do
    # DIALOG_STARTED with missing required properties should be invalid
    assert_not AnalyticsService.send(:validate_event_data,
      AnalyticsService::Events::DIALOG_STARTED, {})

    # DIALOG_STARTED with all required properties should be valid
    assert AnalyticsService.send(:validate_event_data,
      AnalyticsService::Events::DIALOG_STARTED,
      { platform: 'telegram', user_id: 123, message_type: 'text' })
  end
end