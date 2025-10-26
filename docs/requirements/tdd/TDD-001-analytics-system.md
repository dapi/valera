# Technical Design Document: TDD-001 - Analytics System Architecture

**Статус:** Draft
**Приоритет:** High
**Версия:** 1.0
**Создан:** 27.10.2025
**Автор:** Tech Lead
**Связанный FIP:** [FIP-001-analytics-system.md](../FIP-001-analytics-system.md)

## 🎯 Executive Summary

**Technical Challenge:** Реализовать систему сбора и аналитики метрик без влияния на производительность существующего AI-ассистента Valera.

**Solution Overview:** Rails-native analytics service с асинхронной обработкой событий, PostgreSQL для хранения данных и Metabase для визуализации.

## 🏗️ System Architecture

### **High-Level Architecture**
```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│  Telegram Bot   │───▶│ AnalyticsService │───▶│   PostgreSQL    │
│   Controller    │    │  (async track)   │    │  Analytics DB   │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                              │
                              ▼
                       ┌──────────────────┐
                       │  Solid Queue     │
                       │ (background)    │
                       └──────────────────┘
                              │
                              ▼
                       ┌──────────────────┐
                       │    Metabase     │
                       │   Dashboard     │
                       └──────────────────┘
```

### **Core Components:**

1. **AnalyticsService** - основной сервис для трекинга событий
2. **AnalyticsEvent** - ActiveRecord модель для хранения данных
3. **BackgroundProcessor** - асинхронная обработка событий
4. **Metabase** - BI система для дашбордов
5. **MonitoringService** - мониторинг производительности системы

## 📊 Database Design

### **AnalyticsEvent Model**

```ruby
# app/models/analytics_event.rb
class AnalyticsEvent < ApplicationRecord
  # Validations
  validates :event_name, presence: true, length: { maximum: 50 }
  validates :chat_id, presence: true, numericality: { only_integer: true }
  validates :occurred_at, presence: true

  # Scopes для эффективных запросов
  scope :by_event, ->(event) { where(event_name: event) }
  scope :by_chat, ->(chat_id) { where(chat_id: chat_id) }
  scope :recent, ->(hours = 24) { where('occurred_at >= ?', hours.hours.ago) }
  scope :in_period, ->(start_date, end_date) {
    where(occurred_at: start_date..end_date)
  }

  # JSONB helpers
  def self.properties_stats(keys = [])
    select("
      event_name,
      COUNT(*) as event_count,
      #{keys.map { |k| "AVG(CAST(properties->>'#{k}' as NUMERIC)) as avg_#{k}" }.join(', ')}
    ").group(:event_name)
  end
end
```

### **Migration Schema**

```ruby
# db/migrate/20251027000001_create_analytics_events.rb
class CreateAnalyticsEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :analytics_events do |t|
      t.string :event_name, null: false, limit: 50, index: true
      t.bigint :chat_id, null: false, index: true
      t.string :session_id, limit: 64, index: true
      t.jsonb :properties, default: {}, null: false
      t.timestamp :occurred_at, null: false, index: true
      t.string :platform, default: 'telegram', limit: 20

      t.timestamps
    end

    # Performance indexes for analytics queries
    add_index :analytics_events, [:chat_id, :event_name, :occurred_at],
              name: 'idx_analytics_funnel'
    add_index :analytics_events, [:occurred_at, :event_name],
              name: 'idx_analytics_timeline'
    add_index :analytics_events, [:event_name, :occurred_at],
              name: 'idx_analytics_events_by_type'

    # Partial indexes for common queries
    add_index :analytics_events, :occurred_at,
              name: 'idx_analytics_recent',
              where: "occurred_at >= (CURRENT_DATE - INTERVAL '30 days')"

    # GIN index for JSONB properties
    add_index :analytics_events, :properties, using: :gin
  end
end
```

## 🔧 Core Services Implementation

### **AnalyticsService**

