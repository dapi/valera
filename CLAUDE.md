# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 🚨 КРИТИЧЕСКИ ВАЖНО: Архитектурные принципы

**ПЕРВОЕ ЧТО НУЖНО ПРОЧИТАТЬ:** [Memory Bank](.claude/memory-bank.md)

Содержит **архитектурные решения** и **принципы проекта**:
- [Product Constitution](docs/product/constitution.md) - НЕПРИКОСНОВЕННЫЕ требования
- Критерии качества документации (ОБЯЗАТЕЛЬНЫЕ для всех агентов)
- Ключевые решения AI-архитектуры
- Team structure и зоны ответственности

**ВСЕГДА проверяйте memory-bank.md перед началом ЛЮБОЙ работы!**

## 📋 Правило разделения документации (Zero дублирования)

### **🧠 memory-bank.md = WHY** (Архитектурные решения)
- **ПОЧЕМУ** проект устроен именно так
- История архитектурных решений
- Фундаментальные принципы (Product Constitution)
- Критерии качества документации
- Team structure и зоны ответственности

### **📖 CLAUDE.md = HOW** (Практическая инструкция)
- **КАК** работать с проектом
- Технологический стек и команды
- Практические инструкции по разработке
- Интеграция с инструментами

**🔗 Главное правило:** Если нужно знать ПОЧЕМУ → memory-bank.md, если нужно знать КАК → CLAUDE.md

## 📋 Quick Start (практическая инструкция)

1. **Изучи архитектуру (WHY):** [.claude/memory-bank.md](.claude/memory-bank.md)
2. **Технологический стек (HOW):** Ruby on Rails 8.1 + ruby_llm + PostgreSQL
3. **Основные команды (HOW):** `bin/dev`, `bin/rails test`, `bin/rubocop`
4. **Документация (HOW):** [docs/README.md](docs/README.md)
5. **🚀 Новый flow работы:** [FLOW.md](docs/FLOW.md) - **ОБЯЗАТЕЛЬНО**

> **Подробнее о технологическом стеке и командах разработки** см. ниже в этом документе.

## 🔄 Новый подход к документации (УПРОЩЕННЫЙ)

**Ключевой принцип:** Один документ на функцию (**Feature Implementation Plan**) вместо трех (User Story + Tech Spec + Tech Solution).

### 📋 Создание новой функции
```bash
# Вместо: User Story → Tech Spec → Tech Solution → Implementation
# Теперь: Feature Implementation Plan → Implementation
1. Копировать шаблон: docs/requirements/templates/user-story-hybrid-template.md
2. Создать FIP-XXX-название.md
3. Заполнить все разделы
4. Сразу начинать реализацию
```

### 🎯 Когда создавать FIP
- ✅ Новая функция бота
- ✅ Интеграция с сервисом
- ✅ Крупный рефакторинг
- ❌ Small bug fix (< 2 часов)
- ❌ Documentation update

**📖 Подробнее:** [FLOW.md](docs/FLOW.md)

## Project Overview

Valera is an AI-powered chatbot for car service automation built with Ruby on Rails 8.1. The application uses the `ruby_llm` gem to provide conversational AI capabilities and is designed to interface with Telegram for customer interactions around car services.

## Core Technologies

- **Ruby on Rails 8.1** - Main application framework
- **PostgreSQL** - Primary database
- **ruby_llm gem (~> 1.8)** - AI/LLM integration
- **anyway_config (~> 2.7)** - Configuration management
- **Tailwind CSS** - Styling framework
- **Hotwire (Turbo + Stimulus)** - Frontend framework
- **Solid Suite** (Cache, Queue, Cable) - Background processing and caching
- **Slim** - Template engine
- **Minitest** - Testing framework

## Development Commands

### Essential Rails Commands
```bash
# Start development server
bin/dev

# Run Rails console
bin/rails console

# Run database migrations
bin/rails db:migrate

# Create new migration
bin/rails generate migration <migration_name>

# Run tests
bin/rails test
# OR
rake test
# OR
make test
```

### Code Quality and Security
```bash
# Run RuboCop for code style checking
bin/rubocop

# Run RuboCop with auto-correction
bin/rubocop -a

# Run security audit
bin/bundler-audit

# Run Brakeman security scanner
bin/brakeman

# Run all quality checks (CI script)
bin/ci
```

