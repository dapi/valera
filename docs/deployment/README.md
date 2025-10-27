# 🚀 Deployment Guide

**Обновлено:** 2025-10-27
**Проект:** Valera - AI-powered чат-бот для автоматизации автосервиса
**Технологии:** Ruby on Rails 8.1, ruby_llm, telegram-bot

---

## 📋 Содержание

- [Требования](#требования)
- [Локальная разработка](#локальная-разработка)
- [Продакшн развертывание](#продакшн-развертывание)
- [Конфигурация](#конфигурация)
- [Мониторинг](#мониторинг)

---

## 🔧 Требования

### Системные требования
- **Ruby:** 3.4.2+
- **Rails:** 8.1
- **Database:** PostgreSQL 14+
- **Redis:** 6+ (для sidekiq)
- **Node.js:** 18+ (для assets)

### Гемы и зависимости
Основные зависимости описаны в [docs/gems/README.md](../gems/README.md)

---

## 💻 Локальная разработка

### 1. Клонирование и настройка
```bash
git clone <repository-url>
cd valera
bundle install
```

### 2. Конфигурация
Проект использует `anyway_config` вместо `.env` файлов:

```ruby
# config/configs/application_config.rb
class ApplicationConfig < Anyway::Config
  config_name :application

  # Telegram Bot
  attr_config telegram_bot_token: nil
  attr_config telegram_webhook_url: nil

  # AI/LLM
  attr_config openai_api_key: nil
  attr_config anthropic_api_key: nil

  # Database
  attr_config database_url: nil

  # Другие настройки...
end
```

### 3. База данных
```bash
rails db:create
rails db:migrate
rails db:seed
```

### 4. Запуск
```bash
# Сервер
rails server

# Sidekiq (для фоновых задач)
bundle exec sidekiq

# Telegram бот webhook
rails telegram_bot:webhook:set
```

---

## 🌐 Продакшн развертывание

### Docker развертывание

#### 1. Dockerfile
```dockerfile
FROM ruby:3.4.2-slim

# Установка зависимостей
RUN apt-get update && apt-get install -y \
    postgresql-client \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile ./
COPY Gemfile.lock ./
RUN bundle install --without development test

COPY . .

# Assets precompilation
RUN SECRET_KEY_BASE=dummy rails assets:precompile

EXPOSE 3000
CMD ["rails", "server", "-b", "0.0.0.0"]
```

#### 2. docker-compose.yml
```yaml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "3000:3000"
    environment:
      - RAILS_ENV=production
      - DATABASE_URL=postgresql://user:pass@db:5432/valera
    depends_on:
      - db
      - redis

  db:
    image: postgres:14
    environment:
      - POSTGRES_DB=valera
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=pass
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine

  sidekiq:
    build: .
    command: bundle exec sidekiq
    environment:
      - RAILS_ENV=production
      - DATABASE_URL=postgresql://user:pass@db:5432/valera
    depends_on:
      - db
      - redis

volumes:
  postgres_data:
```

### Heroku развертывание

#### 1. Подготовка
```bash
# Добавить PostgreSQL
heroku addons:create heroku-postgresql:hobby-dev

# Добавить Redis для Sidekiq
heroku addons:create heroku-redis:hobby-dev

# Настроить переменные окружения
heroku config:set \
  TELEGRAM_BOT_TOKEN=your_token \
  OPENAI_API_KEY=your_key \
  RAILS_ENV=production
```

#### 2. Развертывание
```bash
git push heroku main

# Миграции базы данных
heroku run rails db:migrate

# Precompile assets
heroku run rails assets:precompile

# Настроить webhook
heroku run rails telegram_bot:webhook:set
```

---

## ⚙️ Конфигурация

### Конфигурационные файлы

**Основная конфигурация:** `config/configs/application_config.rb`

**Окружения:**
- `config/environments/development.rb`
- `config/environments/production.rb`
- `config/environments/test.rb`

### Переменные окружения

```bash
# Telegram Bot
TELEGRAM_BOT_TOKEN=your_bot_token
TELEGRAM_WEBHOOK_URL=https://your-domain.com/telegram/webhook

# AI/LLM
OPENAI_API_KEY=your_openai_key
ANTHROPIC_API_KEY=your_anthropic_key

# Database
DATABASE_URL=postgresql://user:pass@host:5432/dbname

# Redis
REDIS_URL=redis://host:6379/0

# Rails
SECRET_KEY_BASE=your_secret_key
RAILS_ENV=production
```

---

## 📊 Мониторинг

### Health checks
```bash
# Базовый health check
GET /up

# Детальная информация
GET /health
```

### Логирование
Проект использует `ErrorLogger` для обработки ошибок:

```ruby
include ErrorLogger

begin
  # код
rescue => e
  log_error(e, { user_id: user.id, action: "process_booking" })
end
```

### Метрики
- **Аналитика:** `AnalyticsEvent` модель
- **Производительность:** Rails logging
- **Ошибки:** ErrorLogger система

---

## 🔒 Безопасность

### Ключевые моменты
- Использование `anyway_config` вместо `.env` файлов
- Валидация входных данных
- Безопасная обработка файлов
- Регулярные обновления зависимостей

### Рекомендации
1. Регулярно обновлять гемы
2. Использовать HTTPS в продакшене
3. Ограничить доступ к API ключам
4. Настроить бэкапы базы данных

---

## 🚀 Оптимизация

### Производительность
- **Assets:** Rails assets pipeline
- **Кэширование:** Redis caching
- **База данных:** Индексы и оптимизация запросов
- **Фоновые задачи:** Sidekiq

### Масштабирование
- **Horizontal:** Несколько экземпляров приложения
- **Database:** Read replicas
- **CDN:** Для статических assets

---

## 📝 Дополнительные ресурсы

- [Development Guide](../development/README.md)
- [Architecture Decisions](../architecture/decisions.md)
- [Gems Documentation](../gems/README.md)
- [Product Constitution](../product/constitution.md)

---

**📝 Документ создан:** 27.01.2025
**🔄 Обновлен:** 27.01.2025
**👤 Ответственный:** DevOps Team