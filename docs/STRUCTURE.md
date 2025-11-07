# 📁 Древовидная структура документации Valera

**Обновлено:** 06.11.2025
**Версия:** 1.0
**Назначение:** Полная структура папок и файлов документации проекта

## 🎯 Обзор проекта

**Valera** - AI-powered чат-бот для автоматизации автосервиса
- **Технологии:** Ruby on Rails 8.1, ruby_llm, telegram-bot
- **Архитектура:** ПРОЕКТ (open-source репозиторий) + ПРОДУКТ (Telegram бот инстансы)

```
docs/ (34 директории, 123 файла)
├── 📋 Core Documentation (6 файлов)
├── 🎯 Product & Business (17 файлов)
├── 📋 Requirements System (38 файлов)
├── 🔧 Technical & Development (24 файла)
├── 🏗️ Deployment & Operations (16 файлов)
├── 📊 Analytics & Marketing (5 файлов)
├── 👥 User Experience (9 файлов)
└── 💬 AI & Prompts (2 файла)
```

## 🌳 Полная древовидная структура

```
📁 docs/
│
├── 📋 CORE DOCUMENTATION
│   ├── 📖 README.md                           # Основная навигация по ролям
│   ├── 🔄 FLOW.md                             # Процесс работы с требованиями
│   ├── 📚 INDEX.md                           # Индекс документации
│   ├── 📋 DOCUMENTATION_INDEX.md             # Структура документации
│   └── 📄 documentation-organization.md      # Принципы организации
│
├── 🎯 PRODUCT & BUSINESS
│   ├── 📋 product/
│   │   ├── 📜 constitution.md                 # Конституция продукта
│   │   ├── 🗺️ ROADMAP.md                      # Дорожная карта (активные фазы)
│   │   ├── 📦 BACKLOG.md                      # Очередь на рассмотрение
│   │   ├── ❄️ ICEBOX.md                       # Отложенные идеи
│   │   ├── 🚫 DEPRECATED.md                   # Архив отклоненных
│   │   ├── 🗺️ ROADMAP-ARCHIVE.md              # История изменений
│   │   ├── 🎯 PRODUCT_QUEST.md                # Ключевые вопросы продукта
│   │   ├── 💰 business-metrics.md             # Бизнес-метрики
│   │   ├── 🏷️ alternative-names.md            # Альтернативные названия
│   │   │
│   │   └── 📊 data-examples/                  # Примеры данных
│   │       ├── 🏢 company-info.md
│   │       ├── 💬 welcome-message.md
│   │       ├── 🤖 system-prompt.md
│   │       ├── 💰 price.csv
│   │       ├── 🛠️ кузник.csv
│   │       └── 🏆 престиж.csv
│   │
│   └── 📈 saas/                               # SaaS модель
│       ├── 📋 saas-overview.md
│       ├── 💰 business-value.md
│       ├── ⚔️ competitors.md
│       └── 💸 monetization-strategy.md
│
├── 📋 REQUIREMENTS SYSTEM
│   ├── 📚 requirements/README.md
│   │
│   ├── 📜 templates/                          # Шаблоны документов
│   │   ├── 👤 user-story-template.md
│   │   ├── 🛠️ technical-specification-document-template.md
│   │   ├── 🔧 FIP-template.md
│   │   ├── 📦 PRD-template.md
│   │   └── 📝 user-story-examples.md
│   │
│   ├── 👥 user-stories/                       # User Stories (US)
│   │   ├── 🤖 US-001-telegram-auto-greeting.md
│   │   ├── 💬 US-002a-telegram-basic-consultation.md
│   │   ├── 📅 US-002b-telegram-recording-booking.md
│   │   ├── 📸 US-003-telegram-photo-damage-assessment.md
│   │   ├── 🛡️ US-004-telegram-insurance-automation.md
│   │   ├── ✅ US-005-telegram-booking-confirmation.md
│   │   ├── 🔍 US-006-telegram-chat-id-detection.md
│   │   ├── 🔧 US-007-telegram-services-discovery.md
│   │   ├── 🎁 US-008-telegram-gift-certificates.md
│   │   └── 📞 US-009-telegram-callback-paint-services.md
│   │
│   ├── 🔧 tsd/                               # Technical Design Documents (TSD)
│   │   ├── 📊 TSD-001-analytics-system.md
│   │   ├── 💬 TSD-002a-telegram-basic-consultation.md
│   │   ├── 📅 TSD-002b-telegram-recording-booking.md
│   │   ├── 📸 TSD-003-telegram-photo-damage-assessment.md
│   │   ├── 🛡️ TSD-004-telegram-insurance-automation.md
│   │   ├── 🔍 TSD-006-telegram-chat-id-detection.md
│   │   ├── 🔧 TSD-007-telegram-services-discovery.md
│   │   ├── 🎁 TSD-008-telegram-gift-certificates.md
│   │   ├── 📞 TSD-009-telegram-callback-paint-services.md
│   │   └── 🧹 TSD-010-markdown-cleaner-implementation.md
│   │
│   ├── ⚡ fip/                               # Feature Implementation Plans (FIP)
│   │   ├── 📊 FIP-001-analytics-system.md
│   │   ├── 📢 FIP-003-chat-id-notification-system.md
│   │   ├── 🏢 FIP-004-multitenancy.md
│   │   ├── 👑 FIP-005-memberships-boss-bot.md
│   │   ├── ⚠️ FIP-006-development-warnings.md
│   │   ├── 🌡️ FIP-007-smart-temperature-configuration.md
│   │   ├── 📈 FIP-011-utm-tracking-in-start-command.md
│   │   ├── ✅ FIP-012-quality-control-feedback-system.md
│   │   ├── 🚨 FIP-013-система-эскалации-диалогов-менеджерам.md
│   │   ├── 📞 FIP-015-callback-and-scheduling-system.md
│   │   └── 🗜️ FIP-020-система-компактизации-диалогов.md
│   │
│   ├── 📦 prd/                               # Product Requirements Documents
│   │   ├── 📞 PRD-001-callback-paint-services.md
│   │   └── 💬 PRD-002-text-only-interaction.md
│   │
│   ├── 🔌 api/                               # API документация
│   │   └── 📡 api-telegram-webhook-v1.md
│   │
│   └── 🗃️ _archive/                          # Архив требований
│
├── 🔧 TECHNICAL & DEVELOPMENT
│   ├── 💻 development/                       # Разработка
│   │   ├── 📖 README.md
│   │   ├── ⚙️ SETUP.md
│   │   ├── 🛠️ tech-stack.md
│   │   ├── 🧪 prompt-testing-guide.md
│   │   ├── 📚 YARD_QUICK_START.md
│   │   ├── 📚 YARD_DOCUMENTATION_STANDARDS.md
│   │   └── 🔗 YARDMCP_INTEGRATION_GUIDE.md
│   │
│   ├── 🏗️ domain/                            # Доменная модель
│   │   ├── 📖 README.md
│   │   ├── 📚 glossary.md                    # Глоссарий (критически важно)
│   │   ├── 🏗️ models.md
│   │   ├── 📋 domain-models-simplified.md
│   │   ├── 🔍 bounded-contexts.md
│   │   └── 📝 terminology.md
│   │
│   ├── 🎭 implementation/                   # Реализация
│   │   └── 🔄 pr/                            # Pull Request templates
│   │
│   └── 💡 concepts/                          # Концептуальные документы
│       └── 💬 contextual-dialog-system.md
│
├── 🚀 DEPLOYMENT & OPERATIONS
│   ├── 📋 deployment/README.md
│   ├── 🐳 DOCKER.md                          # Docker настройка
│   ├── 📊 MONITORING.md                      # Мониторинг
│   ├── ⚡ QUICK_DEPLOYMENT_GUIDE.md
│   ├── 📋 deployment-readiness-report.md
│   ├── 🔧 COMPONENT_REFERENCE.md
│   ├── 🔌 API_REFERENCE.md
│   │
│   ├── 📚 gems/                              # Документация по gem'ам
│   │   ├── 📖 README.md
│   │   ├── 📝 markdown-parser-comparison.md
│   │   │
│   │   ├── 🤖 ruby_llm/                      # AI интеграция
│   │   │   ├── 📖 README.md
│   │   │   ├── 📚 api-reference.md
│   │   │   ├── 🔧 patterns.md
│   │   │   │
│   │   │   └── 💡 examples/
│   │   │       ├── 💬 basic-chat.rb
│   │   │       ├── ⚙️ configuration.rb
│   │   │       └── 🛠️ tool-calls.rb
│   │   │
│   │   ├── 📱 telegram-bot/                  # Telegram интеграция
│   │   │   ├── 📖 README.md
│   │   │   ├── 📚 api-reference.md
│   │   │   ├── 🔧 patterns.md
│   │   │   │
│   │   │   └── 💡 examples/
│   │   │       └── 🚀 advanced-handlers.rb
│   │   │
│   │   └── 📼 vcr/                            # VCR для тестов
│   │       ├── 📖 README.md
│   │       ├── 📚 api-reference.md
│   │       │
│   │       └── 💡 examples/
│   │           ├── 🔧 basic-usage.rb
│   │           ├── ⚙️ advanced-configuration.rb
│   │           ├── 🧪 testing-patterns.rb
│   │           └── 🔬 rspec-integration.rb
│   │
│   └── 🔧 patterns/                          # Паттерны разработки
│       ├── 📋 INDEX.md
│       └── ⚠️ error-handling.md
│
├── 📊 ANALYTICS & MARKETING
│   ├── 📈 analytics/                         # Аналитика
│   │   ├── 📖 README.md
│   │   ├── 🗄️ metabase-setup.md
│   │   │
│   │   └── 🗃️ sql/                          # SQL запросы
│   │       ├── 📊 performance_metrics.sql
│   │       └── 🔍 conversion_funnel.sql
│   │
│   └── 📢 marketing/                         # Маркетинг
│       ├── 📖 README.md
│       └── ⚔️ competitive-analysis.md
│
├── 👥 USER EXPERIENCE
│   ├── 📋 user-scenarios/                    # Сценарии использования
│   │   ├── 📖 README.md
│   │   ├── 💬 01-service-dialog-scenarios.md
│   │   ├── 🛠️ 02-post-booking-support.md
│   │   ├── ❓ 03-general-inquiries.md
│   │   ├── 😤 04-complaint-resolution.md
│   │   ├── 💰 05-sales-objection-handling.md
│   │   ├── 📸 06-photo-based-assessment.md
│   │   ├── 📅 07-ideal-booking-flow.md
│   │   └── 🔧 DIALOG_STARTED_v2_IMPLEMENTATION_PLAN.md
│   │
│   └── 🔍 cust-dev/                          # Customer Development
│       └── 🛠️ kuznik/
│           └── 📅 28-10-2025.md
│
└── 💬 AI & PROMPTS
    ├── 🤖 prompts/                           # Промпты для AI
    │   └── 🎭 valera-personality-prompts.md
    │
    └── 📋 INDEX.md
```