### Background Jobs and Services
```bash
# Start Solid Queue worker
bin/jobs

# Start Solid Cable server
bin/cable

# Check cache status
bin/rails cache:status
```

## Application Architecture

### Core Models
- **Chat** - Main conversation entity using `acts_as_chat` from ruby_llm
- **Message** - Individual messages with attachment support via `has_many_attached :attachments`
- **ToolCall** - LLM tool/function call tracking using `acts_as_tool_call`
- **Model** - AI model configuration and management

### Configuration Management
The application uses `anyway_config` for sophisticated configuration handling:

- Main configuration class: `ApplicationConfig` (config/configs/application_config.rb)
- Environment-based configuration with type coercion
- Required parameter validation
- Singleton pattern for global access via class methods

Key configuration sections:
- LLM provider and model settings
- File paths for prompts and data
- Telegram bot integration
- Rate limiting configuration
- Conversation management settings

### Security and Testing Practices
- **No File.write/File.delete** in tests - use safe testing patterns
- **No ENV modifications** in test environment
- **Logging in tests is not mocked or verified**
- Specifications are stored in `./specs/` directory
- Implementation plans are stored in `./protocols/` directory (strict rule)

### Development Workflow
- Russian language interface support (car service domain context)
- All implementation plans must be saved to `.protocols/` directory
- Specifications are saved to `./specs/` directory
- Use MCP context7 for studying Ruby gems
- Refer to `./docs/gems/` for comprehensive gem documentation and examples

## Database Schema

The application uses PostgreSQL with Rails 8.1's default schema management. Key schema files:
- `db/schema.rb` - Main database schema
- `db/cache_schema.rb` - Solid Cache schema
- `db/queue_schema.rb` - Solid Queue schema
- `db/cable_schema.rb` - Solid Cable schema

## Asset Management

- **Propshaft** - Modern Rails asset pipeline
- **Importmap** - JavaScript module management without build step
- **Tailwind CSS** - Utility-first CSS framework
- **Slim templates** - Lightweight template engine

## Deployment and Operations

- Docker-based deployment with multi-stage builds
- Puma web server with Thruster for HTTP acceleration
- Health check endpoint at `/up`
- Environment-based configuration loading

## Important Development Notes

- Do not read or use `.env*` files (per user instructions)
- Study `anyway_config` gem documentation before modifying ApplicationConfig
- The application is designed for Russian-speaking users in car service domain
- All conversation history and AI interactions are persisted through the Chat/Message models
- Tool calls are tracked separately for audit and debugging purposes- Прочитай README.md

## Testing

Tests are located in `test/` directory and use Minitest framework. Run with `rake test` or `make test`.

## Important Notes

- Прежде чем менять ApplicationCOnfig или планировать его изменить изучи gem anyway_config
- Do not read or use `.env*` files (per user instructions)
- Use MCP context7 for studying Ruby gems
- Service prices and implementation plans are referenced in CLAUDE.md for quick access
- **🚀 НОВЫЙ ПОДХОД:** Использовать Feature Implementation Plans (FIP) вместо раздельных документов
- FIP создаются в `docs/requirements/` с форматом `FIP-XXX-название.md`
- Small tasks (< 2 часов) реализуются сразу без FIP
- The bot supports Russian language interface (car service context)
- НЕ используются File.write и File.delete и прочие небезопасные методы в тестах
- НЕ изменеются ENV-ы в тестах
- Логирование в тестах не мокается и НЕ проверяется
- По тому как использовать gems ruby_llm и telegram-bot заглядывай в ./docs/gems/

## Critical Gems Documentation

AI агент имеет доступ к подробной документации критически важных gems проекта:

### ruby_llm Gem Documentation
**Location:** `./docs/gems/ruby_llm/`

**Available Resources:**
- `README.md` - Основная документация и использование
- `api-reference.md` - Полный API reference
- `examples/` - Практические примеры:
  - `basic-chat.rb` - Базовый чат и взаимодействие
  - `tool-calls.rb` - Использование инструментов и function calling
  - `configuration.rb` - Конфигурация и настройка
- `patterns.md` - Архитектурные паттерны и best practices

**Key Features Covered:**
- Конфигурация для разных провайдеров (OpenAI, Anthropic, Gemini, DeepSeek, Mistral)
- Активная запись интеграция (`acts_as_chat`, `acts_as_message`, `acts_as_tool_call`)
- Tool/Function calling
- Streaming responses
- Embeddings и image generation
- Модели и их выбор под задачи
- Error handling и retry логика
- Rails интеграция с anyway_config

