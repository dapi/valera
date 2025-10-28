# 📚 Documentation Index

**Создан:** 28.10.2025
**Версия:** 1.0
**Статус:** Active Navigation Index

## 🎯 Назначение

Этот документ служит центральным навигационным узлом для всей документации проекта Valera. Используйте его для быстрого поиска нужной информации.

## 📋 Структура документации

### 🚀 **Быстрый старт (Quick Start)**
- **[CLAUDE.md](../CLAUDE.md)** - Основная документация для Claude Code AI Agent
- **[README.md](../README.md)** - Общее описание проекта
- **[docs/INDEX.md](INDEX.md)** - Детальный индекс документации

### 📋 **Requirements (Требования)**
`docs/requirements/`
- **[fip/](requirements/fip/)** - Feature Implementation Plans (основные функции)
  - **[FIP-001-analytics-system.md](requirements/fip/FIP-001-analytics-system.md)** - Система аналитики
  - **[FIP-004-multitenancy.md](requirements/fip/FIP-004-multitenancy.md)** - Multi-tenancy архитектура
  - **[FIP-005-memberships-boss-bot.md](requirements/fip/FIP-005-memberships-boss-bot.md)** - Авторизация владельцев
- **[user-stories/](requirements/user-stories/)** - User Stories (пользовательские истории)
- **[tdd/](requirements/tdd/)** - Test-Driven Development спецификации
- **[templates/](requirements/templates/)** - Шаблоны для создания документов

### 🏗️ **Architecture (Архитектура)**
`docs/architecture/`
- **[decisions.md](architecture/decisions.md)** - Зафиксированные архитектурные решения
- **[domain/models.md](architecture/domain/models.md)** - Core domain модели
- **[bounded-contexts.md](architecture/bounded-contexts.md)** - Bounded contexts

### 💎 **Gems (Технические компоненты)**
`docs/gems/`
- **[ruby_llm/](gems/ruby_llm/)** - Ruby LLM gem документация
- **[telegram-bot/](gems/telegram-bot/)** - Telegram Bot gem документация
- **[anyway_config/](gems/anyway_config/)** - Configuration management
- **[vcr/](gems/vcr/)** - VCR testing documentation

### 🛠️ **Development (Разработка)**
`docs/development/`
- **[README.md](development/README.md)** - Гайд разработчика
- **[tech-stack.md](development/tech-stack.md)** - Технологический стек проекта
- **[SETUP.md](development/SETUP.md)** - Настройка окружения
- **[YARD_DOCUMENTATION_STANDARDS.md](development/YARD_DOCUMENTATION_STANDARDS.md)** - Стандарты документации
- **[prompt-testing-guide.md](development/prompt-testing-guide.md)** - Гайд по тестированию промптов

### 📊 **Product (Продукт)**
`docs/product/`
- **[constitution.md](product/constitution.md)** - Конституция продукта (критически важный документ)
- **[metrics.md](product/metrics.md)** - Метрики продукта
- **[alternative-names.md](product/alternative-names.md)** - Альтернативные названия

### 💼 **SaaS (Бизнес-модель)**
`docs/saas/`
- **[README.md](saas/README.md)** - SaaS бизнес документация
- **[saas-overview.md](saas/saas-overview.md)** - Общие сведения SaaS
- **[monetization-strategy.md](saas/monetization-strategy.md)** - Стратегия монетизации
- **[business-value.md](saas/business-value.md)** - Бизнес-ценность
- **[competitors.md](saas/competitors.md)** - Конкурентный анализ

### 🚀 **Deployment (Развертывание)**
`docs/deployment/`
- **[README.md](deployment/README.md)** - Деплоймент документация
- **[production.md](deployment/production.md)** - Production окружение

### 🎯 **Domain (Предметная область)**
`docs/domain/`
- **[models.md](domain/models.md)** - Модели домена
- **[glossary.md](domain/glossary.md)** - Глоссарий терминов

### 📊 **Analytics (Аналитика)**
`docs/analytics/`
- **[README.md](analytics/README.md)** - Event tracking
- **[metabase-setup.md](analytics/metabase-setup.md)** - Metabase настройка

### 🗃️ **Archive (Архив)**
`docs/archive/`
- Устаревшие документы (сохранены для истории)

---

## 🔍 Поиск по типам задач

### 🚀 **Для нового развития:**
1. Выберите User Story из `docs/requirements/user-stories/`
2. Создайте FIP по шаблону из `docs/requirements/templates/`
3. Согласуйте с Product Constitution

### 🛠️ **Для технической реализации:**
1. Изучите архитектуру в `docs/architecture/`
2. Проверьте gem документацию в `docs/gems/`
3. Следуйте гайду разработчика `docs/development/README.md`

### 📊 **Для бизнес-анализа:**
1. Начните с Product Constitution `docs/product/constitution.md`
2. Изучите SaaS документацию `docs/saas/`
3. Проверьте метрики `docs/product/metrics.md`

### 🧪 **Для тестирования:**
1. Используйте VCR documentation `docs/gems/vcr/`
2. Следуйте стандартам `docs/development/YARD_DOCUMENTATION_STANDARDS.md`
3. Проверьте prompt testing guide `docs/development/prompt-testing-guide.md`

---

## 🎯 Роли и рекомендуемые документы

### **AI Agent / Claude Code:**
- **Обязательно:** [CLAUDE.md](../CLAUDE.md)
- **Архитектура:** [decisions.md](architecture/decisions.md)
- **Разработка:** [development/README.md](development/README.md)

### **Product Owner:**
- **Обязательно:** [constitution.md](product/constitution.md)
- **Бизнес:** [saas/README.md](saas/README.md)
- **Планирование:** [requirements/README.md](requirements/README.md)

### **Developer:**
- **Обязательно:** [development/SETUP.md](development/SETUP.md)
- **Архитектура:** [architecture/](architecture/)
- **Гемы:** [gems/](gems/)

### **Investor/Stakeholder:**
- **Обязательно:** [saas/README.md](saas/README.md)
- **Продукт:** [product/constitution.md](product/constitution.md)
- **Метрики:** [product/metrics.md](product/metrics.md)

---

## 🔗 Важнейшие связи

### Product Constitution ↔ Все документы
Конституция продукта является основой для всех решений и должна учитываться во всех документах.

### FIP ↔ User Stories
Каждый FIP должен ссылаться на соответствующие User Stories.

### Architecture ↔ Implementation
Архитектурные решения должны согласовываться с технической реализацией в gem документации.

### Development ↔ Testing
Процесс разработки должен включать тестирование согласно VCR документации.

---

## 📈 Метрики документации

- **Всего документов:** 120+ markdown файлов
- **Основных разделов:** 10 категорий
- **Критически важных:** Product Constitution, CLAUDE.md
- **Часто обновляемых:** FIP, SaaS документация

---

**Версия:** 1.0
**Последнее обновление:** 28.10.2025
**Ответственный:** Documentation Team
**Тип документа:** Navigation Index