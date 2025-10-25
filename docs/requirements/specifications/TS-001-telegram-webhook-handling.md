# Technical Specification: TS-001 - Telegram Webhook Handling

**Статус:** Approved
**Приоритет:** High
**Версия:** 1.2
**Создан:** 25.10.2025
**Автор:** Technical Lead
**Ревьювер:** Senior Developer

## 📋 Обзор (Overview)

### Описание
Спецификация обработки Telegram webhook'ов для автоматического приветствия новых пользователей и маршрутизации сообщений в системе Valera Bot.

### Цели
- [ ] Обработка входящих Telegram сообщений в реальном времени
- [ ] Определение новых vs существующих пользователей
- [ ] Автоматическая отправка приветственных сообщений
- [ ] Интеграция с существующей системой Chat/Message моделей

## 🔧 Требования

### Функциональные требования
- **FR-001:** Получение webhook'ов от Telegram API
- **FR-002:** Определение типа пользователя (новый/существующий)
- **FR-003:** Генерация и отправка приветственных сообщений
- **FR-004:** Создание inline клавиатуры для быстрых действий
- **FR-005:** Логирование всех взаимодействий

### Нефункциональные требования
- **Производительность:** Время ответа webhook < 200ms
- **Безопасность:** Валидация webhook'ов от Telegram
- **Масштабируемость:** Поддержка до 1000 одновременных пользователей
- **Надежность:** Retry механизм для неудачных отправок
- **Доступность:** 99.9% uptime для webhook endpoint

## 🏗️ Техническое решение (Technical Approach)

### Архитектура
```
Telegram → Webhook Endpoint → TelegramController → UserService → WelcomeService → Telegram API
```

### Компоненты
- **TelegramController:** Обработка входящих webhook'ов
- **UserService:** Управление пользователями и их состоянием
- **WelcomeService:** Генерация приветственных сообщений
- **TelegramClient:** Отправка сообщений в Telegram

### Алгоритмы и логика
1. **Получение webhook:** Валидация и парсинг входящего сообщения
2. **Определение пользователя:** Проверка существования Chat записи
3. **Логика приветствия:** Выбор соответствующего шаблона
4. **Отправка ответа:** Формирование и отправка сообщения с клавиатурой

## 🗄️ Данные и схема

### База данных
- **Модели:**
  - `Chat` (существующая) - добавление поля `last_contacted_at`
  - `Message` (существующая) - добавление поля `message_type`
- **Миграции:**
  - Добавление `last_contacted_at` к `chats`
  - Добавление `message_type` к `messages`
- **Индексы:**
  - Индекс на `chats.telegram_id`
  - Индекс на `messages.chat_id, created_at`

### Форматы данных
```ruby
# Webhook payload
{
  "update_id": 123456789,
  "message": {
    "message_id": 1,
    "from": {
      "id": 123456789,
      "first_name": "John",
      "username": "john_doe"
    },
    "chat": {
      "id": 123456789,
      "type": "private"
    },
    "text": "/start"
  }
}
```

## 🔌 Интеграции и зависимости

### Внешние сервисы
- **Telegram Bot API:** Отправка сообщений и получение webhook'ов
- **Redis:** Кэширование состояния пользователей для быстрого доступа

### Внутренние зависимости
- **ruby_llm gem:** Использование существующей Chat модели
- **anyway_config:** Конфигурация Telegram бота
- **Solid Queue:** Асинхронная отправка сообщений

### Gems и библиотеки
- **telegram-bot-rb:** Основной gem для работы с Telegram API
- **rails:** Rails framework (существующий)
- **pg:** PostgreSQL (существующий)

## 🌐 API и интерфейсы

### Endpoints
- `POST /api/v1/telegram/webhook` - Основной webhook endpoint

### Request/Response форматы
**Request:** Telegram webhook payload
**Response:** HTTP 200 OK (empty body)

