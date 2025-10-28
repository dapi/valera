# 🚀 План реализации DIALOG_STARTED v2.0

**Создан:** 27.10.2025
**Версия:** 1.0
**Статус:** Ready for Implementation
**Приоритет:** High

---

## 🎯 Обзор проекта

**DIALOG_STARTED v2.0** - расширенная система определения начала диалога, которая способна различать разные типы пользовательских сценариев и собирать контекстную аналитику.

### **Основные улучшения:**
- 🧠 **Интеллектуальная детекция** типа диалога
- 📊 **Контекстная аналитика** с 6 типами сценариев
- ⏰ **Временная логика** (30+ минут, 2+ часа)
- 🔗 **Интеграция с заявками** для пост-бронинговых диалогов

---

## 📋 Структура реализации

### **Этап 1: Core Logic Implementation** (4 часа)
**Цель:** Обновить WebhookController с новой логикой

**Задачи:**
1.1. **Заменить `first_message_today?` → `should_start_new_dialog?`**
1.2. **Реализовать `new_dialog_conditions_met?(chat_id)`**
1.3. **Добавить `determine_dialog_context(chat_id)`**
1.4. **Обновить DIALOG_STARTED трекинг с новыми свойствами**

### **Этап 2: Helper Methods** (3 часа)
**Цель:** Создать вспомогательные методы для анализа контекста

**Задачи:**
2.1. **`last_user_message_time(chat_id)`** - время последнего сообщения
2.2. **`has_recent_booking?(chat_id)`** - проверка недавних заявок
2.3. **`calculate_time_since_last_message(chat_id)`** - расчет времени
2.4. **`get_last_booking_details(chat_id)`** - детали последней заявки

### **Этап 3: Analytics Enhancement** (2 часа)
**Цель:** Обновить аналитическую систему

**Задачи:**
3.1. **Обновить `EventConstants::DIALOG_STARTED`** свойства
3.2. **Добавить новые поля в `AnalyticsService.track`**
3.3. **Обновить `BookingNotificationJob`** для контекста
3.4. **Создать новые аналитические события (опционально)**

### **Этап 4: Testing & Validation** (3 часа)
**Цель:** Обеспечить качество реализации

**Задачи:**
4.1. **Обновить существующие тесты** для WebhookController
4.2. **Добавить тесты для новых сценариев**
4.3. **Интеграционные тесты** для полного flow
4.4. **Performance тесты** для проверки скорости

---

## 🔧 Детальная реализация

### **Этап 1: Core Logic**

```ruby
# app/controllers/telegram/webhook_controller.rb

def should_start_new_dialog?(chat_id)
  return true if Rails.env.test?

  has_dialog_today = dialog_started_today?(chat_id)

  if has_dialog_today
    new_dialog_conditions_met?(chat_id)
  else
    true  # Первый диалог дня
  end
end

private

def dialog_started_today?(chat_id)
  AnalyticsEvent
    .by_chat(chat_id)
    .by_event(AnalyticsService::Events::DIALOG_STARTED)
    .where('occurred_at >= ?', Date.current)
    .exists?
end

def new_dialog_conditions_met?(chat_id)
  time_condition = time_since_last_message_exceeds_threshold?(chat_id)
  booking_condition = has_recent_booking?(chat_id)

  time_condition || booking_condition
end

def time_since_last_message_exceeds_threshold?(chat_id)
  last_time = last_user_message_time(chat_id)
  return false unless last_time

  (Time.current - last_time) > 30.minutes
end

def determine_dialog_context(chat_id)
  if has_recent_booking?(chat_id)
    'post_booking'
  elsif service_dialog_indicators_present?(chat_id)
    'service'
  elsif complaint_indicators_present?(chat_id)
    'complaint'
  elsif sales_objection_indicators_present?(chat_id)
    'sales_objection'
  elsif general_inquiry_indicators_present?(chat_id)
    'general_inquiry'
  else
    'primary'
  end
end

# Update existing create method
def create
  # ... existing code ...

  if should_start_new_dialog?(chat_id)
    AnalyticsService.track(
      AnalyticsService::Events::DIALOG_STARTED,
      chat_id: chat_id,
      properties: {
        message_type: message_type(message),
        platform: 'telegram',
        user_id: telegram_user.id,
        dialog_context: determine_dialog_context(chat_id),
        has_recent_booking: has_recent_booking?(chat_id),
        time_since_last_message: calculate_time_since_last_message(chat_id),
        user_segment: determine_user_segment(telegram_user)
      }
    )
  end

  # ... rest of create method ...
end
```

