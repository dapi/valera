# FIP-002: Chat ID Detection для групп

**Статус:** Draft
**Версия:** 1.0
**Создан:** 28.10.2025
**Автор:** AI Assistant
**Обновлен:** 28.10.2025

## 🎯 Обзор функции (Feature Overview)

**Название функции:** Определение и уведомление chat_id при добавлении бота в группу
**Проблема:** Владельцам автосервисов нужно знать chat_id групп для настройки бота
**Решение:** Автоматическое определение chat_id при добавлении бота И при миграции группы в супергруппу
**Приоритет:** High (критически важно для онбординга)

## 🎯 User Story

**As a** автосервис владелец
**I want** получить chat_id группы когда добавляю бота
**So that** я могу настроить бота для работы с моей группой

## 🏗️ Технический анализ

### Текущая архитектура:
- `telegram_bot_updates_controller` (gem)
- Webhook контроллер `app/controllers/telegram/webhook_controller.rb`
- `TelegramUser` модель с методами работы с Telegram данными
- `BookingNotificationJob` как паттерн для Job реализации

### Что нужно добавить:
1. **Обработчик `new_chat_members`** - для добавления бота
2. **Обработчик `migrate_to_supergroup`** - для миграции групп
3. **`ChatIdNotificationJob`** - для асинхронной отправки
4. **Методы получения bot_id** - из токена

## 📝 Детальный план реализации

### Phase 1: Добавление локализации

**Файл:** `config/locales/ru.yml`
```yaml
ru:
  chat_id_notification:
    message: "🎉 Бот добавлен в чат!\n\n📋 Chat ID для настройки: ` %{chat_id} `\n\nИспользуйте этот ID в настройках для работы с чатом."
```

### Phase 2: Добавление методов в ApplicationConfig

**Файл:** `config/configs/application_config.rb`
```ruby
# В class ApplicationConfig

# Возвращает username бота из токена
def bot_username
  @bot_username ||= extract_bot_info_from_token[:username]
end

# Возвращает ID бота из токена
def bot_id
  @bot_id ||= extract_bot_info_from_token[:id]
end

private

# Извлекает информацию о боте из токена через Telegram API
def extract_bot_info_from_token
  return { id: nil, username: nil } if bot_token.blank?

  # Кешируем результат, чтобы не делать лишние запросы
  @bot_info ||= begin
    client = Telegram::Bot::Client.new(bot_token)
    bot_info = client.api.get_me
    {
      id: bot_info['id'],
      username: bot_info['username']
    }
  rescue => e
    Rails.logger.error "Failed to get bot info from token: #{e.message}"
    { id: nil, username: nil }
  end
end
```

### Phase 3: Создание ChatIdNotificationJob

**Файл:** `app/jobs/chat_id_notification_job.rb`
```ruby
# frozen_string_literal: true

# Job для отправки уведомления с chat_id при добавлении бота в группу
class ChatIdNotificationJob < ApplicationJob
  include ErrorLogger

  queue_as :default
  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  # Отправляет уведомление с chat_id в чат
  # @param chat_id [Integer] ID чата, куда отправить уведомление
  def perform(chat_id)
    Telegram.bot.send_message(
      chat_id: chat_id,
      text: I18n.t('chat_id_notification.message', chat_id: chat_id),
      parse_mode: 'Markdown'
    )
  rescue StandardError => e
    log_error(e, job: self.class.name, chat_id: chat_id)
    raise e
  end
end
```

### Phase 4: Обработчики в WebhookController

**Файл:** `app/controllers/telegram/webhook_controller.rb`

#### 1. Обработчик добавления бота:
```ruby
# Обработчик добавления новых участников в чат
def new_chat_members(message)
  chat_id = message.dig('chat', 'id')
  new_members = message['new_chat_members']

  # Проверяем что добавлен ИМЕННО НАШ бот по ID
  bot_added = new_members&.any? do |member|
    member['is_bot'] && member['id'] == ApplicationConfig.bot_id
  end

  ChatIdNotificationJob.perform_later(chat_id) if bot_added
end
```

#### 2. Обработчик миграции в супергруппу:
```ruby
# Обработчик миграции группы в супергруппу (меняется chat_id)
def migrate_to_supergroup(message)
  new_chat_id = message.dig('chat', 'id')
  ChatIdNotificationJob.perform_later(new_chat_id)
end
```

## 🔧 Технические детали

### Telegram Bot API события:

#### 1. **new_chat_members** - добавление участников:
```json
{
  "update_id": 123456789,
  "message": {
    "message_id": 1,
    "chat": {
      "id": -1001234567890,
      "type": "supergroup"
    },
    "new_chat_members": [
      {
        "id": 111111111,
        "is_bot": true,
        "first_name": "Valera Bot",
        "username": "valera_bot"
      }
    ]
  }
}
```

#### 2. **migrate_to_supergroup** - миграция группы:
```json
{
  "update_id": 123456790,
  "message": {
    "message_id": 2,
    "chat": {
      "id": -1001234567890,
      "type": "supergroup"
    },
    "migrate_from_chat_id": -123456789
  }
}
```

### Ключевая логика проверки:
```ruby
# Проверка только нашего бота по ID
member['is_bot'] && member['id'] == ApplicationConfig.bot_id
```

## ⚠️ Риски и Mitigation

### Риски:
1. **Неправильный bot_id** - бот не будет реагировать на добавление
2. **Нет прав на отправку** - бот не сможет написать в группу
3. **Rate limiting** - слишком частые сообщения
4. **Ошибка получения bot_info** - проблемы с токеном

### Mitigation:
1. **Грейсфул деградация** - логировать ошибки но не падать
2. **Retry логика** - встроена в Job (3 попытки с экспоненциальным ростом)
3. **Кеширование bot_info** - один запрос при старте приложения

## 📊 Success Metrics

- **Functional**: 100% определение chat_id при добавлении бота
- **Migration Support**: Автоматическое уведомление при миграции групп
- **Performance**: <1 секунды на обработку события
- **Reliability**: Retry логика при ошибках отправки
- **Accuracy**: 0% ложных срабатываний (только наш бот)

## 🚀 Implementation Order

1. **I18n локализация** - добавить сообщение
2. **ApplicationConfig методы** - bot_id/bot_username из токена
3. **ChatIdNotificationJob** - создать по паттерну BookingNotificationJob
4. **Webhook обработчики** - добавить в контроллер
5. **Тестирование** - проверить в реальной группе
6. **Мониторинг** - отслеживать работу Job

## 🎯 Результат для пользователя

**При добавлении бота в группу:**
```
🎉 Бот добавлен в чат!

📋 Chat ID для настройки: ` -1001234567890 `

Используйте этот ID в настройках для работы с чатом.
```

**При миграции группы в супергруппу:**
```
🎉 Бот добавлен в чат!

📋 Chat ID для настройки: ` -1009876543210 `

Используйте этот ID в настройках для работы с чатом.
```

## 🔗 Связанные документы

- [Product Constitution](../../product/constitution.md)
- [Architecture Decisions](../../architecture/decisions.md)
- [Error Handling Patterns](../../patterns/error-handling.md)
- [Telegram Gem Documentation](../../gems/telegram-bot/README.md)
- [BookingNotificationJob](../../../app/jobs/booking_notification_job.rb) - паттерн

---

**История изменений:**
- v1.0 (28.10.2025) - Создание FIP с использованием bot_id и Job архитектуры