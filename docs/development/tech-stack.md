# 🛠️ Технологический стек Valera

**Создан:** 28.10.2025
**Версия:** 1.0
**Статус:** Active Technical Specification

## 📋 Обзор

Valera построен на современном стеке технологий для Ruby on Rails приложений с акцентом на AI, безопасность и масштабируемость.

### 🎯 Ключевые принципы выбора стека:
- **Ruby/Rails экосистема:** максимальная производительность разработки
- **AI-first:** встроенная поддержка LLM интеграций
- **Telegram-native:** optimized для Telegram Bot API
- **SaaS-ready:** multi-tenancy и scalability из коробки
- **Modern practices:** Rails 8.1 + PostgreSQL + Solid Queue

---

## 🏗️ Core Stack

### **Backend Framework**
- **Ruby on Rails 8.1.0** - фреймворк приложения
- **Ruby 3.4.2** - язык программирования
- **PostgreSQL 16+** - основная база данных
- **Redis 7+** - кэширование и очереди

### **AI & Machine Learning**
- **ruby_llm gem** - интеграция с LLM провайдерами
- **OpenAI API** - основная AI модель
- **Claude API** - альтернативная AI модель
- **Gemini API** - дополнительная AI модель

### **Telegram Integration**
- **telegram-bot gem** - Telegram Bot API
- **Telegram Login Widget** - авторизация через Telegram
- **Webhook-based** - real-time обработка сообщений

### **Queue & Background Jobs**
- **Solid Queue** - background job processing (Rails 8 default)
- **Async operations** - AI ответов, уведомлений
- **Job prioritization** - critical vs batch operations

---

## 💎 Key Gems Dependencies

### **AI & LLM**
```ruby
gem 'ruby_llm', '~> 1.8'          # AI интеграции
gem 'openai', '~> 7.0'            # OpenAI API клиент
gem 'anthropic', '~> 0.25'        # Claude API клиент
```

### **Telegram & Communication**
```ruby
gem 'telegram-bot', '~> 0.16'    # Telegram Bot API
gem 'httparty', '~> 0.22'         # HTTP клиент для webhook
```

### **Database & ORM**
```ruby
gem 'pg', '~> 1.5'                # PostgreSQL адаптер
gem 'activerecord', '~> 8.1'     # Rails ORM
gem 'acts_as_chat', '~> 1.0'      # Chat functionality (custom)
```

### **Background Jobs**
```ruby
gem 'solid_queue', '~> 2.0'      # Queue processing (Rails 8)
gem 'solid_cable', '~> 2.0'      # ActionCable backend
```

### **Configuration**
```ruby
gem 'anyway_config', '~> 2.4'    # Configuration management
gem 'dotenv-rails', '~> 3.0'     # Environment variables
```

### **Development & Testing**
```ruby
gem 'rspec-rails', '~> 7.0'      # Testing framework
gem 'factory_bot_rails', '~> 7.0' # Test factories
gem 'vcr', '~> 6.2'              # HTTP recording/testing
gem 'yard', '~> 0.9'              # Documentation generation
```

---

## 🏛️ Architecture Components

### **Multi-Tenancy Support**
- **Account-based isolation** - данные клиентов изолированы
- **Single database** - эффективная масштабируемость
- **Dynamic bot instances** - отдельные боты для каждого клиента
- **Membership system** - управление командами

### **AI Integration Layer**
- **ruby_llm abstraction** - единый интерфейс для разных AI провайдеров
- **Prompt management** - системные промпты для каждого клиента
- **Tool calling** - AI функциональность (запись, анализ фото)
- **Conversation memory** - контекст диалогов

### **Telegram Bot Engine**
- **Webhook processing** - real-time обработка сообщений
- **Multi-bot support** - управление ботами для разных клиентов
- **Rich message formatting** - Markdown, HTML, медиа
- **Authentication** - Telegram Login Widget integration

