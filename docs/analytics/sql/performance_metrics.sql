-- Performance Metrics Analysis
-- Анализ производительности системы AI и метрик времени ответа

-- 1. AI Response Time Analysis (last 24 hours)
SELECT
  DATE_TRUNC('hour', occurred_at) as hour,
  COUNT(*) as total_responses,
  AVG(CAST(properties->>'duration_ms' AS INTEGER)) as avg_response_time_ms,
  PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY CAST(properties->>'duration_ms' AS INTEGER)) as p50_response_time_ms,
  PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY CAST(properties->>'duration_ms' AS INTEGER)) as p95_response_time_ms,
  PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY CAST(properties->>'duration_ms' AS INTEGER)) as p99_response_time_ms,
  MIN(CAST(properties->>'duration_ms' AS INTEGER)) as min_response_time_ms,
  MAX(CAST(properties->>'duration_ms' AS INTEGER)) as max_response_time_ms,
  COUNT(CASE WHEN CAST(properties->>'duration_ms' AS INTEGER) > 3000 THEN 1 END) as slow_responses_count,
  ROUND(COUNT(CASE WHEN CAST(properties->>'duration_ms' AS INTEGER) > 3000 THEN 1 END) * 100.0 / COUNT(*), 2) as slow_response_percent
FROM analytics_events
WHERE event_name = 'ai_response_time'
  AND occurred_at >= CURRENT_DATE - INTERVAL '24 hours'
GROUP BY DATE_TRUNC('hour', occurred_at)
ORDER BY hour DESC;

-- 2. Response Time Trends (last 7 days)
SELECT
  DATE(occurred_at) as date,
  COUNT(*) as total_requests,
  AVG(CAST(properties->>'duration_ms' AS INTEGER)) as avg_response_time_ms,
  PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY CAST(properties->>'duration_ms' AS INTEGER)) as p95_response_time_ms,
  COUNT(CASE WHEN CAST(properties->>'duration_ms' AS INTEGER) <= 3000 THEN 1 END) as fast_responses,
  ROUND(COUNT(CASE WHEN CAST(properties->>'duration_ms' AS INTEGER) <= 3000 THEN 1 END) * 100.0 / COUNT(*), 2) as sla_compliance_percent
FROM analytics_events
WHERE event_name = 'ai_response_time'
  AND occurred_at >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY DATE(occurred_at)
ORDER BY date DESC;

-- 3. Error Rate Monitoring
SELECT
  DATE_TRUNC('hour', occurred_at) as hour,
  COUNT(*) as total_events,
  COUNT(CASE WHEN event_name = 'error_occurred' THEN 1 END) as error_count,
  ROUND(COUNT(CASE WHEN event_name = 'error_occurred' THEN 1 END) * 100.0 / COUNT(*), 2) as error_rate_percent,
  COUNT(DISTINCT CASE WHEN event_name = 'error_occurred' THEN chat_id END) as affected_users,
  STRING_AGG(DISTINCT properties->>'error_class', ', ') as error_types
FROM analytics_events
WHERE occurred_at >= CURRENT_DATE - INTERVAL '24 hours'
GROUP BY DATE_TRUNC('hour', occurred_at)
ORDER BY hour DESC;

-- 4. Top Error Types Analysis
SELECT
  properties->>'error_class' as error_type,
  COUNT(*) as error_count,
  COUNT(DISTINCT chat_id) as affected_users,
  properties->>'context' as most_common_context,
  MIN(occurred_at) as first_occurrence,
  MAX(occurred_at) as last_occurrence
FROM analytics_events
WHERE event_name = 'error_occurred'
  AND occurred_at >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY properties->>'error_class', properties->>'context'
ORDER BY error_count DESC
LIMIT 10;

-- 5. System Performance Summary (real-time)
WITH recent_metrics AS (
  SELECT
    COUNT(CASE WHEN event_name = 'ai_response_time' THEN 1 END) as total_responses,
    AVG(CASE WHEN event_name = 'ai_response_time'
             THEN CAST(properties->>'duration_ms' AS INTEGER) END) as avg_response_time,
    COUNT(CASE WHEN event_name = 'error_occurred' THEN 1 END) as error_count,
    COUNT(DISTINCT chat_id) as active_users
  FROM analytics_events
  WHERE occurred_at >= CURRENT_DATE - INTERVAL '1 hour'
)
SELECT
  CURRENT_TIMESTAMP as current_time,
  total_responses,
  avg_response_time,
  error_count,
  active_users,
  CASE
    WHEN avg_response_time <= 3000 THEN 'Good'
    WHEN avg_response_time <= 5000 THEN 'Warning'
    ELSE 'Critical'
  END as performance_status,
  CASE
    WHEN error_count <= 5 THEN 'Normal'
    WHEN error_count <= 20 THEN 'Elevated'
    ELSE 'High'
  END as error_status
FROM recent_metrics;

-- 6. User Experience Metrics
SELECT
  DATE_TRUNC('day', occurred_at) as date,
  COUNT(DISTINCT chat_id) as daily_active_users,
  COUNT(DISTINCT CASE WHEN event_name = 'ai_dialog_started' THEN chat_id END) as new_dialogs,
  COUNT(DISTINCT CASE WHEN event_name = 'booking_request_created' THEN chat_id END) as conversions,
  COUNT(CASE WHEN event_name = 'ai_dialog_started' THEN 1 END) as total_dialog_events,
  AVG(CASE WHEN event_name = 'ai_response_time'
           THEN CAST(properties->>'duration_ms' AS INTEGER) END) as avg_response_time_ms
FROM analytics_events
WHERE occurred_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY DATE_TRUNC('day', occurred_at)
ORDER BY date DESC;

-- 7. Message Type Performance Analysis
SELECT
  properties->>'message_type' as message_type,
  COUNT(*) as message_count,
  COUNT(DISTINCT chat_id) as unique_users,
  AVG(CASE WHEN event_name = 'ai_response_time'
           THEN CAST(properties->>'duration_ms' AS INTEGER) END) as avg_response_time_ms,
  COUNT(CASE WHEN event_name = 'booking_request_created'
           AND occurred_at > LAG(occurred_at) OVER (PARTITION BY chat_id ORDER BY occurred_at)
           THEN 1 END) as resulting_conversions
FROM analytics_events
WHERE event_name = 'ai_dialog_started'
  AND occurred_at >= CURRENT_DATE - INTERVAL '7 days'
  AND properties->>'message_type' IS NOT NULL
GROUP BY properties->>'message_type'
ORDER BY message_count DESC;