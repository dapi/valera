# Technical Specification: TS-002 - Telegram Service Booking Engine

**Статус:** Approved
**Приоритет:** High
**Версия:** 1.0
**Создан:** 25.10.2025
**Автор:** Technical Lead
**Ревьювер:** Senior Developer

## 📋 Обзор (Overview)

### Описание
Техническая спецификация AI-движка для записи на услуги автосервиса через Telegram. Система использует LLM для естественного диалога с клиентами, работает со встроенными ценами и асинхронно отправляет заявки в менеджерский чат.

### Цели
- [ ] Реализовать AI-ассистента с естественным диалогом
- [ ] Использовать встроенные цены для кузовных работ
- [ ] Создавать корзину услуг из контекста диалога
- [ ] Обеспечить асинхронную отправку заявок с retry механизмом
- [ ] Интегрироваться с существующей ruby_llm инфраструктурой

## 🏗️ Архитектура

### Поток данных
```
Telegram Bot → Webhook Endpoint → TelegramController → TelegramWebhookService
                                                                                     ↓
                                                                            TelegramUser Model
                                                                                     ↓
                                                                               Chat Model (ruby_llm)
                                                                                     ↓
                                                                          AI Response Generation
                                                                                     ↓
                                                                               Telegram Bot Client
                                                                                     ↓
                                                                               Response to User

Booking Flow:
Chat Context → Service Extraction → Booking Model → BookingJob → Manager Chat
```

### Основные компоненты

#### 1. Модели данных
- **TelegramUser:** Профиль пользователя Telegram
- **Chat:** Диалог с интеграцией ruby_llm
- **Booking:** Заявка на услуги

#### 2. Service слои
- **TelegramWebhookService:** Обработка webhook запросов
- **BookingJob:** Асинхронная отправка заявок менеджерам

#### 3. Интеграции
- **ruby_llm:** AI генерация ответов
- **Telegram API:** Отправка/получение сообщений
- **Solid Queue:** Фоновые задачи

## 🔧 Требования

### Функциональные требования
- **FR-001:** Естественный диалог с клиентом через ruby_llm
- **FR-002:** Включение встроенных цен в системный промпт
- **FR-003:** Извлечение корзины услуг из контекста диалога
- **FR-004:** Формирование и отправка структурированных заявок
- **FR-005:** Обработка различных классов автомобилей и цен
- **FR-006:** Асинхронная отправка сообщений через Solid Queue

### Нефункциональные требования
- **Производительность:** Время ответа AI < 5 секунд
- **Надежность:** Retry механизм для отправки заявок
- **Масштабируемость:** Поддержка 100+ одновременных диалогов
- **Отказоустойчивость:** Graceful degradation при недоступности AI
- **Мониторинг:** Bugsnag интеграция для ошибок

## 🗄️ Структура данных

### TelegramUser модель
**Таблица:** `telegram_users`
**Primary key:** `id` (telegram user id)

**Поля:**
- `id` (bigint, primary key) - Telegram user ID
- `first_name` (string) - Имя пользователя
- `last_name` (string) - Фамилия пользователя
- `username` (string) - @username в Telegram
- `photo_url` (string) - URL аватара
- `language_code` (string) - Язык пользователя
- `is_bot` (boolean) - Флаг бота
- `is_premium` (boolean) - Флаг premium
- `last_contact_at` (timestamp) - Последний контакт

**Связи:**
- `has_many :chats`
- `has_many :bookings`

**Индексы:**
- `username`
- `last_contact_at`

### Chat модель
**Таблица:** `chats` (расширение существующей ruby_llm модели)

**Дополнительные поля:**
- `telegram_user_id` (bigint, foreign key) - Связь с пользователем
- `telegram_chat_id` (bigint) - ID чата в Telegram
- `chat_type` (string) - Тип чата (private, group)

**Интеграция:**
- `acts_as_chat` (ruby_llm)
- `belongs_to :telegram_user`

### Booking модель
**Таблица:** `bookings`

**Основные поля:**
- `id` (bigint, primary key)
- `telegram_user_id` (bigint, foreign key)
- `chat_id` (bigint, foreign key, optional)
- `customer_name` (string) - Имя клиента
- `customer_phone` (string) - Телефон клиента
- `customer_telegram_username` (string) - Telegram username

**Информация об автомобиле:**
- `car_brand` (string) - Марка автомобиля
- `car_model` (string) - Модель автомобиля
- `car_year` (integer) - Год выпуска
- `car_class` (string) - Класс автомобиля (1/2/3)

**Услуги и цены:**
- `services` (json) - Массив услуг с ценами
- `total_price` (decimal) - Общая стоимость

**Предпочтения:**
- `preferred_time` (text) - Желаемое время
- `problem_description` (text) - Описание проблемы

**Статусы:**
- `status` (string) - pending, confirmed, cancelled, completed
- `sent_to_manager_at` (timestamp)
- `manager_confirmed_at` (timestamp)
- `completed_at` (timestamp)

**Индексы:**
- `status`
- `created_at`
- `telegram_user_id`
- `[status, created_at]`

### Встроенные цены
**Ценовые категории (MVP):**
```ruby
PDR_REPAIR = {
  small: { size: "до 5 см", price: 5000..7000, time: "1 день" },
  medium: { size: "5-15 см", price: 7000..10000, time: "1-2 дня" },
  large: { size: "15-25 см", price: 10000..15000, time: "2 дня" }
}

LOCAL_PAINTING = {
  small: { area: "до 1м²", price: 8000..12000, time: "2 дня" },
  large: { area: "1-2м²", price: 12000..18000, time: "3 дня" }
}

POLISHING = {
  partial: { area: "отдельные элементы", price: 4000..6000, time: "2-3 часа" },
  full: { area: "весь кузов", price: 8000..12000, time: "1 день" }
}
```

