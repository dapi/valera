# Feature Implementation Plan: FIP-002b - Telegram Recording + Booking

**Приоритет:** High
**Сложность:** Simple (LLM Tool подход)
**Статус:** Draft
**Создан:** 25.10.2025
**Обновлен:** 25.10.2025
**User Story:** US-002b-telegram-recording-booking.md
**Dependencies:** US-001 (приветствие), FIP-002a (консультация)

## 🎯 User Story

**As a** владелец автомобиля, который получил ориентировочную стоимость ремонта и хочет записаться на детальный осмотр
**I want to** быстро и удобно записаться на бесплатный осмотр через естественный диалог в Telegram
**so that** я могу получить точную оценку стоимости и согласовать ремонт в удобное для меня время

### Критерии приемки
- [ ] **Functional:** Клиент может записаться на осмотр через диалог, бот создает заявку в менеджерский чат
- [ ] **User Experience:** 60% консультаций переходят в запись, 90% клиентов приходят на осмотр
- [ ] **Performance:** Response time < 3 секунд, заявки доставляются менеджерам мгновенно

## 🏗️ Технический подход

### Архитектура (LLM Tool Approach)
```yaml
components:
  - name: "TelegramWebhookController"
    type: "Controller"
    responsibility: "Прием webhook от Telegram, передача в LLM"
    implementation_status: "✅ ГОТОВО (требует минимальных изменений)"

  - name: "BookingCreator Tool"
    type: "LLM Tool (ruby_llm)"
    responsibility: "Создание записи через tool calling mechanism"
    implementation_status: "⚠️ НУЖНА РЕАЛИЗАЦИЯ"

  - name: "BookingNotificationJob"
    type: "Job"
    responsibility: "Асинхронная отправка заявок в менеджерский чат"
    implementation_status: "⚠️ НУЖНА РЕАЛИЗАЦИЯ"

  - name: "Booking модель"
    type: "Model"
    responsibility: "Хранение заявок со статусами"
    implementation_status: "⚠️ НУЖНА РЕАЛИЗАЦИЯ"

  - name: "Chat/Message (ruby_llm)"
    type: "Models"
    responsibility: "Сохранение истории диалогов, tool registration"
    implementation_status: "✅ ГОТОВО"
```

### 🤖 LLM Tool System Design

**Core Concept:** Используем встроенный **tool calling** механизм ruby_llm для естественной записи через AI.

```ruby
# Tool Registration в Chat модели
class Chat < ApplicationRecord
  acts_as_chat

  tool :booking_creator,
       description: "Записывает клиента на осмотр в автосервис",
       parameters: {
         type: "object",
         properties: {
           customer_name: { type: "string", description: "Имя клиента" },
           customer_phone: { type: "string", description: "Телефон клиента" },
           car_info: {
             type: "object",
             properties: {
               brand: { type: "string" },
               model: { type: "string" },
               year: { type: "integer" },
               car_class: { type: "integer", description: "Класс автомобиля (1/2/3)" }
             }
           },
           preferred_date: { type: "string", description: "Предпочтительная дата (LLM определяет из диалога)" },
           preferred_time: { type: "string", description: "Предпочтительное время (LLM определяет из диалога)" }
         },
         required: ["customer_name", "customer_phone", "car_info"]
       }
end
```

### Основные технологии
- **Framework:** Ruby on Rails 8.1
- **AI:** ruby_llm gem (acts_as_chat, acts_as_message)
- **Background Jobs:** Solid Queue
- **External:** Telegram API
- **Database:** PostgreSQL

### Data Flow (LLM Tool Approach)
```mermaid
graph LR
    A[Клиент: "Хочу записаться"] --> B[TelegramWebhookController]
    B --> C[ruby_llm Chat.ask]
    C --> D[AI анализирует intent]
    D --> E[Сбор данных из контекста]
    E --> F[Вызов booking_creator tool]
    F --> G[Booking.create]
    G --> H[BookingNotificationJob.perform_later]
    H --> I[Manager Chat Notification]
    I --> J[Client Confirmation]
```

### 🔄 Как работает Tool System

#### **Сценарий 1: Естественный диалог**
```
Клиент: Да, хочу записаться на осмотр завтра утром

LLM Process:
1. Определяет intent: "запись на завтра утром"
2. Извлекает данные из контекста диалога:
   - customer_name: "Александр" (из предыдущих сообщений)
   - customer_phone: "+7(916)123-45-67" (из контекста)
   - car_info: {brand: "Toyota", model: "Camry", year: 2018}
3. Вызывает booking_creator tool с параметрами
4. Возвращает результат клиенту
```