### **Analytics & Monitoring**
- **Custom analytics** - event tracking (FIP-001)
- **Conversation metrics** - диалоги, конверсии
- **Business KPIs** - MRR, churn, LTV для SaaS
- **Performance monitoring** - AI response times, system health

---

## 🗄️ Database Schema

### **Core Models**
```ruby
# Account - Клиент автосервиса (SaaS)
Account
  ├─ name: string
  ├─ bot_token: string
  ├─ system_prompt: text
  ├─ subscription_tier: string
  └─ settings: jsonb

# Chat - Диалог с клиентом
Chat
  ├─ account: references
  ├─ telegram_user: references
  ├─ status: string
  └─ metadata: jsonb

# Message - Сообщения в диалоге
Message
  ├─ chat: references
  ├─ role: string (user/assistant/system)
  ├─ content: text
  ├─ attachments: jsonb
  └─ llm_response_data: jsonb

# TelegramUser - Пользователь Telegram
TelegramUser
  ├─ telegram_id: integer (unique)
  ├─ username: string
  ├─ first_name: string
  └─ last_name: string

# Booking - Заявка на услугу
Booking
  ├─ chat: references
  ├─ status: string
  ├─ service_type: string
  ├─ description: text
  ├─ photos: jsonb
  └─ scheduled_at: datetime
```

### **SaaS Models**
```ruby
# Membership - Команда автосервиса
Membership
  ├─ account: references
  ├─ telegram_user: references
  ├─ role: string (admin/support)
  └─ created_at: datetime

# AnalyticsEvent - События аналитики
AnalyticsEvent
  ├─ account: references
  ├─ event_type: string
  ├─ properties: jsonb
  └─ created_at: datetime
```

---

## 🚀 Deployment Architecture

### **Production Infrastructure**
- **Single-instance deployment** (初期)
- **PostgreSQL database** - Primary + replicas по мере роста
- **Redis cluster** - Кэширование и очереди
- **Solid Queue workers** - Background processing
- **Puma web server** - Rails application server

### **Scaling Strategy**
```
Year 1 (17 клиентов):
├─ 1 Rails app instance
├─ 1 PostgreSQL database
├─ 1 Redis instance
└─ 1 Solid Queue worker
└─ Стоимость: ~$50/месяц (AWS)

Year 2 (40 клиентов):
├─ 2-3 Rails app instances (load balancer)
├─ 1 PostgreSQL (scaled up)
├─ 1 Redis (scaled up)
└─ 2-3 Solid Queue workers
└─ Стоимость: ~$200/месяц (AWS)

Year 3 (70+ клиентов):
├─ 5+ Rails instances (auto-scaling)
├─ PostgreSQL read replicas
├─ Redis cluster
├─ 5+ Solid Queue workers
└─ CDN for static assets
└─ Стоимость: ~$500/месяц (AWS)
```

---

## 🛡️ Security & Compliance

### **Data Security**
- **Account isolation** - данные клиентов полностью изолированы
- **Telegram OAuth** - безопасная авторизация через Telegram
- **No password storage** - используем Telegram authentication
- **Data encryption** -_sensitive data encrypted at rest

### **API Security**
- **Bot token security** - токены хранятся в зашифрованном виде
- **Webhook verification** - проверка запросов от Telegram
- **Rate limiting** - защита от abuse
- **Input sanitization** - защита от XSS/инъекций

### **AI Security**
- **Prompt injection protection** - фильтрация вредоносных промптов
- **Content filtering** - фильтрация нежелательного контента
- **API key management** - безопасное хранение AI API ключей
- **Request validation** - валидация AI запросов/ответов

---

## 🔧 Development Environment

### **Local Development**
```bash
# Requirements
- Ruby 3.4.2
- PostgreSQL 16+
- Redis 7+
- Node.js 20+ (for assets)

# Setup
$ git clone <repository>
$ cd valera
$ bundle install
$ rails db:setup
$ rails server
```