**Подход с включением в промпт:**
- **Ценовые диапазоны** добавляются в системный промпт
- **AI сам определяет категорию** из описания повреждения
- **Гибкость ценообразования** - ориентировочные диапазоны
- **Контекстная релевантность** - AI выбирает подходящую категорию

## 🌐 AI/LLM конфигурация

### ruby_llm конфигурация
- Использование существующих ENV настроек
- Системный промпт включает встроенные цены
- Контекстное окно: последние 10 сообщений
- Максимальная длина ответа: 2000 токенов

### Управление контекстом
- **Sliding window:** Удаление старых сообщений
- **Service extraction:** Выделение услуг в отдельный контекст
- **Cart management:** Корзина извлекается из диалога

### Промпт стратегия
- Базовый системный промпт + встроенные цены
- Инструкции по определению класса автомобиля
- Правила работы с корзиной услуг
- Инструкции по созданию заявок

## 🔌 Интеграции

### Внутренние зависимости
- **ruby_llm gem:** AI/LLM функциональность
- **rails application:** Existing инфраструктура
- **solid_queue:** Асинхронные задачи
- **anyway_config:** Конфигурация системы

### Внешние сервисы
- **Telegram Bot API:** Отправка и получение сообщений
- **Bugsnag:** Мониторинг ошибок
- **Менеджерский Telegram чат:** Получение заявок

### Webhook endpoint
- **URL:** `/api/v1/telegram/webhook`
- **Метод:** POST
- **Формат:** JSON (Telegram Webhook)
- **Ответ:** HTTP 200 OK

## 🔒 Безопасность

### Валидация и фильтрация
- Максимальная длина сообщения: 1000 символов
- Rate limiting: 10 сообщений в минуту на пользователя
- Базовая фильтрация небезопасного контента

### Обработка ошибок
- Graceful degradation при недоступности AI
- Retry механизм для отправки заявок
- Bugsnag интеграция для критических ошибок

## 📊 Мониторинг

### Метрики
- AI response time
- Booking request成功率
- Context tokens usage
- Ошибки и performance проблемы

### Логирование
- Структурированное логирование всех взаимодействий
- Отслеживание жизненного цикла заявок
- Мониторинг AI качества ответов

## 🚀 Deployment

### Конфигурация
- Manager chat ID через ENV
- CSV файлы в директории `data/`
- Telegram webhook уже настроен

### Environment переменные
- Существующие переменные для ruby_llm
- `MANAGER_TELEGRAM_CHAT_ID`
- `BOOKING_ENABLED`

## ⚠️ Риски и митигация

| Риск | Вероятность | Влияние | Митигация |
|------|-------------|---------|-----------|
| AI недоступен | Средняя | Высокое | Graceful degradation, уведомления в Bugsnag |
| Прайс-лист не загружен | Низкая | Среднее | Fallback на базовый набор услуг |
| Менеджер не получает заявку | Низкая | Высокое | Retry механизм, мониторинг очередей |
| Превышение контекста | Средняя | Среднее | Автоматическая обрезка контекста |
| AI не понимает формат CSV | Средняя | Среднее | Подготовка промпта с четкими инструкциями |

## 🔄 Roadmap разделения на этапы

### 🚀 Этап 1 (MVP - 1 неделя)
**Основной функционал:**
- [x] AI диалог с ruby_llm
- [x] Подготовка прайс-листа для системного промпта
- [x] Извлечение корзины из контекста
- [x] Отправка заявок через Solid Queue
- [x] Базовая обработка ошибок

**Урезанный функционал для MVP:**
- Простое включение CSV в системный промпт
- Базовые промпты без оптимизации
- Простая обработка ошибок без retry

### ⚡ Этап 2 (Улучшения - 2-3 недели)
**Оптимизация производительности:**
- [ ] Контроль длины ответов AI
- [ ] Оптимизация контекстного окна
- [ ] Кэширование промптов с прайс-листом
- [ ] Улучшенная подготовка CSV для промптов

**Качество AI:**
- [ ] Детектирование галлюцинаций модели
- [ ] Fallback сценарии при недоступности AI
- [ ] Улучшенные промпты для лучших ответов
- [ ] A/B тестирование разных подходов

## 🔗 Связанные документы

- **User Story:** [US-002-telegram-service-booking.md](../user-stories/US-002-telegram-service-booking.md)
- **Feature Description:** [feature-telegram-service-booking.md](../features/feature-telegram-service-booking.md)
- **Implementation Plan:** [protocol-telegram-service-booking.md](../../.protocols/protocol-telegram-service-booking.md) (будет создан)
- **Ruby LLM Documentation:** [../../gems/ruby_llm/README.md](../../gems/ruby_llm/README.md)
- **Telegram Bot Documentation:** [../../gems/telegram-bot/README.md](../../gems/telegram-bot/README.md)

## 📋 Ключевые технические решения

1. **Контекстная корзина** - не требует отдельного хранилища
2. **Async отправка** - надежность через Solid Queue
3. **Прайс-лист в промпте** - AI сам разбирает и использует данные
4. **Интеграция с ruby_llm** - использование существующей инфраструктуры

### Технические компромиссы для MVP
- Простое включение CSV в промпт вместо сложного парсинга
- Базовые промпты вместо оптимизированных
- Простая обработка ошибок вместо comprehensive fallback

---

**История изменений:**
- 25.10.2025 21:00 - v1.0: Создана спецификация на основе User Story и Feature Description
- 25.10.2025 23:00 - v1.1: Упрощение архитектуры, удаление кода реализации
- 25.10.2025 23:15 - v1.1: Фокус на структуре данных и моделях