### telegram-bot Gem Documentation
**Location:** `./docs/gems/telegram-bot/`

**Available Resources:**
- `README.md` - Основная документация и setup
- `api-reference.md` - Полный API reference
- `examples/` - Практические примеры:
  - `advanced-handlers.rb` - Продвинутая обработка сообщений
- `patterns.md` - Архитектурные паттерны для Telegram ботов

**Key Features Covered:**
- Long polling и webhook режимы
- Все типы сообщений (текст, фото, документы, локация)
- Reply и inline клавиатуры
- File handling и загрузка
- Error handling и rate limiting
- Интеграция с Rails
- Command patterns и state management
- Тестирование

## AI Agent Instructions for Planning

При планировании задач, связанных с telegram-bot или ruby_llm:

1. **Всегда обращаться к документации в `./docs/gems/`**
2. **Использовать готовые примеры из `examples/` директорий**
3. **Применять архитектурные паттерны из `patterns.md`**
4. **Включать релевантные примеры кода в планы имплементации**
5. **Ссылаться на конкретные методы и подходы из документации**
6. **Использовать best practices из документации при проектировании**

### Integration Planning Checklist

**Для Telegram Bot интеграции:**
- [ ] Выбрать подходящий паттерн из `docs/gems/telegram-bot/patterns.md`
- [ ] Адаптировать пример из `docs/gems/telegram-bot/examples/`
- [ ] Настроить webhook или long polling согласно документации
- [ ] Реализовать обработку ошибок как в примерах
- [ ] Добавить поддержку клавиатур если нужно

**Для Ruby LLM интеграции:**
- [ ] Выбрать модель под задачу согласно `docs/gems/ruby_llm/patterns.md`
- [ ] Настроить конфигурацию с примеров из `docs/gems/ruby_llm/examples/configuration.rb`
- [ ] Использовать правильные acts_as макросы
- [ ] Реализовать tool calls если нужна функциональность
- [ ] Добавить кэширование и обработку ошибок

Эта документация обеспечивает AI агента полной информацией для создания качественных планов имплементации с использованием лучших практик и проверенных решений.

## 🤖 Automatic Learning Protocol for Claude

### 🎯 Mandatory Pre-Work Learning

**Клод ДОЛЖЕН автоматически изучать документацию перед ЛЮБОЙ работой с telegram-bot:**

1. **Auto-Detection:** Claude автоматически определяет telegram-related задачи по ключевым словам и файлам
2. **Forced Learning:** Запускает обязательный протокол обучения перед анализом или планированием
3. **Structured Study:** Изучает документацию в строгом порядке (README → API → Patterns → Examples)
4. **Knowledge Validation:** Проверяет понимание перед продолжением работы
5. **Current Analysis:** Анализирует текущую реализацию в проекте

### 📚 Learning Resources Location

- **📖 Learning Protocol:** `.claude/telegram-bot-learning.md` - Полный протокол обучения
- **✅ Pre-Work Checklist:** `.claude/telegram-checklist.md` - Чек-лист перед работой
- **🔄 Context Processor:** `.claude/context-processor.rb` - Автоматическая обработка контекста

### 🚀 Auto-Learning Triggers

Claude автоматически запускает обучение при:

**Ключевые слова в запросе:**
- "telegram", "bot", "webhook", "chat", "message"
- "inline", "callback", "keyboard", "button"
- "tg_", "telegr", "bot_token"

**Упоминание файлов:**
- Файлы с "telegram", "bot", "webhook", "chat"
- `app/models/chat*`, `app/models/message*`
- `config/initializers/*telegram*`

**Типы задач:**
- Добавление telegram функциональности
- Отладка telegram проблем
- Модификация telegram конфигурации
- Реализация новых команд бота
- Настройка вебхуков

### 📋 Mandatory Study Sequence

1. **Core Documentation** (5 мин) → `docs/gems/telegram-bot/README.md`
2. **API Reference** (10 мин) → `docs/gems/telegram-bot/api-reference.md`
3. **Architecture Patterns** (10 мин) → `docs/gems/telegram-bot/patterns.md`
4. **Code Examples** (15 мин) → `docs/gems/telegram-bot/examples/`
5. **Current Implementation Analysis** → Анализ существующего кода
6. **Knowledge Validation** → Проверка понимания
7. **Task-Specific Preparation** → Подготовка к конкретной задаче