### **Этап 2: Helper Methods**

```ruby
# app/controllers/telegram/webhook_controller.rb (private section)

def last_user_message_time(chat_id)
  Message
    .joins(:chat)
    .where(chats: { telegram_chat_id: chat_id })
    .where(role: 'user')
    .maximum(:created_at)
end

def has_recent_booking?(chat_id)
  Booking
    .joins(telegram_user: :chats)
    .where(chats: { telegram_chat_id: chat_id })
    .where('bookings.created_at > ?', 2.hours.ago)
    .exists?
end

def calculate_time_since_last_message(chat_id)
  last_time = last_user_message_time(chat_id)
  return nil unless last_time

  (Time.current - last_time).to_i
end

def get_last_booking_details(chat_id)
  last_booking = Booking
    .joins(telegram_user: :chats)
    .where(chats: { telegram_chat_id: chat_id })
    .order(created_at: :desc)
    .first

  return {} unless last_booking

  {
    id: last_booking.id,
    created_at: last_booking.created_at,
    status: last_booking.status,
    services: last_booking.meta&.dig('required_services'),
    cost_calculation: last_booking.meta&.dig('cost_calculation')
  }
end

def service_dialog_indicators_present?(chat_id)
  # Проверяем на ключевые слова сервисного диалога
  recent_messages = get_recent_messages(chat_id, 5)
  service_keywords = %w[стоит цена услуга материалы сроки гарантии]

  recent_messages.any? { |msg| service_keywords.any? { |kw| msg.include?(kw) } } }
end

def complaint_indicators_present?(chat_id)
  recent_messages = get_recent_messages(chat_id, 3)
  complaint_keywords = %w[плохо недоволен проблема жалоба вернуть деньги]

  recent_messages.any? { |msg| complaint_keywords.any? { |kw| msg.include?(kw) } } }
end

def sales_objection_indicators_present?(chat_id)
  recent_messages = get_recent_messages(chat_id, 3)
  objection_keywords = %w[дорого дорого нет времени подумаю сравнить]

  recent_messages.any? { |msg| objection_keywords.any? { |kw| msg.include?(kw) } } }
end

def general_inquiry_indicators_present?(chat_id)
  recent_messages = get_recent_messages(chat_id, 3)
  inquiry_keywords = %w[где часы как работать компания отзывы гарантии]

  recent_messages.any? { |msg| inquiry_keywords.any? { |kw| msg.include?(kw) } } }
end

def get_recent_messages(chat_id, limit = 5)
  Message
    .joins(:chat)
    .where(chats: { telegram_chat_id: chat_id })
    .where(role: 'user')
    .order(created_at: :desc)
    .limit(limit)
    .pluck(:content)
end

def determine_user_segment(telegram_user)
  return 'new' if telegram_user.created_at > 24.hours.ago
  return 'returning' if telegram_user.bookings.exists?
  'regular'
end
```

### **Этап 3: Analytics Enhancement**

```ruby
# app/services/analytics/event_constants.rb (already updated)

DIALOG_STARTED = {
  name: 'ai_dialog_started',
  description: 'Начало диалога с AI ассистентом',
  category: 'dialog',
  properties: [
    :platform,
    :user_id,
    :message_type,
    :dialog_context,
    :has_recent_booking,
    :time_since_last_message,
    :user_segment
  ]
}.freeze
```

```ruby
# app/services/analytics_service.rb (already updated)

# Enhanced tracking method call in WebhookController
AnalyticsService.track(
  Events::DIALOG_STARTED,
  chat_id: chat_id,
  properties: {
    message_type: message_type(message),
    platform: 'telegram',
    user_id: telegram_user.id,
    dialog_context: determine_dialog_context(chat_id),
    has_recent_booking: has_recent_booking?(chat_id),
    time_since_last_message: calculate_time_since_last_message(chat_id),
    user_segment: determine_user_segment(telegram_user),
    last_booking_id: get_last_booking_details(chat_id)[:id],
    last_booking_status: get_last_booking_details(chat_id)[:status]
  }
)
```

### **Этап 4: Testing**

