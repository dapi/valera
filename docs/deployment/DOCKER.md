# 🐳 Docker Deployment Guide

**Обновлено:** 2025-10-27

---

## 📋 Содержание

- [Quick Start](#quick-start)
- [Dockerfile](#dockerfile)
- [Docker Compose](#docker-compose)
- [Production](#production)
- [Troubleshooting](#troubleshooting)

---

## 🚀 Quick Start

```bash
# Запуск в development
docker-compose up

# Запуск в production
docker-compose -f docker-compose.prod.yml up -d

# Остановка
docker-compose down
```

---

## 📦 Dockerfile

### Production optimized Dockerfile
```dockerfile
# Multi-stage build
FROM ruby:3.4.2-slim as builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install gems
COPY Gemfile Gemfile.lock ./
RUN bundle config set --local deployment 'true'
RUN bundle config set --local without 'development test'
RUN bundle install

# Copy application code
COPY . .

# Precompile assets
RUN SECRET_KEY_BASE=dummy rails assets:precompile

# Production stage
FROM ruby:3.4.2-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    libpq5 \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy precompiled assets and gems
COPY --from=builder /app .

# Create non-root user
RUN groupadd -r appuser && useradd -r -g appuser appuser
RUN chown -R appuser:appuser /app
USER appuser

EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/up || exit 1

CMD ["rails", "server", "-b", "0.0.0.0"]
```

---

## 🔧 Docker Compose Files

### Development (docker-compose.yml)
```yaml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "3000:3000"
    volumes:
      - .:/app
      - gems:/usr/local/bundle
    environment:
      - RAILS_ENV=development
      - DATABASE_URL=postgresql://postgres:password@db:5432/valera_dev
    depends_on:
      - db
      - redis
    command: bundle exec rails server -b 0.0.0.0

  db:
    image: postgres:14
    environment:
      - POSTGRES_DB=valera_dev
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=password
    volumes:
      - postgres_dev:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

  sidekiq:
    build: .
    volumes:
      - .:/app
      - gems:/usr/local/bundle
    environment:
      - RAILS_ENV=development
      - DATABASE_URL=postgresql://postgres:password@db:5432/valera_dev
    depends_on:
      - db
      - redis
    command: bundle exec sidekiq

volumes:
  postgres_dev:
  gems:
```

### Production (docker-compose.prod.yml)
```yaml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "3000:3000"
    environment:
      - RAILS_ENV=production
      - DATABASE_URL=postgresql://postgres:${POSTGRES_PASSWORD}@db:5432/valera
      - REDIS_URL=redis://redis:6379/0
      - SECRET_KEY_BASE=${SECRET_KEY_BASE}
    depends_on:
      - db
      - redis
    restart: unless-stopped

  db:
    image: postgres:14
    environment:
      - POSTGRES_DB=valera
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
    volumes:
      - postgres_prod:/var/lib/postgresql/data
    restart: unless-stopped

  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data
    restart: unless-stopped

  sidekiq:
    build: .
    environment:
      - RAILS_ENV=production
      - DATABASE_URL=postgresql://postgres:${POSTGRES_PASSWORD}@db:5432/valera
      - REDIS_URL=redis://redis:6379/0
    depends_on:
      - db
      - redis
    restart: unless-stopped
    command: bundle exec sidekiq

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/ssl/certs
    depends_on:
      - app
    restart: unless-stopped

volumes:
  postgres_prod:
  redis_data:
```

---

## 🌐 Production Deployment

### 1. Environment variables
```bash
# .env.production
POSTGRES_PASSWORD=your_secure_password
SECRET_KEY_BASE=your_secret_key_base
TELEGRAM_BOT_TOKEN=your_bot_token
OPENAI_API_KEY=your_openai_key
```

### 2. SSL/TLS с Nginx
```nginx
# nginx.conf
events {
    worker_connections 1024;
}

http {
    upstream app {
        server app:3000;
    }

    server {
        listen 80;
        server_name your-domain.com;
        return 301 https://$server_name$request_uri;
    }

    server {
        listen 443 ssl http2;
        server_name your-domain.com;

        ssl_certificate /etc/ssl/certs/cert.pem;
        ssl_certificate_key /etc/ssl/certs/key.pem;

        location / {
            proxy_pass http://app;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
}
```

### 3. Запуск в production
```bash
# Создать .env файл
cp .env.example .env.production

# Запустить
docker-compose -f docker-compose.prod.yml up -d

# Миграции
docker-compose -f docker-compose.prod.yml exec app rails db:migrate

# Assets precompile
docker-compose -f docker-compose.prod.yml exec app rails assets:precompile
```

---

## 🔍 Monitoring and Logs

### Logs
```bash
# Все сервисы
docker-compose logs -f

# Конкретный сервис
docker-compose logs -f app
docker-compose logs -f db
docker-compose logs -f sidekiq
```

### Health checks
```bash
# Check health
curl http://localhost:3000/up

# Docker health
docker-compose ps
```

---

## 🐛 Troubleshooting

### Common issues

#### 1. Database connection
```bash
# Check database connection
docker-compose exec app rails db:migrate:status

# Reset database
docker-compose down -v
docker-compose up -d db
docker-compose exec app rails db:create db:migrate
```

#### 2. Assets not loading
```bash
# Precompile assets
docker-compose exec app rails assets:precompile

# Clear cache
docker-compose exec app rails tmp:clear
```

#### 3. Sidekiq not working
```bash
# Check sidekiq
docker-compose exec sidekiq bundle exec sidekiq-web

# Restart sidekiq
docker-compose restart sidekiq
```

### Performance tuning
```yaml
# In docker-compose.prod.yml
app:
  deploy:
    resources:
      limits:
        memory: 512M
      reservations:
        memory: 256M
```

---

## 🔄 CI/CD Integration

### GitHub Actions example
```yaml
# .github/workflows/docker.yml
name: Docker

on:
  push:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - name: Build and test
      run: |
        docker-compose build
        docker-compose run app rails test

  deploy:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
    - uses: actions/checkout@v3
    - name: Deploy to production
      run: |
        docker-compose -f docker-compose.prod.yml pull
        docker-compose -f docker-compose.prod.yml up -d
```

---

**📝 Документ создан:** 27.01.2025
**🔄 Обновлен:** 27.01.2025
**👤 Ответственный:** DevOps Team