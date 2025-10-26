# Настройка Metabase для аналитики Valera

**Дата создания:** 27.10.2025
**Версия:** 1.0
**Статус:** Инструкции по установке и настройке

## 📋 Обзор

Metabase - это open source BI инструмент для создания дашбордов и визуализации данных. В проекте Valera используется для:

- Визуализации воронок конверсии (US-001 → US-002b)
- Мониторинга производительности AI системы
- Анализа пользовательского поведения
- Построения бизнес-отчетов

## 🚀 Быстрый старт

### 1. Запуск Metabase

```bash
# Запуск Metabase и PostgreSQL для аналитики
docker-compose -f docker-compose.analytics.yml up -d

# Проверка статуса
docker-compose -f docker-compose.analytics.yml ps
```

### 2. Первичная настройка

1. Откройте http://localhost:3001 в браузере
2. Создайте администратора Metabase
3. Добавьте базу данных PostgreSQL:
   - **Host:** host.docker.internal (или localhost:5433)
   - **Database name:** valera_development
   - **Username:** valera
   - **Password:** password
   - **Port:** 5432

## 📊 Создание дашбордов

### Дашборд 1: Conversion Funnel (Воронка конверсии)

**Цель:** Отслеживание конверсии пользователей на каждом этапе

1. **Создание вопроса: Complete User Journey**
```sql
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

2. **Создание вопроса: Response Time Performance**
```sql
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

3. **Создание вопроса: Top Services Suggested**
```sql
SELECT
  properties->>'service_name' as service_name,
  COUNT(*) as suggestion_count,
  AVG(CAST(properties->>'confidence_score' AS NUMERIC)) as avg_confidence
FROM analytics_events
WHERE event_name = 'service_suggested'
  AND occurred_at >= CURRENT_DATE - INTERVAL '30 days'
  AND properties->>'service_name' IS NOT NULL
GROUP BY properties->>'service_name'
ORDER BY suggestion_count DESC
LIMIT 10;
```

### Дашборд 2: Performance Metrics

**Цель:** Мониторинг производительности системы

1. **AI Response Time Trends**
2. **Error Rate Monitoring**
3. **Database Query Performance**
4. **User Activity Heatmap**

## 🔧 Конфигурация

### Environment Variables

```bash
# Production environment
MB_DB_TYPE=postgres
MB_DB_DBNAME=valera_production
MB_DB_USER=valera
MB_DB_PASS=your_secure_password
MB_DB_HOST=your_postgres_host
MB_SITE_URL=https://analytics.yourdomain.com
```

### Database Permissions

Metabase требует только read-only доступ к таблице `analytics_events`:

```sql
-- Создание read-only пользователя для Metabase
CREATE USER metabase_reader WITH PASSWORD 'secure_password';
GRANT CONNECT ON DATABASE valera_production TO metabase_reader;
GRANT USAGE ON SCHEMA public TO metabase_reader;
GRANT SELECT ON analytics_events TO metabase_reader;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO metabase_reader;
```

## 📈 Оптимизация запросов

### Индексы для производительности

```sql
-- Основные индексы уже созданы в миграции
-- Дополнительные индексы для сложных запросов:
CREATE INDEX CONCURRENTLY idx_analytics_properties_service
ON analytics_events USING GIN ((properties->>'service_name'))
WHERE properties->>'service_name' IS NOT NULL;

CREATE INDEX CONCURRENTLY idx_analytics_properties_confidence
ON analytics_events ((CAST(properties->>'confidence_score' AS NUMERIC)))
WHERE properties->>'confidence_score' IS NOT NULL;
```

### Materialized Views для тяжелых запросов

```sql
CREATE MATERIALIZED VIEW daily_analytics_summary AS
SELECT
  DATE(occurred_at) as date,
  event_name,
  COUNT(*) as event_count,
  COUNT(DISTINCT chat_id) as unique_users,
  AVG(CASE WHEN event_name = 'ai_response_time'
           THEN CAST(properties->>'duration_ms' AS INTEGER) END) as avg_response_time
FROM analytics_events
GROUP BY DATE(occurred_at), event_name;

-- Обновление materialized view
CREATE OR REPLACE FUNCTION refresh_daily_analytics()
RETURNS void AS $$
BEGIN
  REFRESH MATERIALIZED VIEW daily_analytics_summary;
END;
$$ LANGUAGE plpgsql;

-- Автоматическое обновление каждый день
-- (настроить через pg_cron или внешний scheduler)
```

## 🔒 Безопасность

### Network Security

- Metabase доступен только через VPN или internal network
- Использование HTTPS в production
- Ограничение доступа к базе данных только read-only пользователем

### Data Privacy

```sql
-- Анонимизация персональных данных в представлениях
CREATE VIEW analytics_anonymous AS
SELECT
  event_name,
  properties - ARRAY['customer_name', 'customer_phone'] as properties,
  occurred_at,
  -- Хеширование chat_id для анонимности
  MD5(chat_id::text || 'salt') as anonymous_chat_id,
  session_id,
  platform
FROM analytics_events;
```

## 📋 Мониторинг

### Health Check Endpoint

```ruby
# app/controllers/analytics/health_controller.rb
class Analytics::HealthController < ApplicationController
  def show
    render json: {
      database_status: check_database_connection,
      last_event: AnalyticsEvent.maximum(:occurred_at),
      total_events: AnalyticsEvent.count,
      metabase_status: check_metabase_connection
    }
  end

  private

  def check_database_connection
    AnalyticsEvent.connection.active? ? 'connected' : 'disconnected'
  end

  def check_metabase_connection
    # Check Metabase API health
    uri = URI('http://localhost:3001/api/health')
    response = Net::HTTP.get_response(uri)
    response.code == '200' ? 'healthy' : 'unhealthy'
  rescue
    'unreachable'
  end
end
```

## 🚨 Алерты и уведомления

### Настройка алертов в Metabase

1. **Conversion Rate Drop**: Уведомление при падении конверсии > 20%
2. **Response Time Spike**: Уведомление при времени ответа > 5 секунд
3. **Error Rate Increase**: Уведомление при росте ошибок > 5%

### Интеграция с уведомлениями

```ruby
# app/services/analytics_alert_service.rb
class AnalyticsAlertService
  def self.check_metrics
    check_conversion_rate
    check_response_times
    check_error_rates
  end

  private

  def self.check_conversion_rate
    recent_rate = calculate_conversion_rate(1.day.ago, Time.current)
    baseline_rate = calculate_conversion_rate(7.days.ago, 1.day.ago)

    if recent_rate < baseline_rate * 0.8
      send_alert("Conversion rate dropped: #{recent_rate}% (baseline: #{baseline_rate}%)")
    end
  end

  def self.send_alert(message)
    # Send to Slack, Telegram, etc.
    Rails.logger.error "Analytics Alert: #{message}"
  end
end
```

## 📚 Дополнительные ресурсы

- [Metabase Documentation](https://www.metabase.com/docs/latest/)
- [SQL Best Practices for Analytics](https://www.metabase.com/learn/sql/)
- [PostgreSQL Performance Tuning](https://wiki.postgresql.org/wiki/Tuning_Your_PostgreSQL_Server)

---

**Версия:** 1.0
**Дата создания:** 27.10.2025
**Тип документа:** Technical Documentation
**Обновление:** Плановые обновления по мере добавления метрик