#### **Сценарий 2: Запрос уточняющей информации**
```
Клиент: Хочу записаться

LLM: Для записи мне понадобится:
🚗 Марка, модель и год вашего авто
📞 Ваш номер телефона
⏰ Когда удобно приехать?

Клиент: Toyota Camry 2018, +7(916)123-45-67, завтра в 10:00

LLM: Вызывает booking_creator tool с полными данными
```

## 📋 План реализации (LLM Tool Approach - Simplified)

### Phase 1: Foundation (1 день)
- [ ] Создать Booking модель
  - Поля: customer_name, customer_phone, car_brand, car_model, car_year, preferred_date (date), preferred_time (string), status
  - Связи с TelegramUser и Chat
  - Валидации данных (формат телефона, обязательные поля)
- [ ] Реализовать BookingCreatorTool
  - Tool handler для ruby_llm
  - Валидация параметров
  - Создание Booking записи
- [ ] Зарегистрировать tool в Chat модели
  - Tool definition с параметрами
  - Handler registration
  - Error handling

### Phase 2: Integration (1 день)
- [ ] Создать BookingNotificationJob
  - Форматирование заявки
  - Отправка в менеджерский чат
  - Retry механизм
- [ ] Обновить системный промпт
  - Инструкции по tool usage
  - Временные слоты (жестко заданные)
  - Правила сбора данных
- [ ] Минимальные изменения в TelegramWebhookController
  - Поддержка tool responses (уже работает через ruby_llm)
  - Базовая обработка ошибок

### Phase 3: Polish (0.5 дня)
- [ ] Написать тесты
  - Tool calling тесты
  - Integration тесты полного flow
  - Unit тесты для Booking модели
- [ ] UX оптимизация
  - Тестирование диалогов
  - Обработка edge cases
  - Мониторинг метрик

**Total Implementation Time: 2.5 дня (vs 4 дня в оригинальном плане)**

## 🛠️ Техническая реализация Tool System

### BookingCreatorTool Implementation

```ruby
# app/tools/booking_creator_tool.rb
class BookingCreatorTool
  def self.call(parameters:, context:)
    # Валидация параметров
    return error_response("Отсутствуют обязательные данные") unless required_params_present?(parameters)

    # Создание заявки
    # LLM сама определяет все данные из контекста диалога (Product Constitution compliance)
  booking = Booking.new(
      customer_name: parameters[:customer_name],
      customer_phone: parameters[:customer_phone],
      car_brand: parameters[:car_info][:brand],
      car_model: parameters[:car_info][:model],
      car_year: parameters[:car_info][:year],
      car_class: parameters[:car_info][:car_class],
      preferred_date: parameters[:preferred_date], # LLM определяет сама
      preferred_time: parameters[:preferred_time], # LLM определяет сама
      telegram_user: context[:telegram_user],
      chat: context[:chat],
      status: :pending
    )

    if booking.save
      # Асинхронная отправка в менеджерский чат
      BookingNotificationJob.perform_later(booking)

      success_response(booking)
    else
      error_response("Не удалось создать запись: #{booking.errors.full_messages.join(', ')}")
    end
  end

  # LLM сама определяет время из контекста диалога
# Никакого парсинга или маппинга согласно Product Constitution

  def self.success_response(booking)
    {
      success: true,
      message: "✅ Записал вас на #{booking.preferred_date} в #{booking.preferred_time}! 📍 г. Чебоксары, Ядринское ш., 3\nМенеджер перезвонит в течение часа для подтверждения.",
      booking_id: booking.id
    }
  end

  def self.error_response(message)
    {
      success: false,
      message: "❌ #{message}. Пожалуйста, проверьте данные и попробуйте снова."
    }
  end

  def self.required_params_present?(parameters)
    parameters[:customer_name].present? &&
    parameters[:customer_phone].present? &&
    parameters[:car_info]&.dig(:brand).present? &&
    parameters[:car_info]&.dig(:model).present? &&
    parameters[:car_info]&.dig(:year).present?
  end
end
```

### Chat Model с Tool Registration

