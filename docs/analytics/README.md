# 📊 Valera Analytics System

**Быстрый старт и руководство по использованию системы аналитики**

## 🚀 Quick Start

### 1. Запуск Metabase
```bash
docker-compose -f docker-compose.analytics.yml up -d
```
Откройте http://localhost:3001

### 2. Проверка работы аналитики
```bash
bin/rails runner "puts AnalyticsEvent.count"
```

### 3. Создание тестового события
```bash
bin/rails runner "
AnalyticsService.track(
  AnalyticsService::Events::DIALOG_STARTED,
  chat_id: 12345,
  properties: { platform: 'telegram', message_type: 'test' }
)
"
```

## 📋 Основные компоненты

### Models
- `AnalyticsEvent` - модель хранения событий
- `Booking` - интегрирована с аналитикой

### Services
- `AnalyticsService` - основной интерфейс трекинга
- `Analytics::ResponseTimeTracker` - измерение производительности
- `Analytics::ServiceSuggestionTracker` - трекинг предложений услуг

### Jobs
- `AnalyticsJob` - фоновая обработка событий

## 🎯 Ключевые метрики

### Business Metrics
- **Conversion Rate:** 8-12% (диалог → заявка)
- **Response Time:** < 3 секунд
- **Avg Ticket Size:** 8,000-12,000₽

### Technical Metrics
- **Event Processing:** < 100ms
- **Query Performance:** < 1 секунда
- **System Uptime:** 99.5%

## 📈 Дашборды Metabase

### 1. Conversion Funnel Dashboard
- Weekly conversion trends
- User segment analysis
- Service performance
- Time to conversion

### 2. Performance Metrics Dashboard
- Response time analysis (P50, P95, P99)
- Error rate monitoring
- System health status
- User experience metrics

### 3. Business Overview Dashboard
- KPI overview
- Revenue impact
- User growth

## 🔧 Разработка

### Включение аналитики
```ruby
# development.rb
config.analytics_enabled = true
config.active_job.queue_adapter = :inline
```

### Добавление новых событий
```ruby
# 1. Добавить константу в Analytics::EventConstants
# 2. Обновить REQUIRED_PROPERTIES если нужно
# 3. Использовать в коде:
AnalyticsService.track(Events::NEW_EVENT, chat_id: id, properties: {})
```

### Тестирование
```bash
# Unit тесты
bin/rails test test/models/analytics_event_test.rb

# Performance тесты
bin/rails test test/performance/analytics_performance_test.rb
```

## 🔍 Мониторинг

### Health Check
```bash
curl http://localhost:3000/analytics/health
```

### Просмотр событий
```bash
bin/rails runner "
AnalyticsEvent.last(10).each do |event|
  puts \"#{event.occurred_at}: #{event.event_name} - #{event.properties}\"
end
"
```

## 📚 Документация

- [Полная документация](IMPLEMENTATION_SUMMARY.md)
- [Настройка Metabase](metabase-setup.md)
- [SQL скрипты дашбордов](sql/)

---

**Статус:** ✅ Production Ready
**Версия:** 1.0
**Последнее обновление:** 27.10.2025