```ruby
# app/services/analytics_service.rb
class AnalyticsService
  include ErrorLogger

  # Event constants for consistency
  module Events
    DIALOG_STARTED = 'ai_dialog_started'
    SERVICE_SUGGESTED = 'service_suggested'
    SERVICE_ADDED = 'service_added'
    CART_CONFIRMED = 'cart_confirmed'
    BOOKING_CREATED = 'booking_request_created'
    SUGGESTION_ACCEPTED = 'ai_suggestion_accepted'
    RESPONSE_TIME = 'ai_response_time'
    ERROR_OCCURRED = 'error_occurred'
  end

  # Properties validation schema
  REQUIRED_PROPERTIES = {
    Events::DIALOG_STARTED => [],
    Events::SERVICE_SUGGESTED => [:service_name, :confidence_score],
    Events::BOOKING_CREATED => [:booking_id, :services_count, :estimated_total],
    Events::RESPONSE_TIME => [:duration_ms, :model_used]
  }.freeze

  class << self
    def track(event_name, chat_id:, properties: {}, occurred_at: Time.current)
      return unless tracking_enabled?

      # Validate event data
      return unless validate_event_data(event_name, properties)

      # Process asynchronously to avoid blocking main flow
      AnalyticsJob.perform_later(
        event_name: event_name,
        chat_id: chat_id,
        properties: properties,
        occurred_at: occurred_at,
        session_id: generate_session_id(chat_id)
      )
    rescue => e
      # Never break main functionality due to analytics errors
      log_error(e, {
        event_name: event_name,
        chat_id: chat_id,
        properties: properties
      })
    end

    def track_response_time(chat_id, duration_ms, model_used)
      track(
        Events::RESPONSE_TIME,
        chat_id: chat_id,
        properties: {
          duration_ms: duration_ms,
          model_used: model_used,
          timestamp: Time.current.to_f
        }
      )
    end

    def track_conversion(event_name, chat_id, conversion_data)
      track(event_name, chat_id: chat_id, properties: conversion_data)
    end

    private

    def tracking_enabled?
      Rails.env.production? || Rails.env.staging? || ENV['FORCE_ANALYTICS']
    end

    def validate_event_data(event_name, properties)
      required = REQUIRED_PROPERTIES[event_name] || []
      required.all? { |prop| properties.key?(prop) }
    end

    def generate_session_id(chat_id)
      # Generate daily session identifier for user journey tracking
      Digest::MD5.hexdigest("#{chat_id}-#{Date.current}-#{Rails.application.secret_key_base}")
    end
  end
end
```

### **Background Job Processing**

```ruby
# app/jobs/analytics_job.rb
class AnalyticsJob < ApplicationJob
  queue_as :analytics

  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform(event_data)
    AnalyticsEvent.create!(
      event_name: event_data[:event_name],
      chat_id: event_data[:chat_id],
      properties: event_data[:properties],
      occurred_at: event_data[:occurred_at],
      session_id: event_data[:session_id]
    )

    # Optional: Real-time alerts for critical events
    Analytics::AlertService.check_event(event_data) if critical_event?(event_data[:event_name])
  rescue => e
    # Use database connection fallback for critical events
    Analytics::FallbackService.store_event(event_data) if should_fallback?(e)
    raise e
  end

  private

  def critical_event?(event_name)
    [
      AnalyticsService::Events::BOOKING_CREATED,
      AnalyticsService::Events::ERROR_OCCURRED
    ].include?(event_name)
  end

  def should_fallback?(error)
    error.is_a?(ActiveRecord::ConnectionNotEstablished) ||
    error.is_a?(ActiveRecord::StatementInvalid)
  end
end
```

## 🔗 Integration Points

### **1. Telegram Webhook Integration**

```ruby
# app/controllers/telegram/webhook_controller.rb
class Telegram::WebhookController < ApplicationController
  before_action :setup_analytics_context

  def create
    chat_id = message.dig('chat', 'id')

    # Track dialog start
    if first_message_today?(chat_id)
      AnalyticsService.track(
        AnalyticsService::Events::DIALOG_STARTED,
        chat_id: chat_id,
        properties: {
          message_type: message_type,
          platform: 'telegram'
        }
      )
    end

    # Measure AI response time
    start_time = Time.current

    begin
      @response = telegram_assistant.process_message(message)

      # Track response time
      duration_ms = ((Time.current - start_time) * 1000).to_i
      AnalyticsService.track_response_time(chat_id, duration_ms, 'deepseek-chat')

    rescue => e
      AnalyticsService.track(
        AnalyticsService::Events::ERROR_OCCURRED,
        chat_id: chat_id,
        properties: {
          error_class: e.class.name,
          error_message: e.message,
          context: 'webhook_processing'
        }
      )
      raise e
    end

    render json: { status: 'ok' }
  end

  private

  def setup_analytics_context
    # Set request context for analytics
    RequestStore.store[:analytics_request_id] = SecureRandom.uuid
    RequestStore.store[:analytics_start_time] = Time.current
  end

  def first_message_today?(chat_id)
    AnalyticsEvent
      .by_chat(chat_id)
      .by_event(AnalyticsService::Events::DIALOG_STARTED)
      .where('occurred_at >= ?', Date.current)
      .exists?
  end
end
```

### **2. Booking Service Integration**

