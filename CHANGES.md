# CHANGES.md

Инструкции по обновлению для SRE и DevOps.

## v0.3.0 — Platform Bot Rename

### Переименование переменных окружения

| Старое имя | Новое имя | Обязательность | Описание |
|------------|-----------|----------------|----------|
| `AUTH_BOT_TOKEN` | `PLATFORM_BOT_TOKEN` | **Обязательно** | Token Telegram бота платформы |
| `AUTH_BOT_USERNAME` | `PLATFORM_BOT_USERNAME` | **Обязательно** | Username Telegram бота (без @) |
| — | `PLATFORM_ADMIN_CHAT_ID` | Опционально | ID канала для уведомлений о лидах |
| — | `ADMIN_HOST` | Опционально | Хост админки (по умолчанию `admin.${HOST}`) |

**Примечания:**
- `PLATFORM_ADMIN_CHAT_ID` — без этой переменной уведомления о лидах не отправляются
- `ADMIN_HOST` — используется для формирования ссылок в уведомлениях

### Шаги миграции

1. **Добавить новые переменные** (до деплоя):
   ```bash
   # Обязательные — скопировать значения из старых переменных
   PLATFORM_BOT_TOKEN=$AUTH_BOT_TOKEN
   PLATFORM_BOT_USERNAME=$AUTH_BOT_USERNAME

   # Опциональные — для уведомлений о лидах
   PLATFORM_ADMIN_CHAT_ID=<chat_id>
   ADMIN_HOST=admin.example.com  # или оставить пустым для admin.${HOST}
   ```

2. **Деплой приложения**

3. **Удалить старые переменные** (после проверки):
   ```bash
   # Можно удалить после успешного деплоя
   unset AUTH_BOT_TOKEN
   unset AUTH_BOT_USERNAME
   ```

### Как получить PLATFORM_ADMIN_CHAT_ID

1. Создать группу/канал в Telegram
2. Добавить Platform Bot в группу
3. Бот автоматически отправит chat_id в группу
4. Использовать этот chat_id для PLATFORM_ADMIN_CHAT_ID

### Проверка

```bash
# Проверить что бот работает
curl -X POST "https://api.telegram.org/bot$PLATFORM_BOT_TOKEN/getMe"

# Проверить отправку в канал
curl -X POST "https://api.telegram.org/bot$PLATFORM_BOT_TOKEN/sendMessage" \
  -d "chat_id=$PLATFORM_ADMIN_CHAT_ID" \
  -d "text=Test message"
```

### Миграция базы данных

```bash
# Выполнить миграцию для добавления manager_id к leads
bin/rails db:migrate
```