```ruby
# app/models/chat.rb
class Chat < ApplicationRecord
  acts_as_chat

  belongs_to :telegram_user
  has_many :messages, dependent: :destroy
  has_many :bookings, dependent: :destroy

  # Tool для создания записи
  tool :booking_creator,
       description: "Создает запись клиента на осмотр в автосервис",
       handler: "BookingCreatorTool",
       parameters: {
         type: "object",
         properties: {
           customer_name: {
             type: "string",
             description: "Полное имя клиента"
           },
           customer_phone: {
             type: "string",
             description: "Телефон клиента в формате +7(XXX)XXX-XX-XX"
           },
           car_info: {
             type: "object",
             description: "Информация об автомобиле клиента",
             properties: {
               brand: { type: "string", description: "Марка автомобиля" },
               model: { type: "string", description: "Модель автомобиля" },
               year: { type: "integer", description: "Год выпуска автомобиля" },
               car_class: { type: "integer", description: "Класс автомобиля (1/2/3)" }
             },
             required: ["brand", "model", "year"]
           },
           preferred_date: {
             type: "string",
             description: "Предпочтительная дата (LLM определяет из контекста диалога)"
           },
           preferred_time: {
             type: "string",
             description: "Предпочтительное время (может быть точным '10:00' или примерным 'утром', LLM определяет из диалога)"
           }
         },
         required: ["customer_name", "customer_phone", "car_info"]
       }
end
```

### Обновленный системный промпт

```markdown
# Инструкция по записи через Booking Creator Tool

## 🎯 Когда использовать booking_creator tool:

Вызывай tool когда клиент:
- Прямо просит записаться: "записаться", "хочу на осмотр", "когда можно приехать"
- Выражает намерение после консультации: "отлично, хочу записаться", "давай запишемся"
- Спрашивает о времени: "а когда можно заехать?", "есть свободное время?"

## 📋 Алгоритм работы:

1. **Проверь контекст диалога:**
   - Уже известны ли имя, телефон, авто из предыдущих сообщений?
   - Клиент уже упоминал свою машину или контакты?

2. **Собери недостающие данные:**
   ```
   Если данных не хватает → спроси:
   🚗 Марка, модель и год вашего авто
   📞 Ваш номер телефона
   📅 На какую дату записаться?
   ⏰ Удобное время дня?
   ```

3. **Вызови booking_creator tool** с собранными данными:
   ```json
   {
     "customer_name": "Александр",
     "customer_phone": "+7(916)123-45-67",
     "car_info": {
       "brand": "Toyota",
       "model": "Camry",
       "year": 2018,
       "car_class": 2
     },
     "preferred_date": "28.10.2025",
     "preferred_time": "10:00-11:00"
   }
   ```
   *LLM сама определяет точные значения из контекста диалога*

## ⏰ Временные слота:

### Доступные слоты:
- **Утро:** 10:00-11:00
- **День:** 14:00-15:00
- **Вечер:** 16:00-17:00

### Время работы:
- **Будни:** 9:00-20:00
- **Суббота:** 9:00-18:00
- **Воскресенье:** выходной

### Для LLM:
- LLM сама определяет точное время из контекста диалога
- Клиент может говорить "завтра в 10:00" или "утром"
- LLM сама выбирает подходящий слот или предлагает альтернативы
- Никакого парсинга или маппинга в коде

**Product Constitution Compliance:** Вся логика работы с временем находится в LLM, а не в коде.

## ✅ После создания записи:
Сообщи клиенту результат работы tool:
- При успехе: подтверждение времени, адрес, что менеджер перезвонит
- При ошибке: попроси уточнить данные и попробуй снова

**Важно:** Не создавай запись без явного запроса клиента!
```

## ⚠️ Риски и зависимости

**Риски:**
- [ ] **Low:** AI некорректно определяет intent на запись → LLM достаточно хорошо справляется
- [ ] **Low:** Tool extraction ошибается с данными → валидация в tool handler
- [ ] **Low:** Менеджеры не получают заявки → retry механизм в Job
- [ ] **Low:** Time slot logic слишком простая → можно усложнить позже

**Преимущества Tool Approach:**
- ✅ Упрощенная архитектура (убрали TimeSlotService)
- ✅ Естественный диалог через AI
- ✅ Гибкость в обработке разных формулировок
- ✅ Автоматический extract из контекста
- ✅ Легкое тестирование и отладка

**Зависимости:**
- [x] US-001 приветствие (уже реализовано)
- [x] FIP-002a консультация (в процессе)
- [x] ruby_llm gem настроен и работает
- [x] Telegram webhook функционирует корректно
- [ ] Менеджерский чат доступен

## 🧪 Тестирование

**Что протестировать:**
- [ ] Полный user journey: консультация → запись → подтверждение
- [ ] Корректность сбора данных клиента (имя, телефон, авто)
- [ ] Генерация и предложение временных слотов
- [ ] Формат и доставка заявок в менеджерский чат
- [ ] Обработка исключений (все слоты заняты, неполные данные)
- [ ] Performance тесты (< 3 секунд на ответ)
- [ ] Конверсионные метрики (60% консультаций → запись)