```ruby
# app/services/booking_service.rb
class BookingService
  def self.create_booking(chat_id, booking_data)
    start_time = Time.current

    # Core booking logic
    booking = Booking.create!(booking_data)

    # Analytics tracking
    AnalyticsService.track(
      AnalyticsService::Events::BOOKING_CREATED,
      chat_id: chat_id,
      properties: {
        booking_id: booking.id,
        services_count: booking.services.count,
        estimated_total: booking.estimated_total,
        processing_time_ms: ((Time.current - start_time) * 1000).to_i,
        user_segment: determine_user_segment(chat_id)
      }
    )

    # Send to managers
    Telegram::NotificationService.new_booking(booking)

    booking
  end

  private

  def self.determine_user_segment(chat_id)
    events_count = AnalyticsEvent.by_chat(chat_id).count

    case events_count
    when 1..2
      'new'
    when 3..10
      'engaged'
    else
      'returning'
    end
  end
end
```

### **3. Tool Call Handler Integration**

```ruby
# app/services/tool_call_service.rb
class ToolCallService
  def self.process_tool_call(tool_call, chat_id)
    case tool_call.function_name
    when 'create_booking'
      handle_booking_creation(tool_call.arguments, chat_id)
    when 'suggest_service'
      handle_service_suggestion(tool_call.arguments, chat_id)
    end
  end

  private

  def self.handle_service_suggestion(arguments, chat_id)
    service_name = arguments['service_name']
    confidence = arguments['confidence_score'] || 0.8

    # Track service suggestion
    AnalyticsService.track(
      AnalyticsService::Events::SERVICE_SUGGESTED,
      chat_id: chat_id,
      properties: {
        service_name: service_name,
        confidence_score: confidence,
        suggestion_type: 'ai_generated'
      }
    )

    # Execute actual suggestion logic
    # ...
  end
end
```

## 📈 Performance Considerations

### **1. Async Processing**
- **Solid Queue** для всех аналитических операций
- **Non-blocking** основной функциональности
- **Batch processing** для high-volume событий

### **2. Database Optimization**
```ruby
# Efficient analytics queries
class AnalyticsQueryService
  def self.conversion_funnel(start_date, end_date)
    AnalyticsEvent.connection.execute(<<-SQL)
      WITH funnel AS (
        SELECT
          chat_id,
          COUNT(CASE WHEN event_name = 'ai_dialog_started' THEN 1 END) as dialogs,
          COUNT(CASE WHEN event_name = 'booking_request_created' THEN 1 END) as bookings,
          MIN(CASE WHEN event_name = 'ai_dialog_started' THEN occurred_at END) as first_dialog,
          MIN(CASE WHEN event_name = 'booking_request_created' THEN occurred_at END) as first_booking
        FROM analytics_events
        WHERE occurred_at BETWEEN '#{start_date}' AND '#{end_date}'
        GROUP BY chat_id
      )
      SELECT
        COUNT(*) as total_chats,
        COUNT(CASE WHEN dialogs > 0 THEN 1 END) as chats_with_dialogs,
        COUNT(CASE WHEN bookings > 0 THEN 1 END) as chats_with_bookings,
        ROUND(COUNT(CASE WHEN bookings > 0 THEN 1 END) * 100.0 / COUNT(*), 2) as conversion_rate
      FROM funnel
    SQL
  end
end
```

### **3. Memory Management**
```ruby
# app/controllers/analytics_controller.rb
class AnalyticsController < ApplicationController
  def dashboard_data
    # Stream large datasets to avoid memory issues
    response.headers['Content-Type'] = 'application/json'

    self.response_body = Enumerator.new do |y|
      y << '{"data":['

      AnalyticsEvent
        .where(occurred_at: 30.days.ago..Time.current)
        .find_each(batch_size: 1000) do |event|
          y << event.to_json + ','
        end

      y << ']}'
    end
  end
end
```

## 🧪 Testing Strategy

### **1. Unit Tests**
```ruby
# test/services/analytics_service_test.rb
class AnalyticsServiceTest < ActiveSupport::TestCase
  test 'tracks valid event successfully' do
    assert_difference 'AnalyticsEvent.count', 1 do
      AnalyticsService.track(
        AnalyticsService::Events::DIALOG_STARTED,
        chat_id: 12345,
        properties: { platform: 'telegram' }
      )
    end
  end

  test 'does not track invalid event' do
    assert_no_difference 'AnalyticsEvent.count' do
      AnalyticsService.track(
        AnalyticsService::Events::BOOKING_CREATED,
        chat_id: 12345,
        properties: {} # Missing required booking_id
      )
    end
  end

  test 'processes events asynchronously' do
    AnalyticsService.expects(:track).with(has_entries(
      event_name: 'test_event',
      chat_id: 12345
    ))

    AnalyticsJob.perform_now(
      event_name: 'test_event',
      chat_id: 12345,
      properties: {},
      occurred_at: Time.current,
      session_id: 'test_session'
    )
  end
end
```

