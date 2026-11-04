# CHANGES.md

Инструкции по обновлению для SRE и DevOps.

## 0.45.0 — ассеты при rolling update

- `SHARED_ASSETS_PATH` включает раздачу immutable fingerprint-файлов из общего
  каталога. `SHARED_ASSET_CACHE_SECONDS` по умолчанию 31536000.
- `bin/publish-shared-assets --source public/assets --target <каталог>`
  публикует файлы без перезаписи и проверяет SHA256 при совпадении имён.
- `ASSET_MANIFEST_PATH` — временный путь к manifest старой версии для первого
  миграционного rollout. После замены всех старых web pods убрать override;
  далее каждая реплика использует manifest своего image.
- PVC и init-контейнеры управляются из `~/code/brandymint/infra`.
  Web монтирует каталог только на чтение; publisher завершается до ready.
  Старые файлы автоматически не удаляются. Откат приложения сохраняет PVC;
  откаты на версию без shared middleware требуют проверки доступности ассетов.
- Изменений схемы БД нет. Почтовый транспорт сохранён: получение тестовых писем
  подтверждено во входящих двух собственных аккаунтов.

## Следующее обновление — ответы менеджера из dashboard

Менеджер может перехватить чат, ответить клиенту в Telegram и вернуть диалог боту.
Через 30 минут бездействия диалог автоматически возвращается боту.

- Перед запуском новой версии выполнить `bin/rails db:migrate`: добавлены поля
  перехвата чата, отправителя сообщения и индексы. Существующая схема RubyLLM 2
  сохраняется.
- `MANAGER_TAKEOVER_ENABLED` — по умолчанию `true`; `false` скрывает управление
  перехватом и отключает соответствующие endpoints.
- `MANAGER_TAKEOVER_TIMEOUT_MINUTES` — по умолчанию `30`.
- `CHATS_PER_PAGE` — по умолчанию `20` для подгрузки списка диалогов.
- Для автоматического возврата боту должен работать обработчик фоновых заданий.
- Обновлены исправления безопасности в Rack, Nokogiri, Addressable, Crass,
  Loofah, rails-html-sanitizer и Sanitize; после обновления установить зависимости.

## v0.24.0 — Chat Topic Classification (LLM Analytics)

### Описание

Добавлена автоматическая классификация тем чатов с помощью LLM для аналитики.

**Функциональность:**
- Классификация чатов по темам (booking, service_info, price_inquiry, etc.)
- Аналитика популярных тем обращений клиентов
- Автоматическая классификация после создания заявки или по таймауту неактивности

### Новые переменные окружения

| Переменная | Обязательность | По умолчанию | Описание |
|------------|----------------|--------------|----------|
| `TOPIC_CLASSIFIER_ENABLED` | Опционально | `false` | Включить классификацию топиков |
| `TOPIC_CLASSIFIER_MODEL` | Опционально | — | Модель LLM (если не указана, используется `LLM_MODEL`) |
| `TOPIC_CLASSIFIER_INACTIVITY_HOURS` | Опционально | `24` | Часы неактивности до автоклассификации |

**Важно:** Классификация **отключена по умолчанию** для экономии API вызовов.

### Включение классификации

```bash
# Для включения установите:
TOPIC_CLASSIFIER_ENABLED=true

# Опционально: использовать дешёвую модель для классификации
TOPIC_CLASSIFIER_MODEL=gpt-4o-mini
```

### Миграции

```bash
bin/rails db:migrate
```

Создаются таблицы:
- `chat_topics` — справочник тем
- Добавляется `chat_topic_id` к `chats`
- Индексы для оптимизации запросов

### Seeds

```bash
bin/rails db:seed
```

Создаются глобальные топики по умолчанию.

---

## v0.23.0 — Migration from SolidQueue to GoodJob

### Описание

Миграция системы фоновых задач с SolidQueue на GoodJob для улучшенного мониторинга и эффективности.

**Преимущества GoodJob:**
- Лучший встроенный Web UI для мониторинга задач
- LISTEN/NOTIFY вместо polling (эффективнее для PostgreSQL)
- Единая база данных (queue DB больше не нужна)