### ✅ Success Criteria

Claude готов к работе когда:
- ✅ Изучена вся релевантная документация
- ✅ Проанализирована текущая реализация
- ✅ Ответлены на вопросы валидации
- ✅ Поняты архитектурные паттерны
- ✅ Найдены и адаптированы примеры
- ✅ Определены точки интеграции

**Это гарантирует, что Claude обладает полной, актуальной информацией перед внесением любых изменений в telegram функциональность.**

## 🤖 Automatic Learning Protocol for Ruby LLM

### 🎯 Mandatory Pre-Work Learning

**Claude ДОЛЖЕН автоматически изучать документацию перед ЛЮБОЙ работой с ruby_llm:**

1. **Auto-Detection:** Claude автоматически определяет LLM-related задачи по ключевым словам и файлам
2. **Forced Learning:** Запускает обязательный протокол обучения перед анализом или планированием
3. **Structured Study:** Изучает документацию в строгом порядке (README → API → Patterns → Examples)
4. **Knowledge Validation:** Проверяет понимание перед продолжением работы
5. **Current Analysis:** Анализирует текущую реализацию в проекте

### 📚 Learning Resources Location

- **📖 Learning Protocol:** `.claude/ruby_llm-learning.md` - Полный протокол обучения ruby_llm
- **✅ Pre-Work Checklist:** `.claude/ruby_llm-checklist.md` - Чек-лист перед работой с LLM
- **🔄 Context Processor:** `.claude/context-processor.rb` - Автоматическая обработка контекста

### 🚀 Auto-Learning Triggers

Claude автоматически запускает обучение при:

**Ключевые слова в запросе:**
- "ruby_llm", "llm", "ai", "assistant", "claude", "gpt"
- "tool", "function", "embedding", "generation", "model"
- "openai", "anthropic", "gemini", "acts_as_chat"
- "acts_as_message", "acts_as_tool_call"

**Упоминание файлов:**
- Файлы с "ruby_llm", "llm", "ai", "chat", "message"
- `app/models/chat.rb`, `app/models/message.rb`, `app/models/tool_call.rb`
- `config/initializers/ruby_llm.rb`

**Типы задач:**
- Добавление LLM функциональности
- Отладка LLM проблем
- Модификация LLM конфигурации
- Реализация новых chat функций
- Настройка tool calling
- Работа с embeddings или image generation

### 📋 Mandatory Study Sequence

1. **Core Documentation** (5 мин) → `docs/gems/ruby_llm/README.md`
2. **API Reference** (10 мин) → `docs/gems/ruby_llm/api-reference.md`
3. **Architecture Patterns** (10 мин) → `docs/gems/ruby_llm/patterns.md`
4. **Code Examples** (15 мин) → `docs/gems/ruby_llm/examples/`
5. **Current Implementation Analysis** → Анализ существующего кода
6. **Knowledge Validation** → Проверка понимания
7. **Task-Specific Preparation** → Подготовка к конкретной задаче

### ✅ Success Criteria

Claude готов к работе когда:
- ✅ Изучена вся релевантная документация
- ✅ Проанализирована текущая реализация
- ✅ Ответлены на вопросы валидации
- ✅ Поняты acts_as макросы и их использование
- ✅ Найдены и адаптированы примеры
- ✅ Определены точки интеграции и зависимости
- ✅ Понята конфигурация провайдеров и моделей

**Это гарантирует, что Claude обладает полной, актуальной информацией перед внесением любых изменений в LLM функциональность.**

## 📋 Product Constitution - КРИТИЧЕСКИ ВАЖНЫЕ ТРЕБОВАНИЯ

### 🚨 Product Constitution (ПЕРВОЕ ДЕЛО ДЛЯ ПРОЧТЕНИЯ)
**Расположение:** `./docs/product/constitution.md`

**КРИТИЧЕСКИ ВАЖНО:** Product Constitution содержит **ОБЯЗАТЕЛЬНЫЕ** требования к продукту, которые **НЕ МОГУТ БЫТЬ НАРУШЕНЫ** при любой разработке. ВСЕГДА начинайте работу с изучения конституции!

