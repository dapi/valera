# 📊 Monitoring Guide

**Обновлено:** 2025-10-27

---

## 📋 Содержание

- [Health Checks](#health-checks)
- [Logging](#logging)
- [Metrics](#metrics)
- [Alerting](#alerting)
- [Performance Monitoring](#performance-monitoring)

---

## 🏥 Health Checks

### Application Health Endpoints

#### Basic Health Check
```
GET /up
```
**Response:** `200 OK` with service status

#### Detailed Health Check
```
GET /health
```
**Response:**
```json
{
  "status": "ok",
  "timestamp": "2025-10-27T10:00:00Z",
  "services": {
    "database": "ok",
    "redis": "ok",
    "telegram_bot": "ok"
  },
  "version": "1.0.0"
}
```

### Database Health Check
```ruby
# app/controllers/health_controller.rb
class HealthController < ApplicationController
  def up
    render json: { status: 'ok' }
  end

  def health
    status = {
      status: 'ok',
      timestamp: Time.current.iso8601,
      services: {}
    }

    # Check database
    begin
      ActiveRecord::Base.connection.execute('SELECT 1')
      status[:services][:database] = 'ok'
    rescue => e
      status[:services][:database] = "error: #{e.message}"
      status[:status] = 'error'
    end

    # Check Redis
    begin
      Redis.current.ping
      status[:services][:redis] = 'ok'
    rescue => e
      status[:services][:redis] = "error: #{e.message}"
      status[:status] = 'error'
    end

    render json: status
  end
end
```

---

## 📝 Logging

### Structured Logging
```ruby
# app/models/concerns/loggable.rb
module Loggable
  extend ActiveSupport::Concern

  def log_event(event, data = {})
    Rails.logger.info({
      event: event,
      user_id: data[:user_id],
      timestamp: Time.current,
      data: data.except(:user_id)
    })
  end

  def log_error(error, context = {})
    Rails.logger.error({
      event: 'error',
      error_class: error.class.name,
      error_message: error.message,
      backtrace: error.backtrace&.first(10),
      context: context,
      timestamp: Time.current
    })
  end
end
```

### ErrorLogger Integration
```ruby
# Использование ErrorLogger
include ErrorLogger

begin
  # risky operation
  process_booking(booking)
rescue => e
  log_error(e, {
    user_id: current_user&.id,
    booking_id: booking&.id,
    action: 'process_booking',
    context: 'booking_processing'
  })
end
```

### Log Levels
- **DEBUG:** Детальная отладочная информация
- **INFO:** Общая информация о работе приложения
- **WARN:** Предупреждения
- **ERROR:** Ошибки приложения
- **FATAL:** Критические ошибки

---

## 📈 Metrics

### Business Metrics
```ruby
# app/services/analytics_service.rb
class AnalyticsService
  EVENTS = {
    NEW_USER: 'new_user',
    BOOKING_CREATED: 'booking_created',
    TELEGRAM_MESSAGE: 'telegram_message',
    AI_RESPONSE: 'ai_response'
  }.freeze

  def self.track(event, properties = {})
    AnalyticsEvent.create!(
      event_name: event,
      properties: properties,
      timestamp: Time.current
    )
  end

  def self.daily_metrics(date = Date.current)
    {
      new_users: AnalyticsEvent.where(event_name: EVENTS[:NEW_USER])
                              .where(created_at: date.all_day)
                              .count,
      bookings: AnalyticsEvent.where(event_name: EVENTS[:BOOKING_CREATED])
                             .where(created_at: date.all_day)
                             .count,
      messages: AnalyticsEvent.where(event_name: EVENTS[:TELEGRAM_MESSAGE])
                             .where(created_at: date.all_day)
                             .count
    }
  end
end
```

### Technical Metrics
```ruby
# Performance monitoring
class PerformanceMonitor
  def self.track_request(controller, action, duration)
    Rails.logger.info({
      event: 'request_completed',
      controller: controller,
      action: action,
      duration_ms: duration,
      timestamp: Time.current
    })
  end

  def self.track_ai_response(model, tokens_in, tokens_out, duration)
    Rails.logger.info({
      event: 'ai_response_completed',
      model: model,
      tokens_in: tokens_in,
      tokens_out: tokens_out,
      duration_seconds: duration,
      timestamp: Time.current
    })
  end
end
```

---

## 🚨 Alerting

### Critical Alerts
```yaml
# alerting.yml
alerts:
  - name: "Service Down"
    condition: "health_check_failed"
    severity: "critical"
    channels: ["slack", "email"]

  - name: "High Error Rate"
    condition: "error_rate > 5%"
    severity: "high"
    channels: ["slack"]

  - name: "Database Connection Failed"
    condition: "database_status != 'ok'"
    severity: "critical"
    channels: ["slack", "email"]

  - name: "Telegram Bot Not Responding"
    condition: "telegram_bot_webhook_timeout"
    severity: "high"
    channels: ["slack"]
```

### Monitoring Service Setup
```ruby
# config/initializers/monitoring.rb
Rails.application.configure do
  config.after_initialize do
    # Setup monitoring
    if Rails.env.production?
      # Health check monitoring
      Thread.new do
        loop do
          sleep(30) # Check every 30 seconds
          check_service_health
        end
      end
    end
  end
end

def check_service_health
  response = HTTP.get("#{ENV['BASE_URL']}/health")

  if response.code != 200
    AlertService.notify("Service health check failed", {
      status_code: response.code,
      response_body: response.body
    })
  end
rescue => e
  AlertService.notify("Service health check error", {
    error: e.message
  })
end
```

---

## 🔍 Performance Monitoring

### Request Performance
```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  around_action :track_request_performance

  private

  def track_request_performance
    start_time = Time.current
    yield
    duration = ((Time.current - start_time) * 1000).round(2)

    PerformanceMonitor.track_request(
      controller_name,
      action_name,
      duration
    )

    # Log slow requests
    if duration > 2000 # 2 seconds
      Rails.logger.warn({
        event: 'slow_request',
        controller: controller_name,
        action: action_name,
        duration_ms: duration,
        params: params.except(:controller, :action)
      })
    end
  end
end
```

### Database Performance
```ruby
# config/initializers/database_monitoring.rb
if Rails.env.production?
  ActiveSupport::Notifications.subscribe('sql.active_record') do |*args|
    event = ActiveSupport::Notifications::Event.new(*args)

    if event.duration > 500 # 0.5 seconds
      Rails.logger.warn({
        event: 'slow_query',
        sql: event.payload[:sql],
        duration_ms: event.duration,
        timestamp: Time.current
      })
    end
  end
end
```

### Memory Monitoring
```ruby
# lib/tasks/monitoring.rake
desc "Check memory usage"
task memory_check: :environment do
  memory_usage = `ps -o rss= -p #{Process.pid}`.to_i

  Rails.logger.info({
    event: 'memory_check',
    memory_mb: memory_usage / 1024,
    timestamp: Time.current
  })

  if memory_usage > 512_000 # 512MB
    AlertService.notify("High memory usage", {
      memory_mb: memory_usage / 1024
    })
  end
end
```

---

## 📊 Dashboard Metrics

### Daily Report
```ruby
# app/services/daily_report_service.rb
class DailyReportService
  def self.generate(date = Date.yesterday)
    metrics = {
      date: date,
      users: User.where(created_at: date.all_day).count,
      bookings: Booking.where(created_at: date.all_day).count,
      messages: Message.where(created_at: date.all_day).count,
      errors: AnalyticsEvent.where(event_name: 'error')
                            .where(created_at: date.all_day)
                            .count
    }

    # Send to Slack/email
    ReportMailer.daily_report(metrics).deliver_now if Rails.env.production?

    metrics
  end
end
```

### Real-time Monitoring
```javascript
// frontend monitoring (если нужно)
class PerformanceMonitor {
  static trackPageLoad() {
    const loadTime = performance.timing.loadEventEnd - performance.timing.navigationStart;

    fetch('/api/v1/performance', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        event: 'page_load',
        load_time_ms: loadTime,
        url: window.location.href
      })
    });
  }
}

// Track page loads
document.addEventListener('DOMContentLoaded', () => {
  PerformanceMonitor.trackPageLoad();
});
```

---

## 🔧 Tools Integration

### Recommended Monitoring Stack
1. **Application:** New Relic / DataDog
2. **Infrastructure:** Prometheus + Grafana
3. **Logs:** ELK Stack (Elasticsearch, Logstash, Kibana)
4. **Error Tracking:** Sentry (в дополнение к ErrorLogger)
5. **Uptime:** UptimeRobot / Pingdom

### Basic Prometheus Metrics
```ruby
# lib/valera/prometheus.rb
require 'prometheus/client'

prometheus = Prometheus::Client.registry

# Define metrics
http_requests_total = prometheus.counter(:http_requests_total, docstring: 'Total HTTP requests')
http_request_duration = prometheus.histogram(:http_request_duration_seconds, docstring: 'HTTP request duration')

# Use in ApplicationController
around_action :track_prometheus_metrics

private

def track_prometheus_metrics
  http_requests_total.increment(labels: { controller: controller_name, action: action_name })

  Benchmark.measure do
    yield
  end.tap do |result|
    http_request_duration.observe(result.real, labels: { controller: controller_name, action: action_name })
  end
end
```

---

## 📱 Telegram Bot Monitoring

### Bot Health
```ruby
# app/services/telegram_monitor.rb
class TelegramMonitor
  def self.check_bot_health
    response = TelegramBot::Client.get_me

    if response.ok?
      Rails.logger.info({
        event: 'telegram_bot_healthy',
        bot_name: response.result.first_name,
        timestamp: Time.current
      })
    else
      AlertService.notify("Telegram bot not responding", {
        error: response.description
      })
    end
  rescue => e
    AlertService.notify("Telegram bot check failed", {
      error: e.message
    })
  end
end
```

### Webhook Monitoring
```ruby
# Track webhook deliveries
class WebhookMonitor
  def self.track_webhook(update)
    Rails.logger.info({
      event: 'telegram_webhook_received',
      update_type: update.type,
      user_id: update.from&.id,
      timestamp: Time.current
    })
  end
end
```

---

**📝 Документ создан:** 27.01.2025
**🔄 Обновлен:** 27.01.2025
**👤 Ответственный:** DevOps Team