```ruby
# test/controllers/telegram/webhook_controller_test.rb

test "should start new dialog after 30 minutes of inactivity" do
  travel_to 2.hours.ago
    create_message(chat: @chat, role: 'user', created_at: 2.hours.ago)
    create_message(chat: @chat, role: 'user', created_at: 1.hour.ago)
  travel_back

  assert_no_difference -> do
    post :create, params: { message: message_payload }
  end

  assert_equal 2, AnalyticsEvent.by_event('ai_dialog_started').count
  last_event = AnalyticsEvent.last
  assert_equal 'primary', last_event.properties['dialog_context']
  assert_equal true, last_event.properties['time_since_last_message'] > 1800
end

test "should detect post_booking dialog after booking creation" do
  create(:booking, telegram_user: @telegram_user, created_at: 1.hour.ago)
  create_message(chat: @chat, role: 'user', created_at: 45.minutes.ago)

  post :create, params: { message: message_payload }

  event = AnalyticsEvent.last
  assert_equal 'post_booking', event.properties['dialog_context']
  assert_equal true, event.properties['has_recent_booking']
  assert event.properties['last_booking_id'].present?
end

test "should detect service dialog with pricing keywords" do
  message_payload = {
    'message' => {
      'text' => 'сколько стоит полировка кузова?',
      'chat' => { 'id' => @chat.telegram_chat_id }
    }
  }

  post :create, params: message_payload

  event = AnalyticsEvent.last
  assert_equal 'service', event.properties['dialog_context']
end

test "should detect complaint dialog with negative keywords" do
  message_payload = {
    'message' => {
      'text' => 'я недоволен качеством ремонта',
      'chat' => { 'id' => @chat.telegram_chat_id }
    }
  }

  post :create, params: message_payload

  event = AnalyticsEvent.last
  assert_equal 'complaint', event.properties['dialog_context']
end

test "should not start new dialog within 30 minutes" do
  create_message(chat: @chat, role: 'user', created_at: 15.minutes.ago)

  assert_no_difference -> do
    post :create, params: { message: message_payload }
  end

  assert_equal 0, AnalyticsEvent.by_event('ai_dialog_started').count
end
```

---

## 📊 Ожидаемые результаты

### **Аналитические улучшения:**
- 📈 **Segmentation:** 6 типов диалогов вместо 1
- 🎯 **Context-aware:** Понимание намерений пользователей
- ⏰ **Behavior patterns:** Отслеживание временных паттернов
- 🔗 **Journey mapping:** Полная воронка пользователя

### **Business Insights:**
- 📊 **Conversion rates** по типам диалогов
- 🎯 **Engagement metrics** для разных сценариев
- ⏰ **Optimal timing** для follow-up
- 🔧 **Process improvements** на основе данных

---

## 🎯 Success Metrics

### **Technical Metrics:**
- ✅ **Response time:** < 100ms для определения контекста
- ✅ **Accuracy:** > 95% правильное определение типа диалога
- ✅ **Coverage:** Обработка всех 6 типов сценариев
- ✅ **Performance:** Без влияния на скорость ответов

### **Business Metrics:**
- 📈 **Dialog quality:** Понимание паттернов поведения
- 🎯 **Conversion optimization:** Улучшение конверсии по сценариям
- ⏰ **Timing optimization:** Выявление лучших моментов для контакта
- 🔍 **Issue detection:** Быстрое выявление проблемных диалогов

---

## 🚀 Implementation Timeline

| **Day** | **Tasks** | **Priority** |
|---------|------------|---------------|
| **Day 1** | Этап 1: Core Logic | High |
| **Day 2** | Этап 2: Helper Methods | High |
| **Day 3** | Этап 3: Analytics Enhancement | Medium |
| **Day 4** | Этап 4: Testing & Validation | High |
| **Day 5** | Documentation & Deployment | Medium |

**Total Implementation Time:** ~12-15 часов
**Team Required:** 1 разработчик
**Risk Level:** Low (обратимая совместимость)

---

## 🔗 Dependencies

### **Existing Dependencies:**
- ✅ `AnalyticsEvent` модель (уже есть)
- ✅ `Booking` модель (уже есть)
- ✅ `AnalyticsService` (уже есть)
- ✅ WebhookController (требует обновления)

### **New Dependencies:**
- 🆕 Дополнительные поля в `EventConstants`
- 🆕 Новый helper methods в WebhookController
- 🆕 Обновленные тесты

---

## ✅ Ready for Implementation

**Статус:** Все компоненты спроектированы
**Документация:** Полная спецификация с примерами кода
**Тесты:** Комплексный тестовый план
**Risks:** Минимальные, обратимая совместимость

**Next step:** Начать с Этапа 1 - обновление WebhookController