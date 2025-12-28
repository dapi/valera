# Configuration Guide

**Обновлено:** 2025-12-28

Руководство по настройке переменных окружения для приложения Super Valera.

---

## Overview

Проект использует [anyway_config](https://github.com/palkan/anyway_config) для управления конфигурацией. Конфигурация определена в `config/configs/application_config.rb` с пустым префиксом (`env_prefix ''`), что означает прямое использование имён переменных окружения.

**Преобразование имён:** `snake_case` атрибуты → `SCREAMING_SNAKE_CASE` переменные окружения.

**Порядок загрузки (последующие переопределяют предыдущие):**
1. **Defaults** — значения по умолчанию в `attr_config`
2. **YAML files** — `config/application.yml`
3. **Environment variables** — переменные окружения

---

## Required Variables

Эти переменные **обязательны** для запуска приложения (определены через `required` в ApplicationConfig):

| Переменная | Тип | Описание |
|------------|-----|----------|
| `LLM_PROVIDER` | string | Провайдер LLM: `openai`, `anthropic`, `deepseek`, `gemini`, `mistral`, `openrouter`, `perplexity` |
| `LLM_MODEL` | string | Модель LLM (например: `gpt-4o`, `claude-sonnet-4-20250514`, `deepseek-chat`) |

---

## Telegram Auth Bot

Единый бот для авторизации и уведомлений владельцев (tenant-боты создаются динамически):

| Переменная | Тип | Default | Описание |
|------------|-----|---------|----------|
| `AUTH_BOT_TOKEN` | string | — | Telegram Bot API token для auth-бота |
| `AUTH_BOT_USERNAME` | string | — | Username бота (без @) |
| `TELEGRAM_AUTH_EXPIRATION` | integer | `300` | TTL токенов авторизации в секундах (5 минут) |
| `WEBHOOK_PORT` | integer | — | Порт для webhook сервера (если используется) |

---

## LLM Provider API Keys

Укажите API ключ для выбранного провайдера:

| Переменная | Провайдер | Описание |
|------------|-----------|----------|
| `OPENAI_API_KEY` | OpenAI | API ключ для GPT моделей |
| `ANTHROPIC_API_KEY` | Anthropic | API ключ для Claude моделей |
| `DEEPSEEK_API_KEY` | DeepSeek | API ключ для DeepSeek моделей |
| `GEMINI_API_KEY` | Google | API ключ для Gemini моделей |
| `MISTRAL_API_KEY` | Mistral | API ключ для Mistral моделей |
| `OPENROUTER_API_KEY` | OpenRouter | API ключ для OpenRouter |
| `PERPLEXITY_API_KEY` | Perplexity | API ключ для Perplexity AI |

### Custom API Endpoints

| Переменная | Тип | Default | Описание |
|------------|-----|---------|----------|
| `OPENAI_API_BASE` | string | — | Custom base URL для OpenAI-совместимых API |
| `ANTHROPIC_BASE_URL` | string | `https://api.anthropic.com` | Custom base URL для Anthropic API |

### Google Cloud (VertexAI)

| Переменная | Тип | Описание |
|------------|-----|----------|
| `VERTEXAI_LOCATION` | string | Google Cloud region (например: `us-central1`) |
| `VERTEXAI_PROJECT_ID` | string | Google Cloud project ID |

---

## LLM Configuration

| Переменная | Тип | Default | Описание |
|------------|-----|---------|----------|
| `LLM_PROVIDER` | string | — | **Required.** Провайдер LLM |
| `LLM_MODEL` | string | — | **Required.** Модель LLM |
| `LLM_TEMPERATURE` | float | `0.5` | Температура генерации (0.0-2.0) |
| `MAX_HISTORY_SIZE` | integer | `10` | Максимальное количество сообщений в истории диалога |

---

## Application Settings

| Переменная | Тип | Default | Описание |
|------------|-----|---------|----------|
| `APP_NAME` | string | `Супер Валера` | Название приложения |
| `DEVELOPMENT_WARNING` | boolean | `true` | Показывать предупреждения о development режиме |

---

## Landing Page & Support

| Переменная | Тип | Default | Описание |
|------------|-----|---------|----------|
| `DEMO_BOT_USERNAME` | string | `super_valera_demo_bot` | Username демо-бота для landing page |
| `SUPPORT_TELEGRAM` | string | `super_valera_support` | Username Telegram поддержки |
| `SUPPORT_EMAIL` | string | `danil@brandymint.ru` | Email адрес поддержки |
| `OFFER_URL` | string | Google Doc | URL публичной оферты |
| `REQUISITES_URL` | string | pismenny.ru | URL PDF с реквизитами |

---

## URL & Host Configuration

Используются для генерации URL, subdomain routing и mailers:

| Переменная | Тип | Default | Описание |
|------------|-----|---------|----------|
| `HOST` | string | `localhost` | Хост для URL generation |
| `PORT` | integer | `3000` | Порт для URL generation |
| `PROTOCOL` | string | `http` | Протокол (`http` или `https`) |
| `ALLOWED_HOSTS` | array | `[]` | Разрешённые хосты для subdomain routing |
| `APPLICATION_HOST` | string | `localhost` | Хост для production (config.hosts) |
| `APPLICATION_DOMAIN` | string | `localhost` | Домен для subdomain matching в production |

**Примечание:** `ALLOWED_HOSTS` можно указать через запятую: `lvh.me,localhost,.brandymint.ru`

---

## File Paths

Пути к файлам данных (относительно корня проекта):

| Переменная | Тип | Default | Описание |
|------------|-----|---------|----------|
| `SYSTEM_PROMPT_PATH` | string | `./data/system-prompt.md` | Путь к системному промпту |
| `WELCOME_MESSAGE_PATH` | string | `./data/welcome-message.md` | Путь к приветственному сообщению |
| `PRICE_LIST_PATH` | string | `./data/price.csv` | Путь к прайс-листу |
| `TOOLS_INSTRUCTION_PATH` | string | `./config/tools-instruction.md` | Путь к инструкциям для tools |
| `COMPANY_INFO_PATH` | string | `./data/company-info.md` | Путь к информации о компании |

---

## Rate Limiting

| Переменная | Тип | Default | Описание |
|------------|-----|---------|----------|
| `RATE_LIMIT_REQUESTS` | integer | `10` | Максимум запросов за период |
| `RATE_LIMIT_PERIOD` | integer | `60` | Период в секундах |

---

## Redis Configuration

| Переменная | Тип | Default | Описание |
|------------|-----|---------|----------|
| `REDIS_CACHE_STORE_URL` | string | `redis://localhost:6379/2` | URL для Redis (session store для Telegram) |

---

## Database Configuration

| Переменная | Тип | Default | Описание |
|------------|-----|---------|----------|
| `DATABASE_URL` | string | — | Полный URL подключения к БД (переопределяет все остальные) |
| `VALERA_DATABASE_HOST` | string | — | Хост PostgreSQL |
| `VALERA_DATABASE_PASSWORD` | string | — | Пароль PostgreSQL (production) |
| `RAILS_MAX_THREADS` | integer | `5` | Максимум потоков / размер connection pool |

---

## Rails Configuration

| Переменная | Тип | Default | Описание |
|------------|-----|---------|----------|
| `RAILS_ENV` | string | `development` | Окружение: `development`, `test`, `production` |
| `RAILS_LOG_LEVEL` | string | `info` | Уровень логирования: `debug`, `info`, `warn`, `error` |
| `SECRET_KEY_BASE` | string | — | Секретный ключ Rails (production) |
| `RAILS_MASTER_KEY` | string | — | Мастер-ключ для credentials |
| `TIMEZONE` | string | `Europe/Moscow` | Временная зона приложения |

---

## Analytics

| Переменная | Тип | Default | Описание |
|------------|-----|---------|----------|
| `ANALYTICS_ENABLED` | boolean | `true` | Включить аналитику |
| `FORCE_ANALYTICS` | boolean | — | Принудительно включить аналитику (для тестов) |

---

## Topic Classification (LLM)

Конфигурация автоматической классификации тем чатов с помощью LLM.

| Переменная | Тип | Default | Описание |
|------------|-----|---------|----------|
| `TOPIC_CLASSIFIER_ENABLED` | boolean | `false` | Включить классификацию топиков чатов |
| `TOPIC_CLASSIFIER_MODEL` | string | — | Модель LLM для классификации (если не указана, используется `LLM_MODEL`) |
| `TOPIC_CLASSIFIER_INACTIVITY_HOURS` | integer | `24` | Часы неактивности до автоклассификации чата |

**Примечание:** Классификация отключена по умолчанию. Для включения установите `TOPIC_CLASSIFIER_ENABLED=true`.

**Использование в коде:**
```ruby
TopicClassifierConfig.enabled           # => false (по умолчанию)
TopicClassifierConfig.model_with_fallback # => LLM_MODEL если не задан TOPIC_CLASSIFIER_MODEL
TopicClassifierConfig.inactivity_hours  # => 24
```

---

## Puma Web Server

| Переменная | Тип | Default | Описание |
|------------|-----|---------|----------|
| `PORT` | integer | `3000` | Порт Puma сервера |
| `WEB_CONCURRENCY` | integer | `auto` | Количество worker процессов |
| `RAILS_MAX_THREADS` | integer | `3` | Максимум потоков на worker |
| `PIDFILE` | string | — | Путь к PID файлу |
| `SOLID_QUEUE_IN_PUMA` | boolean | — | Запускать Solid Queue внутри Puma |

---

## Error Tracking (Bugsnag)

| Переменная | Тип | Default | Описание |
|------------|-----|---------|----------|
| `BUGSNAG_API_KEY` | string | — | API ключ Bugsnag для error tracking |

Bugsnag автоматически считывает `BUGSNAG_API_KEY` из окружения. Уведомления отправляются только в `production` и `staging` окружениях.

---

## Development Only

| Переменная | Тип | Default | Описание |
|------------|-----|---------|----------|
| `WEB_CONSOLE_PERMISSIONS` | array | `[]` | IP адреса/сети для Web Console (например: `192.168.0.0/16`) |
| `CI` | boolean | — | Признак CI окружения (включает eager_load в тестах) |

---

## Example Configuration

### Minimal (Development)

```bash
export LLM_PROVIDER="deepseek"
export LLM_MODEL="deepseek-chat"
export DEEPSEEK_API_KEY="sk-xxx"
```

### Production

```bash
# Required
export LLM_PROVIDER="anthropic"
export LLM_MODEL="claude-sonnet-4-20250514"
export ANTHROPIC_API_KEY="sk-ant-xxx"

# Auth Bot
export AUTH_BOT_TOKEN="123456789:ABCdefGHIjklMNOpqrsTUVwxyz"
export AUTH_BOT_USERNAME="my_auth_bot"

# Database
export VALERA_DATABASE_HOST="db.example.com"
export VALERA_DATABASE_PASSWORD="secure_password"
# Или используйте DATABASE_URL
export DATABASE_URL="postgres://valera:password@db.example.com:5432/valera_production"

# Rails
export RAILS_ENV="production"
export SECRET_KEY_BASE="your-secret-key-base"
export RAILS_MASTER_KEY="your-master-key"

# Host configuration
export HOST="myapp.example.com"
export PORT="443"
export PROTOCOL="https"
export APPLICATION_HOST="myapp.example.com"
export APPLICATION_DOMAIN="example.com"

# Error Tracking
export BUGSNAG_API_KEY="your-bugsnag-api-key"

# Redis
export REDIS_CACHE_STORE_URL="redis://redis.example.com:6379/2"

# Performance
export WEB_CONCURRENCY="2"
export RAILS_MAX_THREADS="5"
```

---

## Configuration via YAML

Альтернативно можно использовать `config/application.yml`:

```yaml
# config/application.yml
default: &default
  allowed_hosts: []
  web_console_permissions: []

development:
  <<: *default
  llm_provider: 'openai'
  llm_model: 'gpt-4o-mini'
  host: 'lvh.me'
  port: 3000
  protocol: 'http'
  allowed_hosts:
    - '.lvh.me'
    - 'localhost'

production:
  <<: *default
  # В production используйте ENV переменные!
```

---

## Type Coercion

Anyway Config автоматически преобразует типы:

| Ruby Type | ENV Value Example |
|-----------|-------------------|
| `:string` | `"value"` |
| `:integer` | `"42"` → `42` |
| `:float` | `"0.5"` → `0.5` |
| `:boolean` | `"true"`, `"1"`, `"yes"` → `true` |
| `:array` | `"a,b,c"` → `["a", "b", "c"]` |

---

## Accessing Configuration

В коде используйте `ApplicationConfig`:

```ruby
# Singleton access
ApplicationConfig.llm_provider
ApplicationConfig.llm_model
ApplicationConfig.auth_bot_token

# Computed values
ApplicationConfig.system_prompt       # читает файл
ApplicationConfig.default_url_options # {host:, protocol:, port:}
ApplicationConfig.tld_length          # для subdomain routing
```

---

## Environment Summary Table

### Critical (Production Required)

| Переменная | Источник | Обязательна |
|------------|----------|-------------|
| `LLM_PROVIDER` | ApplicationConfig | Да |
| `LLM_MODEL` | ApplicationConfig | Да |
| `AUTH_BOT_TOKEN` | ApplicationConfig | Для Telegram |
| `SECRET_KEY_BASE` | Rails | Production |
| `VALERA_DATABASE_PASSWORD` | database.yml | Production |

### Infrastructure

| Переменная | Источник | Описание |
|------------|----------|----------|
| `DATABASE_URL` | Rails | Полный URL БД |
| `REDIS_CACHE_STORE_URL` | ApplicationConfig | Redis для sessions |
| `BUGSNAG_API_KEY` | Bugsnag gem | Error tracking |

### Performance Tuning

| Переменная | Источник | Влияние |
|------------|----------|---------|
| `WEB_CONCURRENCY` | puma.rb | Worker processes |
| `RAILS_MAX_THREADS` | puma.rb + database.yml | Threads + DB pool |

---

## Gem-Specific Environment Variables

Дополнительные переменные окружения, которые читаются напрямую используемыми gems.

### PostgreSQL (pg gem)

Libpq environment variables — используются если не указаны явно в `database.yml`:

| Переменная | Описание |
|------------|----------|
| `PGHOST` | Хост PostgreSQL |
| `PGPORT` | Порт (default: 5432) |
| `PGDATABASE` | Имя базы данных |
| `PGUSER` | Имя пользователя |
| `PGPASSWORD` | Пароль (не рекомендуется, используйте `.pgpass`) |
| `PGSSLMODE` | Режим SSL: `disable`, `require`, `verify-ca`, `verify-full` |

### Redis (redis gem)

| Переменная | Default | Описание |
|------------|---------|----------|
| `REDIS_URL` | — | URL подключения (автоматически используется gem) |
| `REDIS_TIMEOUT` | `1` | Таймаут подключения в секундах |
| `REDIS_RECONNECT_ATTEMPTS` | `3` | Количество попыток переподключения |

### Thruster (HTTP proxy)

Все переменные можно использовать с префиксом `THRUSTER_`:

| Переменная | Default | Описание |
|------------|---------|----------|
| `TLS_DOMAIN` | — | Домены для TLS (comma-separated) |
| `HTTP_PORT` | `80` | Порт для HTTP |
| `HTTPS_PORT` | `443` | Порт для HTTPS |
| `TARGET_PORT` | — | Порт Puma (куда проксировать) |
| `ACME_DIRECTORY` | Let's Encrypt | URL ACME для сертификатов |
| `STORAGE_PATH` | — | Путь для хранения сертификатов |
| `BAD_GATEWAY_PAGE` | — | HTML страница для 502 ошибки |
| `IDLE_TIMEOUT` | — | Таймаут idle соединения |
| `READ_TIMEOUT` | — | Таймаут чтения запроса |
| `WRITE_TIMEOUT` | — | Таймаут записи ответа |

### Bugsnag (расширенные)

| Переменная | Описание |
|------------|----------|
| `BUGSNAG_API_KEY` | API ключ (основной) |
| `BUGSNAG_RELEASE_STAGE` | Стадия релиза (`production`, `staging`) |
| `BUGSNAG_APP_VERSION` | Версия приложения |
| `BUGSNAG_DISABLE_AUTOCONFIGURE` | Отключить автоконфигурацию |
| `BUGSNAG_ENABLED_RELEASE_STAGES` | Разрешённые стадии (comma-separated) |

### Solid Queue

| Переменная | Default | Описание |
|------------|---------|----------|
| `SOLID_QUEUE_CONFIG` | `config/queue.yml` | Путь к конфигурации |
| `SOLID_QUEUE_SKIP_RECURRING` | `false` | Пропустить recurring tasks |
| `SOLID_QUEUE_IN_PUMA` | `false` | Запускать внутри Puma |
| `JOB_CONCURRENCY` | `1` | Количество worker процессов |

### Bootsnap

| Переменная | Default | Описание |
|------------|---------|----------|
| `BOOTSNAP_CACHE_DIR` | `tmp/cache` | Директория кеша |
| `BOOTSNAP_LOG` | — | Логировать cache misses в STDERR |
| `BOOTSNAP_STATS` | — | Статистика hit rate при выходе |
| `BOOTSNAP_IGNORE_DIRECTORIES` | `node_modules` | Игнорируемые директории |

### RubyLLM (debug)

| Переменная | Описание |
|------------|----------|
| `RUBYLLM_DEBUG` | Включить debug logging (`true`) |
| `RUBY_LLM_DEBUG` | Альтернатива для debug tool calls |

### Selenium/Capybara (testing)

| Переменная | Описание |
|------------|----------|
| `SELENIUM_HOST` | Хост Selenium server |
| `SELENIUM_REMOTE_HOST` | Remote Selenium host (Docker) |
| `SELENIUM_REMOTE_PORT` | Remote Selenium port |
| `WD_INSTALL_DIR` | Директория для webdrivers |
| `WD_CHROME_PATH` | Путь к Chrome binary |
| `CAPYBARA_JAVASCRIPT_DRIVER` | JS драйвер (`:chrome_headless`) |
| `APP_HOST` | Хост приложения для тестов |

### Image Processing (libvips)

| Переменная | Описание |
|------------|----------|
| `VIPS_WARNING` | Отключить warnings |
| `VIPS_INFO` | Включить info output |
| `PKG_CONFIG_PATH` | Путь к pkg-config (для сборки) |

### macOS Specific

| Переменная | Описание |
|------------|----------|
| `OBJC_DISABLE_INITIALIZE_FORK_SAFETY` | `YES` — для Solid Queue и ruby-vips |

### Telegram Bot

| Переменная | Описание |
|------------|----------|
| `BOT_POLLER_MODE` | `true` — режим polling (для daemons) |
| `TELEGRAM_BOT_POOL_SIZE` | Размер connection pool (default: 1) |
| `CERT` | Путь к SSL сертификату для webhook |

---

## Complete Environment Variables Checklist

### Production Deployment Checklist

```bash
# === CRITICAL (Required) ===
LLM_PROVIDER=anthropic
LLM_MODEL=claude-sonnet-4-20250514
ANTHROPIC_API_KEY=sk-ant-xxx
SECRET_KEY_BASE=xxx
RAILS_MASTER_KEY=xxx

# === Telegram ===
AUTH_BOT_TOKEN=123456789:ABCxxx
AUTH_BOT_USERNAME=my_bot

# === Database ===
DATABASE_URL=postgres://user:pass@host:5432/valera_production
# или
VALERA_DATABASE_HOST=db.example.com
VALERA_DATABASE_PASSWORD=xxx

# === Redis ===
REDIS_URL=redis://redis:6379/0
REDIS_CACHE_STORE_URL=redis://redis:6379/2

# === Hosts ===
HOST=app.example.com
PORT=443
PROTOCOL=https
APPLICATION_HOST=app.example.com
APPLICATION_DOMAIN=example.com

# === Error Tracking ===
BUGSNAG_API_KEY=xxx
BUGSNAG_RELEASE_STAGE=production

# === Performance ===
WEB_CONCURRENCY=2
RAILS_MAX_THREADS=5

# === Optional ===
RAILS_LOG_LEVEL=info
TIMEZONE=Europe/Moscow
ANALYTICS_ENABLED=true
```

---

## Related Documentation

- [Development Guide](development/README.md)
- [Deployment Guide](deployment/README.md)
- [Error Handling](patterns/error-handling.md)
- [Puma Configuration](https://github.com/puma/puma)
- [Thruster Configuration](https://github.com/basecamp/thruster)
- [Bugsnag Ruby Docs](https://docs.bugsnag.com/platforms/ruby/rails/configuration-options/)

---

**Документ создан:** 2025-12-19
**Обновлён:** 2025-12-28
**Ответственный:** Development Team
