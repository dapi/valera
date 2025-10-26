# frozen_string_literal: true

require 'test_helper'

# Тесты для AnalyticsJob
#
# Проверяет корректность фоновой обработки аналитических событий
class AnalyticsJobTest < ActiveSupport::TestCase
  test 'uses correct queue' do
    assert_equal 'analytics', AnalyticsJob.queue_name
  end

  test 'creates analytics event successfully' do
    event_data = {
      event_name: 'dialog_started',
      chat_id: 12345,
      properties: { platform: 'telegram' },
      occurred_at: Time.current,
      session_id: 'test_session_123'
    }

    AnalyticsJob.perform_now(event_data)

    assert_equal 1, AnalyticsEvent.where(event_name: 'dialog_started').count
  end
end