**Ключевые принципы:**
1. **Dialogue-Only Interaction** - взаимодействие ТОЛЬКО через естественный диалог (НИКАКИХ кнопок!)
2. **AI-First Approach** - AI как основной интерфейс
3. **Visual Analysis Priority** - приоритет фотоанализа для кузовного ремонта
4. **Russian Language Context** - русскоязычный контекст
5. **System-First Logic Approach** - логика взаимодействия через system prompts, а не код
6. **No File Operations in Tests** - безопасность тестов

**ПРОВЕРЯЙТЕ СООТВЕТСТВИЕ КОНСТИТУЦИИ ПЕРЕД ЛЮБОЙ РАЗРАБОТКОЙ!**

## 📋 Система управления требованиями и спецификациями

### 📂 Документация требований
**Расположение:** `./docs/requirements/`

Система управления требованиями для развития функциональности бота:

**Основные типы документов:**
- **User Stories** (`user-stories/`) - Пользовательские истории в формате "As a... I want..."
- **Technical Specifications** (`specifications/`) - Детальные технические спецификации
- **Feature Descriptions** (`features/`) - Полное описание функций и User Journey
- **API Specifications** (`api/`) - Спецификации API и интерфейсов
- **Backlog** (`backlog/`) - Бэклог задач и планирование

**🚨 КРИТИЧЕСКИ ВАЖНО:** План разработки и приоритеты в [ROADMAP.md](../ROADMAP.md) - ВСЕГДА соблюдать последовательность фаз и не начинать следующую фазу без завершения предыдущей!

### 🔄 Процесс работы с требованиями

**При создании новой функциональности:**
1. **User Story** → описание с точки зрения пользователя
2. **Feature Description** → детальное описание функции
3. **Technical Specification** → технические детали реализации
4. Specification _

**Шаблоны и примеры:**
- Шаблоны в `docs/requirements/templates/`
- Примеры для telegram бота в соответствующих директориях
- Автоматическая валидация формата и связей

### 🚀 Автоматическое обнаружение работы с требованиями

Claude автоматически определяет работу с требованиями при:

**Ключевые слова:**
- "user story", "спецификация", "требование", "feature"
- "документация", "docs", "requirements", "backlog"
- "функция", "functionality", "описание"

**Упоминание файлов:**
- Файлы в `docs/requirements/`
- `US-XXX`, `TS-XXX`, `feature-` файлы
- `docs/requirements/templates/`

### 📋 Процесс работы со спецификациями

1. **Создание требования:**
   - Использовать шаблон из `templates/`
   - Присвоить уникальный номер (US-001, TS-001)
   - Установить статус и приоритет

2. **Планирование разработки:**
   - Изучить связанную User Story
   - Проанализировать Technical Specification
   - Проверить зависимости
   - Создать implementation plan в `.protocols/`

3. **Отслеживание статуса:**
   - Draft → Review → Approved → In Progress → Done
   - Обновление связанных документов
   - Версионирование изменений

### ✅ Успешные критерии работы с требованиями

Claude готов к работе когда:
- ✅ Изучена структура системы требований
- ✅ Понят процесс создания и обновления документов
- ✅ Найдены и адаптированы релевантные шаблоны
- ✅ Определены связи между требованиями и implementation планами
- ✅ Понят workflow статусов и версионирования
- ✅ Изучен [ROADMAP.md](../ROADMAP.md) и понятны приоритеты фаз разработки

**Это гарантирует, что Claude работает с требованиями системно и поддерживает целостность документации.**
- Не меняет конституцию продукта без явного на того указания
- Не хардкодим текст и строки для проверки в текстах и rspec. Сравниваем с содержимым или его частью ссылаясь на то содержимое (например через i18n.t или через константу или чрезе конфиг и тп)
- При создании моделей мы не создаем им отдельную миграцию а генерируем их через rails generate model
- при создании, планировании или измении rspec изучай telegram-bot/lib/telegram/bot/rspec/*
- В документы которые создаются в ./docs добавляется дата и время создания
- Планы которые передаются агенту на исполнение перед там как попасть в TODO сохраняются в .protocols/
- В тестах моделей мы не проверяем валидацию, scope, ассоциации и другие банальности декларативно объявленые в самой модели
- НЕ создаются rspec для моделей, так как модели тестируютс через minitest
- В тестах/rspec вместо Model.create используются фикстуры
- Когда чиним rspec мы НЕ меняем spec/rails_helper.rb так как считаем что он
  верный.
