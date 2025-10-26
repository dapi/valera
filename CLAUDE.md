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

## 📋 Правило разделения документации

**WHY → [.claude/memory-bank.md](.claude/memory-bank.md)** | **HOW → CLAUDE.md**

Подробнее см. [memory-bank.md](.claude/memory-bank.md#правило-разделения-документации-zero-дублирования)

## 📋 Quick Start (практическая инструкция)

1. **Изучи архитектуру (WHY):** [.claude/memory-bank.md](.claude/memory-bank.md)
2. **Технологический стек (HOW):** Ruby on Rails 8.1 + ruby_llm + PostgreSQL
3. **Основные команды (HOW):** `bin/dev`, `bin/rails test`, `bin/rubocop`
4. **Документация (HOW):** [docs/README.md](docs/README.md)
5. **🚀 Новый flow работы:** [FLOW.md](docs/FLOW.md) - **ОБЯЗАТЕЛЬНО**
6. **📚 Полный справочник документации:** [DOCUMENTATION_INDEX.md](DOCUMENTATION_INDEX.md) - быстрая навигация по всем документам

> **Подробнее о технологическом стеке и командах разработки** см. ниже в этом документе.

---

## 🤖 Автоматическое обучение Claude (для AI-агентов)

> **Важно:** Эта информация для AI-агентов, работающих с ПРОЕКТОМ Valera.

### Как работает система обучения

**Автоматическое обнаружение задач:**
- Telegram-related задачи → изучение telegram-bot документации
- LLM-related задачи → изучение ruby_llm документации
- Требования и спецификации → изучение FLOW.md и requirements/

**Обязательное изучение перед работой:**
- Claude автоматически изучает релевантную документацию
- Использует проверенные паттерны из docs/gems/
- Гарантирует качество реализации

### Статус обучения

Claude отслеживает актуальность документации:
- **Активная разработка**: обновление каждые 1 час
- **Отладка**: обновление каждые 6 часов
- **Поддержка**: обновление каждые 24 часа

### Доступные инструменты для самообучения

**Автоматический доступ:**
```bash
# Telegram Bot документация
bin/docs telegram-bot patterns
bin/docs telegram-bot examples photo-handling

# Ruby LLM документация
bin/docs ruby_llm patterns
bin/docs ruby_llm examples visual-analysis

# Поиск по документации
bin/docs search "damage assessment"
```

**Ручной запуск обучения:**
```bash
ruby .claude/pre-work-hook.rb "add photo processing for damage assessment"
ruby .claude/pre-work-hook.rb "implement AI damage analysis from photos"
```

**См. также:**
- [Telegram Bot Learning](.claude/telegram-bot-learning.md)
- [Ruby LLM Learning](.claude/ruby_llm-learning.md)
- [Memory Bank](.claude/memory-bank.md)

---

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


# Run telegram web server in poller model (for development)
./bin/rails telegram:bot:poller
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

### Documentation Generation (YARD)
```bash
# Generate YARD documentation
rake doc:generate
# OR
rake yard

# Start YARD server for local viewing
rake doc:serve
# OR
rake yard_server

# Clean generated documentation
rake doc:clean
# OR
rake yard_clean

# Regenerate documentation with cache reset
rake doc:regenerate

# Check documentation coverage
rake doc:coverage

# Generate documentation graphs (requires graphviz)
rake doc:graphs

# Generate complete documentation with graphs and coverage
rake doc:complete

# Check documentation quality
rake doc:quality
```

### YARD Documentation Standards

**🚨 ОБЯЗАТЕЛЬНО:** Все классы, модули и методы должны иметь YARD-документацию!

**Базовый шаблон документации:**
```ruby
# frozen_string_literal: true

# Краткое описание класса/модуля одной строкой
#
# Подробное описание назначения и использования класса/модуля.
# Может включать примеры использования, важные замечания и т.д.
#
# @example Базовый пример использования
#   service = MyService.new(parameter: "value")
#   result = service.execute
#   puts result
#
# @author Valera Team
# @since 0.1.0
class MyClass
  # Краткое описание метода одной строкой
  #
  # Подробное описание работы метода, включая бизнес-логику,
  # особенности использования и возможные ошибки.
  #
  # @param param1 [String] описание первого параметра
  # @param param2 [Hash] опциональные параметры
  # @option param2 [Symbol] :mode режим работы (:default, :advanced)
  # @option param2 [Boolean] :debug включить отладочные сообщения
  # @return [String] результат выполнения метода
  # @raise [ArgumentError] если param1 пустой
  # @raise [StandardError] при внутренней ошибке
  # @example Выполнение с базовыми параметрами
  #   my_method("test", mode: :default)
  #   #=> "processed: test"
  # @example Выполнение с отладкой
  #   my_method("test", debug: true)
  #   #=> "DEBUG: processing test"
  # @todo Добавить валидацию параметров
  # @note Этот метод является асинхронным
  def my_method(param1, param2 = {})
    # реализация
  end
end
```

**Требования к документации:**
- ✅ **Все публичные методы** должны иметь документацию
- ✅ **Классы и модули** должны иметь описание назначения
- ✅ **Параметры** должны быть типизированы и описаны
- ✅ **Возвращаемые значения** должны иметь указание типа
- ✅ **Исключения** должны быть документированы
- ✅ **Примеры использования** для сложных методов
- ✅ **@since** тег для всех новых элементов
- ✅ **@author Danil Pismenny** тег для всех новых классов (ОБЯЗАТЕЛЬНО)

**YARD теги и их использование:**
- `@param [Type] name` - описание параметра метода
- `@return [Type]` - возвращаемое значение
- `@raise [Error]` - исключения которые может вызвать метод
- `@option param [Type] name` - опции в Hash параметрах
- `@example` - примеры использования
- `@note` - важные замечания
- `@todo` - запланированные улучшения
- `@deprecated [Version]` - пометка устаревшего кода
- `@see Class#method` - ссылки на связанный код
- `@since version` - версия добавления функциональности
- `@author Danil Pismenny` - автор кода (ВСЕГДА использовать именно это значение)
- `@api private` - для внутренних методов

**Проверка качества документации:**
```bash
# Проверить покрытие документации
rake doc:coverage

# Проверить качество документации
rake doc:quality
```

**Генерация документации:**
- Документация генерируется в `doc/yard/`
- Для просмотра используется `rake doc:serve` (http://localhost:8808)
- Автоматически обновляется при изменении файлов

### YardMCP Integration (MCP Server)

**🚀 YardMCP - MCP сервер для интеграции YARD с Claude:**

YardMCP обеспечивает прямой доступ к YARD документации из Claude Code через MCP (Model Context Protocol).

**Установка YardMCP:**
```bash
gem install yardmcp
```

**Настройка Claude Code:**
YardMCP автоматически обнаруживается и интегрируется в Claude Code.

**Доступные YardMCP инструменты:**
- **Поиск и навигация:**
  - Поиск классов, методов и модулей по имени
  - Получение детальной информации о классах
  - Анализ методов и параметров
  - Список всех классов с фильтрацией

- **Генерация и анализ:**
  - Генерация YARD документации
  - Отчеты о покрытии документации
  - Поиск недокументированных элементов

**Использование YardMCP в Claude:**
```
Используй YardMCP для поиска "BookingTool"
Используй YardMCP для анализа класса "AnalyticsService"
Используй YardMCP для проверки покрытия документации
```

**Команды YardMCP:**
```bash
# Запуск YardMCP сервера
yardmcp

# Проверка доступности
yardmcp --help

# Индексация документации
yardmcp --index
```

**Преимущества YardMCP:**
- 🔄 **Автоматическая индексация** - сканирует всю YARD документацию
- 🔍 **Интеллектуальный поиск** - ищет по именам и содержанию
- 📊 **Аналитика покрытия** - отслеживает качество документации
- ⚡ **Быстрый доступ** - прямая интеграция с Claude Code
- 🎯 **Контекстная работа** - учитывает структуру проекта

**Документация YardMCP:**
- `mcp_servers/yard_mcp/README.md` - полное руководство
- Официальная документация: `yardmcp --help`

### Background Jobs and Services
```bash
# Start Solid Queue worker
bin/jobs

# Start Solid Cable server
bin/cable

# Check cache status
bin/rails cache:status
```

## Журналирование (логи, logging)

Журналирование в development - log/development.log
Журналирование в test - log/test.log

### 🚨 Расширенное логирование ошибок (ErrorLogger)

**КРИТИЧЕСКИ ВАЖНО:** ВСЕГДА использовать модуль `ErrorLogger` вместо `Bugsnag.notify(e)`!

**Location:** `app/concerns/error_logger.rb`

**Правило использования:**
```ruby
rescue => e
  # ПРАВИЛЬНО: один вызов вместо логирования + Bugsnag
  log_error(e, { context_key: context_value })

  # НЕПРАВИЛЬНО: прямой вызов Bugsnag или простое логирование
  Rails.logger.error "Error: #{e.message}"
  Bugsnag.notify(e) # ЗАПРЕЩЕНО!
end
```

**Возможности модуля:**
- ✅ Автоматическая отправка в Bugsnag с контекстом
- ✅ Полный backtrace ошибки с нумерацией строк
- ✅ Контекстная информация (пользователь, чат, параметры и т.д.)
- ✅ Автоматическое форматирование для читаемости
- ✅ Поддержка кастомных логгеров

**Где подключать:** В любом классе/контроллере/модели с rescue блоками:
```ruby
include ErrorLogger
```

**Примечание:** Метод `log_error()` автоматически отправляет ошибку в Bugsnag с переданным контекстом. Не нужно вызывать `Bugsnag.notify()` отдельно!

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

### Development Workflow
- Russian language interface support (car service domain context)
- User Stories and Requirements in `docs/requirements/user-stories/` and `docs/requirements/tdd/`
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

## 🤖 Automatic Learning Protocols

Детальные протоколы обучения для claude находятся в `.claude/`:
- **Telegram Bot:** [.claude/README.md](.claude/README.md) и [.claude/telegram-bot-learning.md](.claude/telegram-bot-learning.md)
- **Ruby LLM:** [.claude/ruby_llm-learning.md](.claude/ruby_llm-learning.md)

**Обязательно изучи эти протоколы перед работой с соответствующими технологиями!**

## 📋 Product Constitution - КРИТИЧЕСКИ ВАЖНЫЕ ТРЕБОВАНИЯ

**🚨 ОБЯЗАТЕЛЬНО К ИЗУЧЕНИЮ:** [Product Constitution](docs/product/constitution.md) - неприкосновенные требования к продукту!

**Критичные принципы (НИКОГДА не нарушать):**
1. **Dialogue-Only Interaction** - ТОЛЬКО естественный диалог (НИКАКИХ кнопок!)
2. **AI-First Approach** - AI как основной интерфейс

**Остальные принципы:** Visual Analysis Priority, Russian Language Context, System-First Logic, No File Operations in Tests.

**📖 Полная информация:** [constitution.md](docs/product/constitution.md)

## 📋 Система управления требованиями

**Полная документация:** [docs/requirements/README.md](docs/requirements/README.md)
**Процесс работы:** [FLOW.md](docs/FLOW.md)
**Приоритеты разработки:** [ROADMAP.md](docs/ROADMAP.md)

**Quick Reference:**
- **User Stories:** `docs/requirements/user-stories/US-XXX.md` (As a/I want/So that)
- **Technical Design:** `docs/requirements/tdd/TDD-XXX.md` (техническая реализация)
- **Templates:** `docs/requirements/templates/` (шаблоны для создания документов)

**Автоматическое обнаружение:** Агент активируется при ключевых словах "user story", "спецификация", "требование", "feature" или работе с файлах в `docs/requirements/`.

## ⚙️ Правила разработки проекта

- Не меняет конституцию продукта без явного на того указания
- При создании моделей мы не создаем им отдельную миграцию а генерируем их через rails generate model
- В документы которые создаются в ./docs добавляется дата и время создания
- Планы которые передаются агенту на исполнение перед там как попасть в TODO сохраняются в .protocols/
- В тестах моделей мы не проверяем валидацию, scope, ассоциации и другие банальности декларативно объявленые в самой модели
  верный.
- Соблюдается принцип Single Source of Truth
- Когда создаются файлы (классы и модули) на ruby, оставляется комментарий с описанием этого калсса, для чего он нужен, что делает и в рамках каких требований реализован со ссылкаи на эти требования.


---

## 📊 Информация о документе

**Версия:** 2.0
**Дата создания:** 15.10.2024
**Последнее обновление:** 26.10.2025
**Тип документа:** HOW (Практические инструкции)
**Ответственный:** Tech Lead / Development Team

📈 **[Метрики использования](docs/docs-usage-metrics.md#claudemd)** - см. централизованный документ метрик
