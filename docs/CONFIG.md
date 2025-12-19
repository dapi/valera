# Configuration Guide

**Обновлено:** 2025-12-19

Руководство по настройке переменных окружения для приложения Valera.

---

## Overview

Проект использует [anyway_config](https://github.com/palkan/anyway_config) для управления конфигурацией. Конфигурация определена в `config/configs/application_config.rb` с пустым префиксом (`env_prefix ''`), что означает прямое использование имён переменных окружения.

**Преобразование имён:** `snake_case` атрибуты → `SCREAMING_SNAKE_CASE` переменные окружения.

---

## Required Variables

Эти переменные **обязательны** для запуска приложения:

| Переменная | Тип | Описание |
|------------|-----|----------|
| `BOT_TOKEN` | string | Telegram Bot API token (получить у @BotFather) |
| `LLM_PROVIDER` | string | Провайдер LLM: `openai`, `anthropic`, `deepseek`, `gemini`, `mistral`, `openrouter`, `perplexity` |
| `LLM_MODEL` | string | Модель LLM (например: `gpt-4o`, `claude-sonnet-4-20250514`, `deepseek-chat`) |

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

| Переменная | Тип | Описание |
|------------|-----|----------|
| `OPENAI_API_BASE` | string | Custom base URL для OpenAI-совместимых API |
| `ANTHROPIC_BASE_URL` | string | Custom base URL для Anthropic API (default: `https://api.anthropic.com`) |

### Google Cloud (VertexAI)

| Переменная | Тип | Описание |
|------------|-----|----------|
| `VERTEXAI_LOCATION` | string | Google Cloud region (например: `us-central1`) |
| `VERTEXAI_PROJECT_ID` | string | Google Cloud project ID |

---

## Telegram Configuration

| Переменная | Тип | Default | Описание |
|------------|-----|---------|----------|
| `BOT_TOKEN` | string | — | **Required.** Telegram Bot API token |
| `ADMIN_CHAT_ID` | integer | — | ID чата для отправки уведомлений о заявках |
| `WEBHOOK_PORT` | integer | — | Порт для webhook сервера (если используется) |

---

## LLM Configuration

| Переменная | Тип | Default | Описание |
|------------|-----|---------|----------|
| `LLM_PROVIDER` | string | — | **Required.** Провайдер LLM |
| `LLM_MODEL` | string | — | **Required.** Модель LLM |
| `LLM_TEMPERATURE` | float | `0.5` | Температура генерации (0.0-2.0) |
| `MAX_HISTORY_SIZE` | integer | `10` | Максимальное количество сообщений в истории диалога |

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
| `REDIS_CACHE_STORE_URL` | string | `redis://localhost:6379/2` | URL для Redis (session store) |

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

---

## Puma Web Server

| Переменная | Тип | Default | Описание |
|------------|-----|---------|----------|
| `WEB_CONCURRENCY` | integer | — | Количество worker процессов |
| `RAILS_MAX_THREADS` | integer | `5` | Максимум потоков на worker |
| `PIDFILE` | string | — | Путь к PID файлу |
| `SOLID_QUEUE_IN_PUMA` | boolean | — | Запускать Solid Queue внутри Puma |

---

## Error Tracking (Bugsnag)

| Переменная | Тип | Default | Описание |
|------------|-----|---------|----------|
| `BUGSNAG_API_KEY` | string | — | API ключ Bugsnag для error tracking |

Bugsnag автоматически считывает `BUGSNAG_API_KEY` из окружения. Уведомления отправляются только в `production` и `staging` окружениях.

---

## Development

| Переменная | Тип | Default | Описание |
|------------|-----|---------|----------|
| `DEVELOPMENT_WARNING` | boolean | `true` | Показывать предупреждения о development режиме |
| `CI` | boolean | — | Признак CI окружения (включает eager_load в тестах) |

---

## Example Configuration

### Minimal (Development)

```bash
export BOT_TOKEN="123456789:ABCdefGHIjklMNOpqrsTUVwxyz"
export LLM_PROVIDER="deepseek"
export LLM_MODEL="deepseek-chat"
export DEEPSEEK_API_KEY="sk-xxx"
```

### Production

```bash
# Required
export BOT_TOKEN="123456789:ABCdefGHIjklMNOpqrsTUVwxyz"
export LLM_PROVIDER="anthropic"
export LLM_MODEL="claude-sonnet-4-20250514"
export ANTHROPIC_API_KEY="sk-ant-xxx"

# Database
export VALERA_DATABASE_HOST="db.example.com"
export VALERA_DATABASE_PASSWORD="secure_password"

# Or use DATABASE_URL
export DATABASE_URL="postgres://valera:password@db.example.com:5432/valera_production"

# Rails
export RAILS_ENV="production"
export SECRET_KEY_BASE="your-secret-key-base"
export RAILS_MASTER_KEY="your-master-key"

# Telegram
export ADMIN_CHAT_ID="123456789"

# Error Tracking
export BUGSNAG_API_KEY="your-bugsnag-api-key"

# Redis
export REDIS_CACHE_STORE_URL="redis://redis.example.com:6379/2"

# Performance
export WEB_CONCURRENCY="2"
export RAILS_MAX_THREADS="5"
```

---

## Configuration Loading Order

Anyway Config загружает конфигурацию в следующем порядке (последующие переопределяют предыдущие):

1. **Defaults** — значения по умолчанию в `attr_config`
2. **YAML files** — `config/application.yml` (если существует)
3. **Environment variables** — переменные окружения

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
ApplicationConfig.bot_token
ApplicationConfig.llm_provider
ApplicationConfig.admin_chat_id

# Computed values
ApplicationConfig.system_prompt      # читает файл
ApplicationConfig.bot_id             # извлекает ID из токена
```

---

## Related Documentation

- [Development Guide](development/README.md)
- [Deployment Guide](deployment/README.md)
- [Error Handling](patterns/error-handling.md)

---

**Документ создан:** 2025-12-19
**Ответственный:** Development Team
