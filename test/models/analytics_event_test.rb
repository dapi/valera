# frozen_string_literal: true

require 'test_helper'

class AnalyticsEventTest < ActiveSupport::TestCase
  test 'fixture is valid and persisted' do
    event = analytics_events(:one)
    assert event.valid?
    assert event.persisted?
  end

  test 'has required attributes' do
    event = analytics_events(:one)
    assert_not_nil event.event_name
    assert_not_nil event.chat_id
    assert_not_nil event.occurred_at
    assert_not_nil event.properties
  end

  test 'stores JSONB properties correctly' do
    event = analytics_events(:one)
    assert_equal 'telegram', event.properties['platform']
    assert_equal 1, event.properties['user_id']
    assert_equal 'general', event.properties['message_type']
  end

  test 'stores response time data correctly' do
    event = analytics_events(:two)
    assert_equal 1500, event.properties['duration_ms']
    assert_equal 'deepseek-chat', event.properties['model_used']
    assert event.properties['timestamp'].present?
  end

  test 'stores booking data correctly' do
    event = analytics_events(:booking_event)
    assert_equal 1, event.properties['booking_id']
    assert_equal 2, event.properties['services_count']
    assert_equal 15000, event.properties['estimated_total']
    assert_equal 'Тестовый Клиент', event.properties['customer_name']
  end

  test 'default platform is telegram' do
    event = AnalyticsEvent.new(
      event_name: 'test_event',
      chat_id: 12345,
      occurred_at: Time.current
    )
    assert_equal 'telegram', event.platform
  end

  test 'validates event name presence' do
    event = AnalyticsEvent.new(
      chat_id: 12345,
      occurred_at: Time.current
    )
    assert_not event.valid?
    assert event.errors[:event_name].any?
  end

  test 'validates chat_id presence' do
    event = AnalyticsEvent.new(
      event_name: 'test_event',
      occurred_at: Time.current
    )
    assert_not event.valid?
    assert event.errors[:chat_id].any?
  end

  test 'validates occurred_at presence' do
    event = AnalyticsEvent.new(
      event_name: 'test_event',
      chat_id: 12345
    )
    assert_not event.valid?
    assert event.errors[:occurred_at].any?
  end

  test 'scopes work correctly' do
    # Test by_event scope
    dialog_events = AnalyticsEvent.by_event('ai_dialog_started')
    assert dialog_events.include?(analytics_events(:one))
    assert_not dialog_events.include?(analytics_events(:two))

    # Test by_chat scope
    chat_events = AnalyticsEvent.by_chat(943084337)
    assert chat_events.include?(analytics_events(:one))
    assert_not chat_events.include?(analytics_events(:two))

    # Test recent scope (1 hour)
    recent_events = AnalyticsEvent.recent(2.hours)
    assert recent_events.include?(analytics_events(:one))
    assert recent_events.include?(analytics_events(:two))
    assert recent_events.include?(analytics_events(:booking_event))
  end

  test 'event name length validation' do
    # Test within limit
    event = analytics_events(:one)
    event.event_name = 'a' * 50
    assert event.valid?

    # Test exceeding limit
    event.event_name = 'a' * 51
    assert_not event.valid?
    assert event.errors[:event_name].any?
  end
end
