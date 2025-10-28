# User Story: US-001 - Telegram Auto Greeting для кузовного ремонта

**Статус:** Ready for Development ✅
**Приоритет:** High
**Story Points:** 3
**Создан:** 27.10.2025
**Обновлен:** 27.10.2025 (добавлены метрики аналитики)

## 📝 User Story
**As a** владелец автомобиля с повреждениями кузова, который впервые обращается в наш сервис **I want to** получить естественное приветствие с фокусом на кузовной ремонт через диалог в Telegram **so that** я могу быстро начать консультацию и получить экспертную помощь по ремонту

## 👥 User Acceptance Criteria

### 🤖 Functional Criteria (Технические требования)
- [ ] **Given** новый пользователь пишет в бота **When** он отправляет первое сообщение **Then** бот отправляет приветствие нового пользователя с фокусом на кузовной ремонт
- [ ] **Given** бот отправляет приветствие **When** клиент отвечает **Then** диалог продолжается естественно, без кнопок и меню
- [ ] **Given** возвращающийся пользователь пишет в бота первое сообщение за день **When** он отправляет сообщение **Then** бот отправляет краткое приветствие для возвращающихся клиентов
- [ ] **Given** пользователь уже общался сегодня с ботом **When** он отправляет сообщение **Then** бот продолжает диалог без дополнительного приветствия

### 👥 User Acceptance Criteria (Пользовательские критерии)
- [ ] **Как клиент** Я чувствую что диалог начинается естественно и по-человечески
- [ ] **Как клиент** Я понимаю что бот специализируется на кузовном ремонте
- [ ] **Как клиент** Я могу легко начать разговор без изучения команд или кнопок

### 📊 Performance Criteria (Требования к производительности)
- [ ] **Response time:** < 3 секунд для первого приветствия
- [ ] **Greeting delivery:** < 2 секунд для отправки сообщения
- [ ] **Success rate:** 99.9% успешных отправок приветствий

### 📈 Analytics Criteria (Требования к аналитике)
- [ ] **Given** пользователь пишет впервые **When** бот отправляет приветствие **Then** событие `greeting_sent` отслеживается в аналитике
- [ ] **Given** диалог начат **When** пользователь продолжает общение **Then** время ответа AI измеряется и сохраняется
- [ ] **Given** новый пользователь взаимодействует **When** он отправляет сообщения **Then** engagement метрики собираются для анализа

## 🎯 Business Value
- **Проблема:** Новые клиенты не понимают специализации бота и не знают как начать диалог
- **Решение:** Естественное приветствие с фокусом на кузовной ремонт для быстрого вовлечения
- **Метрики успеха (FIP-001):**
  - **First response time:** < 3 секунд в 95% случаев
  - **Engagement rate:** > 70% новых пользователей продолжают диалог после приветствия
  - **Recognition rate:** > 90% пользователей понимают специализацию на кузовном ремонте
  - **Drop-off rate:** < 5% пользователей покидают диалог после первого сообщения

## 🎯 Target Metrics (из FIP-001 Analytics System)

### **Key Performance Indicators:**
- **Greeting response time:** < 3 секунд (SLA)
- **User engagement:** % пользователей, которые продолжают диалог
- **Session initiation rate:** Успешное начало консультации
- **Platform recognition:** Понимание специализации сервиса

### **Analytics Events to Track:**
```ruby
# Для US-001 отслеживаем:
AnalyticsService::Events::DIALOG_STARTED      # Начало диалога (включая пост-бронинговые)
AnalyticsService::Events::GREETING_SENT        # Отправка приветствия
AnalyticsService::Events::RESPONSE_TIME        # Время ответа AI
AnalyticsService::Events::USER_ENGAGEMENT     # Вовлечение пользователя
```

### **DIALOG_STARTED - Типы диалогов:**
**1. Первичный диалог:**
- Первое сообщение дня от пользователя
- Цель: Консультация или запись

**2. Пост-бронинговый диалог (новый):**
- Через 30+ минут после создания заявки
- Цель: Вопросы по заявке, статусу, документам

**3. Сервисный диалог:**
- После консультации, но до записи
- Цель: Уточнение деталей по услугам

### **Новые свойства для DIALOG_STARTED:**
```ruby
properties: {
  platform: 'telegram',                    # Платформа
  user_id: 12345,                        # ID пользователя
  message_type: 'text',                   # Тип сообщения
  dialog_context: 'post_booking',         # Тип диалога: 'primary', 'post_booking', 'service'
  has_recent_booking: true,               # Есть ли недавняя заявка (< 2 часов)
  time_since_last_message: 1800           # Секунд с последующего сообщения
}
```