### **Development Tools**
- **VSCode + Ruby extension** - основная IDE
- **Postico** - PostgreSQL клиент
- **Redis Desktop Manager** - Redis GUI
- **Postman** - API testing
- **Telegram BotFather** - bot management

### **Testing Stack**
- **RSpec** - unit и integration тесты
- **Factory Bot** - тестовые данные
- **VCR** - HTTP interactions recording
- **Database Cleaner** - очистка тестовой БД
- **SimpleCov** - code coverage

---

## 📊 Performance Considerations

### **Response Times Target**
- **Webhook processing:** < 200ms
- **AI response generation:** < 3 секунд
- **Database queries:** < 50ms (95th percentile)
- **Background job processing:** < 1 секунда

### **Scalability Targets**
- **Concurrent users:** 1000+ per instance
- **Messages per minute:** 500+ per instance
- **AI requests per minute:** 100+ per instance
- **Database connections:** 20+ per instance

### **Optimization Strategies**
- **Database indexing** - критичные запросы
- **Redis caching** - AI responses, user sessions
- **Background processing** - AI генерация, уведомления
- **Connection pooling** - эффективное использование БД

---

## 🔗 Integration Points

### **External APIs**
- **OpenAI API** - AI ответы
- **Telegram Bot API** - сообщения и auth
- **Cloud storage** - фото клиентов (будущее)
- **Payment gateway** - подписки SaaS (будущее)

### **Internal Services**
- **ruby_llm** - AI abstraction layer
- **Solid Queue** - async processing
- **ApplicationConfig** - управление настройками
- **ErrorLogger** - централизованный error handling

---

## 📋 Version Requirements

### **Ruby & Rails**
```ruby
ruby '3.4.2'
gem 'rails', '~> 8.1.0'
```

### **Database Requirements**
- **PostgreSQL:** 16+ (JSONB support required)
- **Redis:** 7+ (for Solid Queue)

### **System Dependencies**
- **Bundler:** 2.5+
- **Node.js:** 20+ (for asset compilation)
- **Yarn:** 1.22+ (JavaScript packages)

---

## 🎯 Technology Rationale

### **Why Ruby on Rails 8.1?**
- **Productivity:** Быстрая разработка бизнес-логики
- **Convention over Configuration:** Меньше boilerplate
- **Solid Queue:** Встроенный background job processing
- **Ecosystem:** Огромное количество готовых gem'ов
- **Multi-tenancy:** Поддержка из коробки

### **Why PostgreSQL?**
- **JSONB support:** Идеально для AI metadata
- **Reliability:** Промышленная надежность
- **Scalability:** Горизонтальное масштабирование
- **Features:** Full-text search, extensions

### **Why ruby_llm?**
- **Provider abstraction:** Легкая смена AI провайдеров
- **Tool calling:** Встроенная поддержка функций
- **Streaming responses:** Real-time AI ответы
- **Rails integration:** Нативная интеграция с Rails

### **Why Solid Queue?**
- **Rails native:** Нет external dependencies
- **PostgreSQL backend:** Единственная БД для всего
- **Reliability:** Атомарные операции с БД
- **Performance:** Оптимизирован для Rails

---

## 🚀 Future Technology Additions

### **Phase 2 (Post-MVP)**
- **Elasticsearch** - поиск по диалогам
- **Sidekiq** - альтернатива Solid Queue для high-load
- **Docker containers** - deployment optimization
- **CloudFlare** - CDN и security

### **Phase 3 (Scale)**
- **Kubernetes** - container orchestration
- **Read replicas** - БД масштабирование
- **Microservices** - выделение AI сервиса
- **Event streaming** - Kafka/NATS для real-time

---

**Версия:** 1.0
**Последнее обновление:** 28.10.2025
**Ответственный:** Tech Lead
**Тип документа:** Technical Specification