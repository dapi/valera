# Technical Specification Document: TSD-006 - Chat ID Detection для групп

**Статус:** Draft
**Сложность:** Medium
**Приоритет:** High
**Создан:** 28.10.2025
**Обновлен:** 28.10.2025
**User Story:** [US-006-telegram-chat-id-detection.md](../user-stories/US-006-telegram-chat-id-detection.md)

## 🎯 Технические требования

### Functional Requirements
- [ ] **[FR-001]:** Обработка Telegram webhook события `new_chat_members`
- [ ] **[FR-002]:** Обработка Telegram webhook события `migrate_to_supergroup`
- [ ] **[FR-003]:** Автоматическое извлечение bot_id из bot_token
- [ ] **[FR-004]:** Отправка chat_id владельцу бота через Telegram API
- [ ] **[FR-005]:** Логирование всех событий определения chat_id
- [ ] **[FR-006]:** Обработка повторных добавлений (дедупликация)

### Non-Functional Requirements
- [ ] **Performance:**
  - Response time: < 3000ms для отправки уведомления
  - Throughput: > 100 webhook events/minute
  - Concurrent processing: 10+ одновременных событий
- [ ] **Security:**
  - Webhook verification: проверка Telegram токена
  - Input validation: валидация входящих данных
  - Error sanitization: безопасная обработка ошибок
- [ ] **Reliability:**
  - Retry mechanism: 3 попытки при сбое отправки
  - Error logging: детальное логирование всех ошибок
  - Monitoring: отслеживание успешности определений
- [ ] **Availability:**
  - Uptime: > 99.5% для webhook обработчика
  - Failover: graceful degradation при недоступности Telegram API

## 🏗️ Архитектура

### Components
1. **TelegramWebhookController** - обработка webhook событий
2. **ChatIdDetectionService** - основная логика определения
3. **ChatIdNotificationJob** - асинхронная отправка уведомлений
4. **BotIdExtractor** - утилита извлечения bot_id
5. **ChatIdLogger** - логирование событий

### Data Flow
```
Telegram Webhook → WebhookController → DetectionService → NotificationJob → Telegram API
                                    ↓
                                Logger → Analytics
```

### Integration Points
- **Telegram Bot API:** отправка сообщений с chat_id
- **ApplicationConfig:** хранение bot_token и настроек
- **Solid Queue:** асинхронная обработка уведомлений
- **PostgreSQL:** логирование событий определения

## 📝 Implementation Plan

### Phase 1: Webhook Handlers (2 дня)
```ruby
# app/controllers/telegram/webhook_controller.rb
def new_chat_members
  ChatIdDetectionService.new(params).process_new_members
end

def migrate_to_supergroup
  ChatIdDetectionService.new(params).process_migration
end
```

### Phase 2: Detection Service (1 день)
```ruby
# app/services/chat_id_detection_service.rb
class ChatIdDetectionService
  def initialize(params)
    @params = params
    @chat_id = params[:message][:chat][:id]
    @bot_id = extract_bot_id
  end

  def process_new_members
    # Логика обработки новых участников
  end
end
```

### Phase 3: Notification System (1 день)
```ruby
# app/jobs/chat_id_notification_job.rb
class ChatIdNotificationJob < ApplicationJob
  def perform(chat_id, bot_id)
    # Отправка уведомления владельцу
  end
end
```

## 🔧 Technical Details

### Bot ID Extraction
```ruby
def extract_bot_id
  token = ApplicationConfig.bot_token
  token.split(':')[0].to_i
end
```

### Message Template
```yaml
# config/locales/ru.yml
chat_id_notification:
  message: |
    🎉 Бот добавлен в чат!

    📋 Chat ID для настройки: `%{chat_id}`

    Используйте этот ID в административной панели для работы с чатом.
```

### Error Handling
- **Network errors:** повтор с экспоненциальной задержкой
- **Invalid chat:** логирование и продолжение работы
- **Rate limiting:** queue mechanism для API запросов

## 🧪 Testing Strategy

### Unit Tests
- ChatIdDetectionService - core logic
- BotIdExtractor - ID extraction logic
- ChatIdNotificationJob - notification delivery

### Integration Tests
- WebhookController endpoint tests
- Telegram API integration tests
- Error scenario handling

### End-to-End Tests
- Full flow from webhook to notification
- Multiple chat types (group, supergroup)
- Edge cases and error conditions

## 📊 Success Metrics

### Technical KPIs
- **Detection success rate:** > 99%
- **Notification delivery rate:** > 98%
- **Response time:** < 3 seconds (p95)
- **Error rate:** < 1%

### Business KPIs
- **Onboarding time reduction:** 83% (30min → 5min)
- **Setup completion rate:** > 95%
- **Support ticket reduction:** 90%

---

**Сложность реализации:** Medium
**Оценка времени:** 4 дня
**Необходимые ресурсы:** 1 developer
**Риски:** Низкие