## 📊 Метрики успеха

**Functional:**
- [ ] 60% консультаций переходят в создание заявки
- [ ] 90% созданных заявок подтверждаются менеджерами
- [ ] 95% клиентов приходят на осмотр после подтверждения
- [ ] Среднее время сбора данных < 2 минут

**Technical:**
- [ ] Response time < 3 seconds
- [ ] 99.9% доставляемости заявок в менеджерский чат
- [ ] No data loss в процессе записи
- [ ] Code coverage > 80%
- [ ] Zero critical errors в production

## 📱 Временные слоты (MVP)

### Формат слотов:
```yaml
schedule:
  tomorrow:
    morning:
      - start: "10:00"
        end: "11:00"
        available: 3
      - start: "11:00"
        end: "12:00"
        available: 2
    afternoon:
      - start: "14:00"
        end: "15:00"
        available: 3
      - start: "15:00"
        end: "16:00"
        available: 2
      - start: "16:00"
        end: "17:00"
        available: 1
  day_after_tomorrow:
    # аналогичная структура
```

**Всего 10 слотов на 2 дня** - реалистично для одного мастера

## 💬 Пример диалога (реализация)

```
Клиент: Да, хочу записаться на осмотр

Бот: Отлично! Для записи мне нужна небольшая информация.
🚗 Марка, модель и год авто:
📞 Ваш номер телефона:
👤 Ваше имя:

Клиент: Toyota Camry, 2018, +7(916)123-45-67, Александр

Бот: Спасибо, Александр! 🚗 Toyota Camry 2018

Предлагаю доступное время для осмотра:
📅 Завтра (27 октября):
  - 10:00 - 11:00 ✅
  - 14:00 - 15:00 ✅
  - 16:00 - 17:00 ✅

📅 Послезавтра (28 октября):
  - 11:00 - 12:00 ✅
  - 15:00 - 16:00 ✅

Какое время вам удобно?

Клиент: Завтра в 10:00

Бот: ✅ Записал вас на завтра, 27 октября в 10:00!
📍 Адрес: г. Чебоксары, Ядринское ш., 3
⏰ Планируемое время осмотра: 30-40 минут

Менеджер перезвонит вам в течение часа для подтверждения записи.
Осмотр бесплатный и ни к чему не обязывает.

[Фоновая задача: BookingNotificationJob → Manager Chat]
```

## 🗄️ Структура данных

### Booking модель:
```ruby
class Booking < ApplicationRecord
  belongs_to :telegram_user
  belongs_to :chat, optional: true

  # Данные клиента
  validates :customer_name, presence: true
  validates :customer_phone, presence: true, format: { with: PHONE_REGEX }
  validates :car_brand, :car_model, :car_year, presence: true

  # Время и статус
  validates :scheduled_at, presence: true
  validates :status, presence: true, inclusion: { in: %w[pending confirmed cancelled completed] }

  enum status: { pending: 'pending', confirmed: 'confirmed', cancelled: 'cancelled', completed: 'completed' }

  # Метаданные
  store :metadata, accessors: [:dialog_context, :services_discussed, :cost_estimate]

  scope :upcoming, -> { where('scheduled_at > ?', Time.current).where(status: :confirmed) }
  scope :for_date, ->(date) { where(scheduled_at: date.all_day) }
end
```

## 📋 Manager Chat Notification Format

```markdown
🚗 НОВАЯ ЗАЯВКА НА ОСМОТР

👤 Клиент: Александр (@username)
📞 Телефон: +7(916)123-45-67

🚗 Автомобиль: Toyota Camry, 2018
⏰ Время записи: Завтра (27.10) в 10:00
📍 Адрес: г. Чебоксары, Ядринское ш., 3

📝 История диалога:
Клиент интересовался стоимостью ремонта вмятины на передней левой двери.
Ориентировочная стоимость PDR: 7000-10000₽

🔗 Ссылка на диалог: [telegram ссылка]

⚡ СРОЧНО: Перезвонить клиенту в течение часа для подтверждения!
```

---

**Implementation notes:**
- Использовать существующую архитектуру FIP-002a как основу
- Focus на плавном переходе от консультации к записи
- Временные слоты генерировать динамически
- Асинхронная отправка заявок для надежности

**Change log:**
| Дата | Изменение |
|------|-----------|
| 25.10.2025 | Initial version from US-002b requirements |
| | |