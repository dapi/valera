# 🧠 Концепция: Контекстуальная система диалогов

**Создана:** 27.10.2025
**Версия:** 1.0
**Статус:** Concept Ready for Review
**Приоритет:** High

---

## 🎯 Обзор концепции

**Контекстуальная система диалогов** - эволюция базовой аналитики `DIALOG_STARTED` для интеллектуального определения намерений пользователей и контекста их обращений в AI-ассистента автосервиса.

### **Проблема:**
Текущая система `DIALOG_STARTED` обрабатывает все диалоги одинаково, не различая:
- 🔥 **Горячие лиды** (новые консультации)
- 📋 **Пост-бронинговые вопросы** (уточнения по заявкам)
- 🛠️ **Сервисные диалоги** (детализация услуг)
- 😤 **Жалобы и возражения** (критические сценарии)

### **Решение:**
Система из 6 контекстов диалога с асинхронным анализом для повышения качества обслуживания и аналитики.

---

## 🏗️ Архитектура системы

### **Компоненты:**

#### **1. Детектор контекста диалога**
```ruby
# app/services/dialog_context_detector.rb
class DialogContextDetector
  CONTEXT_TYPES = %w[primary service post_booking general_inquiry sales_objection complaint].freeze

  def detect_context(chat_id, message_content)
    # Асинхронный анализ после завершения диалога
    # Основан на паттернах сообщений и времени
  end
end
```

#### **2. Расширенная аналитика**
```ruby
# app/services/analytics/event_constants.rb (уже обновлено)
DIALOG_STARTED = {
  name: 'ai_dialog_started',
  description: 'Начало диалога с AI ассистентом',
  category: 'dialog',
  properties: [
    :platform,
    :user_id,
    :message_type,
    :dialog_context,        # 🆕 NEW
    :has_recent_booking,   # 🆕 NEW
    :time_since_last_message, # 🆕 NEW
    :user_segment          # 🆕 NEW
  ]
}.freeze
```

#### **3. Паттерны пользовательских сценариев**
7 детализированных сценариев в `docs/user-scenarios/`:
- `01-primary-dialog.md` - Первичные обращения
- `02-post-booking-dialog.md` - Пост-бронинговые вопросы
- `03-service-dialog.md` - Сервисные консультации
- `04-complaint-resolution.md` - Разрешение жалоб
- `05-sales-objection-handling.md` - Работа с возражениями
- `06-photo-based-assessment.md` - Фото-оценка повреждений
- `07-ideal-booking-flow.md` - Идеальный flow записи

---

## 🎨 Сценарии использования

### **Сценарий 1: Пост-бронинговый диалог**
```
[14:00] Клиент создает заявку на ремонт двери
[14:05] AI: "Спасибо! Заявка создана, менеджер позвонит в течение часа"
[14:06] Клиент: "Спасибо!"
...
[16:30] Клиент: "Здравствуйте, а какой примерно будет стоимость?"

🎯 **OLD:** Новый диалог (нет контекста)
🆕 **NEW:** Контекст `post_booking` (понимаем что это вопрос по заявке)
```

### **Сценарий 2: Сервисный диалог**
```
Клиент: "Сколько стоит полировка кузова?"
AI: "От 15000₽, зависит от состояния..."
Клиент: "А материалы включены? Какая гарантия?"

🎯 **OLD:** Стандартный диалог
🆕 **NEW:** Контекст `service` (понимаем что это уточнение услуг)
```

### **Сценарий 3: Жалоба**
```
Клиент: "Недоволен качеством ремонта!"

🎯 **OLD:** Стандартный диалог
🆕 **NEW:** Контекст `complaint` + немедленная эскалация руководству
```

---

## 📊 Бизнес-ценность

### **Для аналитики:**
- 📈 **Сегментация диалогов:** 6 типов вместо 1
- 🎯 **Точность метрик:** Раздельный tracking конверсии по контекстам
- ⏰ **Временные паттерны:** Понимание поведения пользователей
- 🔗 **Journey mapping:** Полная воронка клиента

### ** для AI-ассистента:**
- 🧠 **Контекстные ответы:** Адаптация под тип диалога
- ⚡ **Быстрые решения:** Шаблоны для стандартных сценариев
- 🚨 **Критические уведомления:** Автоматическая эскалация жалоб
- 💬 **Естественное общение:** Понимание намерений клиента

### **Для бизнеса:**
- 📊 **Conversion tracking:** Точные метрики конверсии по сценариям
- 🎯 **Targeted improvements:** Оптимизация конкретных сценариев
- ⚠️ **Proactive support:** Выявление проблемных диалогов
- 💰 **Revenue optimization:** Улучшение конверсии на каждом этапе

---

## 🔧 Техническая реализация

### **Подход: Гибридная детекция**