## 🎯 Ключевые особенности структуры

### 📋 Система требований (FLOW подход)
- **User Stories (US):** ЧТО хочет пользователь
- **Technical Design (TSD):** КАК реализовать технически
- **Feature Implementation (FIP):** Внутренняя/техническая функциональность
- **Templates:** Готовые шаблоны для всех типов документов

### 🔄 Статусы документов
```
Draft → BusinessAnalyzes → SystemAnalyzes → Ready →
In Progress → Completed → Production
```

### 🏗️ Архитектурные принципы
- **Zero дублирование:** Каждый концепт описывается один раз
- **Единый источник правды:** Ссылки вместо копирования
- **Консистентность:** Единый стиль и терминология

### 🎯 Навигация по ролям
- **🤖 Для AI-агентов:** README.md → FLOW.md → ../CLAUDE.md
- **👨‍💻 Для разработчиков:** README.md → ../CLAUDE.md → development/
- **👔 Для Product Owner:** README.md → product/ → requirements/

## 📊 Статистика структуры

| Категория | Директории | Файлы | Назначение |
|-----------|------------|-------|------------|
| Core Documentation | - | 6 | Основная навигация |
| Product & Business | 2 | 17 | Продукт и бизнес |
| Requirements System | 7 | 38 | Управление требованиями |
| Technical & Development | 4 | 24 | Техническая документация |
| Deployment & Operations | 5 | 16 | Развертывание |
| Analytics & Marketing | 2 | 5 | Аналитика и маркетинг |
| User Experience | 2 | 9 | Пользовательский опыт |
| AI & Prompts | 1 | 2 | AI и промпты |
| **ИТОГО** | **34** | **123** | |

## 🔗 Связанные документы

- **[FLOW.md](FLOW.md)** - Процесс работы с требованиями
- **[README.md](README.md)** - Основная навигация по ролям
- **[product/constitution.md](product/constitution.md)** - Конституция продукта
- **[domain/glossary.md](domain/glossary.md)** - Глоссарий проекта

---

**📝 Документ создан:** 06.11.2025
**🔄 Обновлен:** 06.11.2025
**👤 Ответственный:** Documentation Maintainer
**📏 Объем:** 34 директории, 123 файла