### **2. Integration Tests**
```ruby
# test/integration/analytics_tracking_test.rb
class AnalyticsTrackingTest < ActionDispatch::IntegrationTest
  test 'tracks complete user journey' do
    # Simulate user interaction
    post telegram_webhook_url, params: telegram_message

    # Check analytics events
    assert AnalyticsEvent.where(
      event_name: AnalyticsService::Events::DIALOG_STARTED
    ).exists?

    # Simulate booking creation
    # ... booking flow test

    assert AnalyticsEvent.where(
      event_name: AnalyticsService::Events::BOOKING_CREATED
    ).exists?
  end

  test 'does not break main functionality when analytics fails' do
    # Mock analytics to fail
    AnalyticsService.stubs(:track).raises(StandardError.new('Analytics failed'))

    # Main functionality should still work
    post telegram_webhook_url, params: telegram_message
    assert_response :success
  end
end
```

### **3. Performance Tests**
```ruby
# test/performance/analytics_performance_test.rb
class AnalyticsPerformanceTest < ActiveSupport::TestCase
  test 'handles high volume events efficiently' do
    start_time = Time.current

    1000.times do |i|
      AnalyticsJob.perform_now(
        event_name: 'test_event',
        chat_id: i,
        properties: { test: 'data' },
        occurred_at: Time.current,
        session_id: "session_#{i}"
      )
    end

    duration = Time.current - start_time
    assert duration < 5.seconds, "Too slow: #{duration} seconds for 1000 events"
  end

  test 'analytics queries are performant' do
    # Create test data
    create_test_analytics_data(days: 30, events_per_day: 100)

    start_time = Time.current

    result = AnalyticsQueryService.conversion_funnel(30.days.ago, Time.current)

    query_duration = Time.current - start_time
    assert query_duration < 1.second, "Query too slow: #{query_duration} seconds"
    assert_not_empty result
  end
end
```

## 🔒 Security & Privacy

### **1. Data Anonymization**
```ruby
# app/services/analytics_anonymization_service.rb
class AnalyticsAnonymizationService
  SENSITIVE_FIELDS = %w[phone_number email address full_name].freeze

  def self.anonymize_properties(properties)
    properties.dup.tap do |props|
      SENSITIVE_FIELDS.each do |field|
        if props.key?(field)
          props[field] = anonymize_value(props[field])
        end
      end
    end
  end

  private

  def self.anonymize_value(value)
    # Hash phone numbers, emails, etc.
    Digest::SHA256.hexdigest("#{value}-#{Rails.application.secret_key_base}")
  end
end
```

### **2. Data Retention Policy**
```ruby
# config/initializers/analytics_cleanup.rb
if Rails.env.production?
  # Schedule daily cleanup job
  AnalyticsCleanupJob.set(wait: 24.hours).perform_later
end

# app/jobs/analytics_cleanup_job.rb
class AnalyticsCleanupJob < ApplicationJob
  def perform
    # Delete events older than 12 months
    AnalyticsEvent
      .where('occurred_at < ?', 12.months.ago)
      .delete_all

    # Archive aggregated data if needed
    # ...
  end
end
```

## 📊 Metabase Integration

### **1. Docker Setup**
```yaml
# docker-compose.analytics.yml
version: '3.8'
services:
  metabase:
    image: metabase/metabase:latest
    ports:
      - "3000:3000"
    environment:
      - MB_DB_TYPE=postgres
      - MB_DB_DBNAME=#{Rails.env.test? ? 'valera_test' : 'valera_development'}
      - MB_DB_PORT=5432
      - MB_DB_USER=#{ENV['DATABASE_USERNAME']}
      - MB_DB_PASS=#{ENV['DATABASE_PASSWORD']}
      - MB_DB_HOST=host.docker.internal
      - MB_DB_CONNECTIONPOOL_SIZE=5
    volumes:
      - ./metabase-data:/metabase-data
    restart: unless-stopped
```

### **2. SQL Queries for Metabase**