### **Бизнес-ценность пост-бронинговых диалогов:**
- **Customer Satisfaction:** Клиенты доверьваются задавать вопросы
- **Conversion Rate:** Дополнительные продажи/услуги
- **Support Efficiency:** Снижение нагрузки на менеджеров
- **Service Quality:** Понимание узких мест в процессе

### **Success Benchmarks:**
- **Response time performance:** 95% < 3 секунд
- **Engagement conversion:** 70%+ продолжают диалог
- **User satisfaction:** 85%+ позитивных отзывов на приветствие

## 🚫 Исключения и Edge Cases
- [ ] **Непонятное первое сообщение:** Бот определяет намерение и отвечает соответствующим приветствием
- [ ] **Технические проблемы:** Graceful degradation и уведомление о временных проблемах
- [ ] **Спам/abus:** Rate limiting и фильтрация inappropriate контента
- [ ] **Несколько языков:** Определение языка и соответствующий ответ

## ✅ Definition of Done
- [ ] Все User Acceptance Criteria выполнены и протестированы
- [ ] Performance Criteria измерены и достигнуты
- [ ] Analytics Criteria реализованы и интегрированы с FIP-001
- [ ] Unit тесты для greeting логики написаны и проходят
- [ ] Integration тесты полного диалога проходят
- [ ] Performance тесты response time проходят
- [ ] Analytics tracking работает и возвращает корректные данные
- [ ] Code review выполнен и одобрен
- [ ] Документация обновлена с метриками

## 🔗 Связанные документы
- **Analytics Implementation:** [FIP-001-analytics-system.md](../FIP-001-analytics-system.md)
- **Technical Design:** [TSD-001-analytics-system.md](../tsd/TSD-001-analytics-system.md)
- **Dependent User Stories:** US-002a (консультация), US-002b (запись)
- **Business Metrics:** [../../business-metrics.md](../../business-metrics.md)
- **Product Constitution:** [../../product/constitution.md](../../product/constitution.md)

## 📋 Notes and Decisions

### Ключевые решения:
1. **Dialogue-only approach:** Никаких кнопок или меню, только естественный диалог
2. **Specialization focus:** Приветствие сразу подчеркивает экспертизу в кузовном ремонте
3. **Analytics integration:** Полная интеграция с системой метрик из FIP-001
4. **Performance monitoring:** Измерение и оптимизация времени ответа
5. **Multi-tier greeting system:** Различные приветствия для новых/возвращающихся/активных пользователей

### Technical Notes:
- **System prompt integration:** Приветствие должно соответствовать system-prompt.md
- **Company info usage:** Использует данные из company-info.md
- **Error handling:** Graceful обработка ошибок без прерывания диалога
- **Memory management:** Сохранение контекста начала диалога

### 🎯 Greeting Context Logic:
**1. Новый пользователь (< 24 часов):**
- Полное приветствие из `welcome-message.md`
- Фокус на кузовной ремонт и услуги
- Подробная информация о возможностях

**2. Возвращающийся пользователь (первое сообщение сегодня):**
- Краткое приветствие из `welcome-returning.md`
- Акцент на продолжение обслуживания
- Быстрый переход к делу

**3. Активный пользователь (уже общался сегодня):**
- Никакого дополнительного приветствия
- Сразу переход к обработке запроса
- Естественное продолжение диалога

## 🔄 Workflow Dependencies
- **Зависит от:** FIP-001 analytics system для метрик
- **Обеспечивает:** Фундамент для US-002a и US-002b
- **Интеграция с:** Telegram webhook controller и AI processing pipeline

---

**Change log:**
| Дата | Версия | Изменение | Автор |
|------|--------|-----------|-------|
| 27.10.2025 | 1.0 | Initial version based on ROADMAP.md requirements | Claude Code Assistant |
| 27.10.2025 | 1.1 | Added analytics criteria and FIP-001 integration | Claude Code Assistant |
| 28.10.2025 | 1.2 | Added multi-tier greeting system with detailed logic for new/returning/active users | Claude Code Assistant |

---

**Approval:**
- [ ] Product Owner: ____________________ Date: _______
- [ ] Tech Lead: __________________________ Date: _______

**Implementation Notes:**
- **Story Points:** 3 (Complexity: Medium, Technical Debt: Low)
- **Estimated Time:** 1.5 дня
- **Required Analytics Integration:** FIP-001 metrics system must be implemented first or in parallel