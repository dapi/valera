-- Conversion Funnel Analysis
-- Анализ воронки конверсии от первого контакта до создания заявки

-- 1. Complete User Journey Funnel (weekly)
WITH user_journey AS (
  SELECT
    chat_id,
    MIN(CASE WHEN event_name = 'ai_dialog_started' THEN occurred_at END) as first_dialog,
    MIN(CASE WHEN event_name = 'service_suggested' THEN occurred_at END) as first_suggestion,
    MIN(CASE WHEN event_name = 'booking_request_created' THEN occurred_at END) as first_booking,
    COUNT(DISTINCT event_name) as unique_events,
    COUNT(*) as total_events
  FROM analytics_events
  WHERE occurred_at >= DATE_TRUNC('week', CURRENT_DATE) - INTERVAL '12 weeks'
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
  ) as conversion_rate_percent,
  ROUND(
    COUNT(CASE WHEN first_suggestion IS NOT NULL THEN 1 END) * 100.0 /
    COUNT(CASE WHEN first_dialog IS NOT NULL THEN 1 END), 2
  ) as suggestion_rate_percent
FROM user_journey
WHERE first_dialog IS NOT NULL
GROUP BY DATE_TRUNC('week', first_dialog)
ORDER BY week DESC;

-- 2. Daily Conversion Funnel
SELECT
  DATE(occurred_at) as date,
  COUNT(DISTINCT CASE WHEN event_name = 'ai_dialog_started' THEN chat_id END) as daily_dialogs,
  COUNT(DISTINCT CASE WHEN event_name = 'service_suggested' THEN chat_id END) as daily_suggestions,
  COUNT(DISTINCT CASE WHEN event_name = 'booking_request_created' THEN chat_id END) as daily_bookings,
  ROUND(
    COUNT(DISTINCT CASE WHEN event_name = 'booking_request_created' THEN chat_id END) * 100.0 /
    NULLIF(COUNT(DISTINCT CASE WHEN event_name = 'ai_dialog_started' THEN chat_id END), 0), 2
  ) as daily_conversion_rate
FROM analytics_events
WHERE occurred_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY DATE(occurred_at)
ORDER BY date DESC;

-- 3. User Segment Analysis
SELECT
  CASE
    WHEN properties->>'user_segment' = 'new' THEN 'New Users'
    WHEN properties->>'user_segment' = 'engaged' THEN 'Engaged Users'
    WHEN properties->>'user_segment' = 'returning' THEN 'Returning Users'
    ELSE 'Unknown'
  END as user_segment,
  COUNT(DISTINCT chat_id) as total_users,
  COUNT(DISTINCT CASE WHEN event_name = 'booking_request_created' THEN chat_id END) as converted_users,
  ROUND(
    COUNT(DISTINCT CASE WHEN event_name = 'booking_request_created' THEN chat_id END) * 100.0 /
    NULLIF(COUNT(DISTINCT chat_id), 0), 2
  ) as conversion_rate_by_segment,
  AVG(CASE WHEN event_name = 'ai_response_time'
           THEN CAST(properties->>'duration_ms' AS INTEGER) END) as avg_response_time_ms
FROM analytics_events
WHERE occurred_at >= CURRENT_DATE - INTERVAL '30 days'
  AND properties->>'user_segment' IS NOT NULL
GROUP BY properties->>'user_segment'
ORDER BY total_users DESC;

-- 4. Service Performance Analysis
SELECT
  properties->>'service_name' as service_name,
  COUNT(*) as suggestion_count,
  COUNT(DISTINCT chat_id) as unique_users,
  AVG(CAST(properties->>'confidence_score' AS NUMERIC)) as avg_confidence_score,
  COUNT(DISTINCT CASE WHEN event_name = 'suggestion_accepted' THEN chat_id END) as acceptance_count,
  ROUND(
    COUNT(DISTINCT CASE WHEN event_name = 'suggestion_accepted' THEN chat_id END) * 100.0 /
    NULLIF(COUNT(DISTINCT chat_id), 0), 2
  ) as acceptance_rate_percent
FROM analytics_events
WHERE event_name = 'service_suggested'
  AND occurred_at >= CURRENT_DATE - INTERVAL '30 days'
  AND properties->>'service_name' IS NOT NULL
GROUP BY properties->>'service_name'
ORDER BY suggestion_count DESC
LIMIT 20;

-- 5. Time to Conversion Analysis
WITH user_conversions AS (
  SELECT
    chat_id,
    MIN(CASE WHEN event_name = 'ai_dialog_started' THEN occurred_at END) as dialog_start,
    MIN(CASE WHEN event_name = 'booking_request_created' THEN occurred_at END) as booking_created,
    EXTRACT(EPOCH FROM (
      MIN(CASE WHEN event_name = 'booking_request_created' THEN occurred_at END) -
      MIN(CASE WHEN event_name = 'ai_dialog_started' THEN occurred_at END)
    )) / 60 as time_to_convert_minutes
  FROM analytics_events
  WHERE occurred_at >= CURRENT_DATE - INTERVAL '30 days'
  GROUP BY chat_id
  HAVING MIN(CASE WHEN event_name = 'ai_dialog_started' THEN occurred_at END) IS NOT NULL
    AND MIN(CASE WHEN event_name = 'booking_request_created' THEN occurred_at END) IS NOT NULL
)
SELECT
  AVG(time_to_convert_minutes) as avg_time_to_convert_minutes,
  PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY time_to_convert_minutes) as median_time_to_convert,
  PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY time_to_convert_minutes) as p95_time_to_convert,
  COUNT(*) as total_conversions
FROM user_conversions;