**Conversion Funnel Query:**
```sql
-- Complete User Journey Funnel
WITH user_journey AS (
  SELECT
    chat_id,
    MIN(CASE WHEN event_name = 'ai_dialog_started' THEN occurred_at END) as first_dialog,
    MIN(CASE WHEN event_name = 'service_suggested' THEN occurred_at END) as first_suggestion,
    MIN(CASE WHEN event_name = 'booking_request_created' THEN occurred_at END) as first_booking,
    COUNT(DISTINCT event_name) as unique_events,
    COUNT(*) as total_events
  FROM analytics_events
  WHERE occurred_at >= DATE_TRUNC('week', CURRENT_DATE) - INTERVAL '4 weeks'
  GROUP BY chat_id
)
SELECT
  DATE_TRUNC('week', first_dialog) as week,
  COUNT(*) as total_chats,
  COUNT(CASE WHEN first_dialog IS NOT NULL THEN 1 END) as started_dialogs,
  COUNT(CASE WHEN first_suggestion IS NOT NULL THEN 1 END) as received_suggestions,
  COUNT(CASE WHEN first_booking IS NOT NULL THEN 1 END) as created_bookings,
  ROUND(
    COUNT(CASE WHEN first_booking IS NOT NULL THEN 1 END) * 100.0 /
    COUNT(CASE WHEN first_dialog IS NOT NULL THEN 1 END), 2
  ) as conversion_rate
FROM user_journey
WHERE first_dialog IS NOT NULL
GROUP BY DATE_TRUNC('week', first_dialog)
ORDER BY week DESC;
```

**Response Time Performance:**
```sql
-- AI Response Time Analysis
SELECT
  DATE_TRUNC('hour', occurred_at) as hour,
  AVG(CAST(properties->>'duration_ms' AS INTEGER)) as avg_response_time_ms,
  PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY CAST(properties->>'duration_ms' AS INTEGER)) as p50_response_time,
  PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY CAST(properties->>'duration_ms' AS INTEGER)) as p95_response_time,
  COUNT(*) as total_responses
FROM analytics_events
WHERE event_name = 'ai_response_time'
  AND occurred_at >= CURRENT_DATE - INTERVAL '24 hours'
GROUP BY DATE_TRUNC('hour', occurred_at)
ORDER BY hour DESC;
```

## 🚀 Deployment Strategy

### **1. Database Migration**
```bash
# Step 1: Create table (minimal downtime)
rails db:migrate VERSION=20251027000001

# Step 2: Backfill existing data (if needed)
# rails runner:Analytics::BackfillService.process

# Step 3: Add indexes (can be done separately)
rails db:migrate VERSION=20251027000002
```

### **2. Feature Flagging**
```ruby
# config/application.rb
config.analytics_enabled = ENV.fetch('ANALYTICS_ENABLED', 'false') == 'true'

# app/services/analytics_service.rb
def self.track(event_name, chat_id:, properties: {})
  return unless Rails.application.config.analytics_enabled

  # ... rest of implementation
end
```

### **3. Monitoring Setup**
```ruby
# app/services/analytics_health_service.rb
class AnalyticsHealthService
  def self.health_check
    {
      database_status: check_database_connection,
      queue_status: check_queue_processing,
      last_event: AnalyticsEvent.order(occurred_at: :last).first&.occurred_at,
      queue_size: SolidQueue::Job.where(queue_name: 'analytics').count
    }
  end

  private

  def self.check_database_connection
    AnalyticsEvent.connection.active? ? 'connected' : 'disconnected'
  end

  def self.check_queue_processing
    last_job = SolidQueue::Job.where(queue_name: 'analytics')
                         .order(finished_at: :desc)
                         .first
    last_job ? 'processing' : 'idle'
  end
end
```

## 📋 Monitoring & Alerts

### **1. Performance Metrics**
- **Event ingestion rate:** events/second
- **Processing latency:** time from event creation to storage
- **Query performance:** analytics query response times
- **Error rate:** failed analytics operations

### **2. Business Metrics Monitoring**
- **Conversion rate trends:** alerts on significant changes
- **Response time SLA:** alerts on >3 second responses
- **User journey drop-offs:** alerts on unexpected funnel changes

## 🔗 Dependencies & Requirements

### **Ruby Gems Required:**
- `solid_queue` (уже используется)
- `redis` (уже используется)
- `pg` (уже используется)
- `request_store` для request-scoped data

### **External Dependencies:**
- **PostgreSQL** с JSONB поддержкой
- **Redis** для Solid Queue
- **Docker** для Metabase
- **Metabase** для дашбордов

### **Infrastructure Requirements:**
- **Database storage:** ~1GB/год для analytics данных
- **Processing overhead:** <5% CPU, <100MB RAM
- **Network:** минимальный overhead

---

**Версия:** 1.0
**Дата создания:** 27.10.2025
**Тип документа:** Technical Design Document (TDD)
**Связанный FIP:** FIP-001-analytics-system.md
**Ожидаемая реализация:** 3 дня