```ruby
# Пример ответного сообщения
{
  "chat_id": 123456789,
  "text": "Добро пожаловать в Валера! 🚗",
  "reply_markup": {
    "inline_keyboard": [
      [
        {"text": "📅 Записаться на сервис", "callback_data": "book_service"},
        {"text": "💰 Уточнить цены", "callback_data": "check_prices"}
      ]
    ]
  }
}
```

## 🔒 Безопасность

### Аутентификация и авторизация
- Проверка секретного токена webhook'а
- Валидация источника запроса (только Telegram IP)

### Валидация данных
- Валидация формата webhook payload
- Санитизация входящих текстовых данных
- Проверка лимитов размера сообщения

### Обработка ошибок
- Логирование всех ошибок с детальной информацией
- Graceful degradation при недоступности внешних сервисов
- Retry механизм для временных сбоев

## 🧪 Тестирование

### Unit тесты
- [ ] TelegramController webhook processing
- [ ] UserService user identification logic
- [ ] WelcomeService message generation
- [ ] TelegramClient message sending

### Integration тесты
- [ ] End-to-end webhook flow
- [ ] Database integration with Chat/Message models
- [ ] Redis caching integration
- [ ] Telegram API integration (mocked)

### E2E тесты
- [ ] New user welcome flow
- [ ] Returning user re-welcome flow
- [ ] Error handling scenarios

### Performance тесты
- [ ] Load testing with 1000 concurrent users
- [ ] Response time benchmarking
- [ ] Database query optimization

## 📊 Мониторинг и логирование

### Метрики
- webhook_processing_time: Время обработки webhook
- welcome_messages_sent: Количество отправленных приветствий
- active_users: Количество активных пользователей
- error_rate: Процент ошибок

### Логи
- webhook_received: INFO уровень, формат JSON
- welcome_sent: INFO уровень, данные пользователя
- webhook_error: ERROR уровень, детали ошибки
- performance_warning: WARN уровень, медленные запросы

### Алерты
- High error rate (> 5%): Slack уведомление
- Slow webhook processing (> 500ms): PagerDuty
- Service downtime: SMS уведомление

## 🚀 Deployment

### Среды
- **Development:** Локальная настройка с ngrok для webhook'ов
- **Staging:** Отдельный bot token для тестов
- **Production:** Основной бот с мониторингом

### Rollback план
1. Отключить webhook в Telegram Bot API
2. Откатить код на предыдущую версию
3. Проверить работоспособность
4. Включить webhook с обновленным URL

## ⚠️ Риски и митигация

| Риск | Вероятность | Влияние | Митигация |
|------|-------------|---------|-----------|
| Telegram API недоступен | Средняя | Высокое | Retry механизм, очередь сообщений |
| Высокая нагрузка | Средняя | Среднее | Rate limiting, кэширование, масштабирование |
| Спам атаки | Высокая | Низкое | Rate limiting, blacklist |
| Потеря сообщений | Низкая | Высокое | Транзакции, логирование, мониторинг |

## 🔗 Связанные документы

- **User Story:** [US-001-telegram-auto-greeting.md](../user-stories/US-001-telegram-auto-greeting.md)
- **Feature Description:** [feature-telegram-welcome-experience.md](../features/feature-telegram-welcome-experience.md)
- **Implementation Plan:** [protocol-telegram-welcome.md](../../.protocols/protocol-telegram-welcome.md)
- **Telegram Gem Documentation:** [../../gems/telegram-bot/README.md](../../gems/telegram-bot/README.md)

## 📋 Заметки и вопросы

- Нужно определить стратегию обработки пользователей, которые заблокировали бота
- Требуется A/B тестирование разных вариантов приветственных сообщений
- Необходимо настроить мониторинг количества активных пользователей

---

**История изменений:**
- 25.10.2025 14:30 - v1.0: Создан черновик
- 25.10.2025 16:45 - v1.1: Добавлены детали по безопасности
- 25.10.2025 17:20 - v1.2: Добавлены требования к производительности и мониторингу