#### **1. Системный промпт (основной)**
```ruby
# app/prompts/assistant_prompt.rb
def self.context_aware_instructions
  <<~PROMPT
    Ты - AI ассистент автосервиса. Определяй контекст диалога:

    🚗 **NEW LEAD** - первый контакт, консультация цены
    📋 **POST-BOOKING** - вопросы по созданной заявке
    🛠️ **SERVICE** - уточнение деталей услуг
    😤 **COMPLAINT** - недовольство, проблемы
    💰 **OBJECTION** - возражения по цене/срокам
    ❓ **GENERAL** - общие вопросы

    Адаптируй ответы под контекст!
  PROMPT
end
```

#### **2. Keyword детекция (дополнительная)**
```ruby
def determine_dialog_context(chat_id)
  if has_recent_booking?(chat_id)
    'post_booking'
  elsif complaint_keywords_present?(chat_id)
    'complaint'
  elsif service_keywords_present?(chat_id)
    'service'
  elsif sales_objection_keywords_present?(chat_id)
    'sales_objection'
  elsif general_inquiry_keywords_present?(chat_id)
    'general_inquiry'
  else
    'primary'
  end
end
```

#### **3. Асинхронный анализ (пост-обработка)**
```ruby
# После завершения диалога - анализ паттернов
DialogAnalysisJob.perform_later(chat_id, messages)
```

---

## 📋 План реализации

### **Phase 1: Core Logic** (4 часа)
- ✅ Обновить `EventConstants` (DONE)
- 🔄 Заменить `first_message_today?` → `should_start_new_dialog?`
- 🔄 Реализовать `new_dialog_conditions_met?(chat_id)`
- 🔄 Добавить `determine_dialog_context(chat_id)`

### **Phase 2: Helper Methods** (3 часа)
- 🔄 `last_user_message_time(chat_id)`
- 🔄 `has_recent_booking?(chat_id)`
- 🔄 `calculate_time_since_last_message(chat_id)`
- 🔄 `get_last_booking_details(chat_id)`

### **Phase 3: Analytics Enhancement** (2 часа)
- ✅ Обновить `DIALOG_STARTED` свойства (DONE)
- 🔄 Добавить поля в `AnalyticsService.track`
- 🔄 Обновить `BookingNotificationJob`

### **Phase 4: Testing & Validation** (3 часа)
- 🔄 Обновить существующие тесты
- 🔄 Добавить тесты для новых сценариев
- 🔄 Интеграционные тесты

**Total:** ~12 часов реализации

---

## 🎯 Success Metrics

### **Технические метрики:**
- ✅ **Response time:** < 100ms для определения контекста
- ✅ **Accuracy:** > 95% правильное определение типа диалога
- ✅ **Coverage:** Обработка всех 6 типов сценариев
- ✅ **Performance:** Без влияния на скорость ответов

### **Бизнес метрики:**
- 📈 **Dialog quality:** Понимание паттернов поведения
- 🎯 **Conversion optimization:** Улучшение конверсии по сценариям
- ⏰ **Timing optimization:** Выявление лучших моментов для контакта
- 🔍 **Issue detection:** Быстрое выявление проблемных диалогов

---

## 🤔 Вопросы для Product Owner

1. **Приоритет контекстов:** Какие 3 контекста наиболее важны для первой версии?
2. **Уровень сложности:** Начать с keyword детекции или сразу с LLM анализа?
3. **Временные пороги:** 30 минут для нового диалога - оптимально?
4. **Эскалация жалоб:** Автоматически уведомлять руководство при жалобах?
5. **Post-booking анализ:** Какой период считать "недавней заявкой" (2 часа)?

---

## 📁 Где хранить концепцию

**Рекомендация:** `docs/concepts/` - новая директория для архитектурных концепций

### **Структура:**
```
docs/
├── concepts/                    # 🆕 Архитектурные концепции
│   ├── contextual-dialog-system.md    # Эта концепция
│   └── [future-concepts].md
├── user-scenarios/             # ✅ Сценарии использования (созданы)
├── requirements/               # User Stories
├── architecture/               # ADR решения
└── development/                # Гайды разработки
```

### **Почему не User Story:**
- **User Story** = конкретная фича для пользователя
- **Concept** = архитектурное решение spanning multiple stories
- **User Scenarios** = паттерны поведения (уже созданы)

### **Связь с сущностями:**
- **Concept** → **User Scenarios** → **Implementation Plan** → **User Stories**

---

## ✅ Next Steps

1. **Review Product Owner** - получить фидбэк по концепции
2. **Approve Implementation Plan** - утвердить 4-фазный план
3. **Start Phase 1** - обновить WebhookController с новой логикой
4. **Create Tests** - обеспечить качество реализации
5. **Monitor Analytics** - отслеживать улучшение метрик

---

**Статус:** Ready for Product Owner Review
**Создатель:** AI Assistant
**Reviewer:** Ожидает Product Owner