### Шаги миграции

1. **Выполнить миграции базы данных:**
   ```bash
   bin/rails db:migrate
   ```

2. **Обновить команду запуска job worker:**
   ```bash
   # Было:
   bin/rails solid_queue:start

   # Стало:
   bin/rails good_job:start
   ```

3. **Удалить старую queue базу данных** (после успешного деплоя):
   ```bash
   dropdb valera_production_queue
   ```

### Изменения в конфигурации

| Компонент | Было | Стало |
|-----------|------|-------|
| Job adapter | `solid_queue` | `good_job` |
| Dashboard URL | `/admin/jobs` (MissionControl) | `/admin/jobs` (GoodJob) |
| Queue database | Отдельная БД `valera_production_queue` | Основная БД |
| Job worker | `solid_queue:start` | `good_job:start` |

### Procfile / Docker

Обновить команду запуска worker:
```yaml
# Procfile
jobs: bin/rails good_job:start
```

### Проверка

```bash
# Проверить что GoodJob работает
bin/rails runner "puts GoodJob::Job.count"

# Проверить dashboard (требует авторизации admin)
curl -I https://admin.example.com/jobs
```

---

## v0.3.1 — Public Port Configuration

### Новая переменная окружения

| Имя | Обязательность | По умолчанию | Описание |
|-----|----------------|--------------|----------|
| `PUBLIC_PORT` | Опционально | 443 (https) / 80 (http) | Публичный порт для формирования URL |

**Проблема:** Ранее `PORT` использовался как для запуска приложения, так и для формирования публичных URL. Это приводило к некорректным URL вида `https://3010.brandymint.ru:3010` вместо `https://3010.brandymint.ru`.

**Решение:** Добавлена переменная `PUBLIC_PORT`, которая определяет порт для публичных URL независимо от внутреннего порта приложения.

### Логика определения публичного порта

1. Если `PUBLIC_PORT` задан — используется он
2. Иначе определяется из протокола:
   - `https` → 443
   - `http` → 80

### Примеры

```bash
# Стандартная конфигурация (PUBLIC_PORT не нужен)
HOST=example.com
PROTOCOL=https
PORT=3000
# Результат: https://example.com (порт 443 не добавляется в URL)

# Нестандартный публичный порт
HOST=example.com
PROTOCOL=https
PORT=3000
PUBLIC_PORT=8443
# Результат: https://example.com:8443
```

### Миграция

**Действий не требуется** — если `PUBLIC_PORT` не задан, порт определяется автоматически из протокола.

---

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

## 0.44.1 — 04.11.2026

Rails 8.1.4.1. Новые аддитивные миграции inbox Telegram и статуса доставки заявок. GoodJob и бизнес-записи используют primary PostgreSQL в общей транзакции, enqueue не откладывается после commit. Worker должен работать до smoke webhook. В production включён GoodJob cron (также запускает уже настроенную классификацию неактивных чатов, если она включена). Обработанные payload очищаются ежедневно через GoodJob cron, идентификаторы дедупликации сохраняются.

Новые настройки ApplicationConfig (ENV без префикса): LOGIN_IP_ATTEMPTS=30, LOGIN_ACCOUNT_ATTEMPTS=10, LOGIN_WINDOW_SECONDS=600; TELEGRAM_UPDATE_ATTEMPTS=10, TELEGRAM_UPDATE_RETRY_SECONDS=5; TELEGRAM_DELIVERY_ATTEMPTS=10, TELEGRAM_DELIVERY_RETRY_SECONDS=5; TELEGRAM_PAYLOAD_RETENTION_DAYS=7. Значения по умолчанию, новые секреты не нужны.

Статус доставки виден в заявке. При финальной ошибке уведомления заявка остаётся доступна в ЛК. Изменения UI: мобильное меню, ссылка на тарифы, уточнение обещаний лендинга.

## 0.44.2 — 04.11.2026

Перенос ссылок подвала тарифов на мобильном экране. В production worker ограничен двумя execution threads при существующем пуле БД 5; запас оставлен для служебных соединений GoodJob. CPU/RAM limits не менялись. Основная логика выпуска 0.44.1 не менялась.
