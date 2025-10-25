# 📚 Документация Valera

## Обзор

Добро пожаловать в документацию проекта **Valera** - AI-powered чат-бота для автоматизации автосервиса, построенного на Ruby on Rails 8.1.

## 🚨 ВАЖНО: Product Constitution

**ПЕРВОЕ ЧТО НУЖНО ПРОЧИТАТЬ:** [📋 Product Constitution](product/constitution.md)

Содержит **неотъемлемые требования** к продукту, которые **НЕ МОГУТ БЫТЬ НАРУШЕНЫ** при разработке.

## 📂 Структура документации

### 🏗️ [Продукт](product/)
- **[📋 Конституция](product/constitution.md)** - ОБЯЗАТЕЛЬНЫЕ требования к продукту
- **[📊 Примеры данных](product/data-examples/)** - Системные промпты, сообщения, прайс-листы
- **[🚀 Bootstrap](product/bootstrap/)** - Начальная настройка проекта

### 📋 [Требования](requirements/)
- **[📖 Обзор](requirements/README.md)** - Система управления требованиями
- **[🤖 Инструкция для AI](requirements/README-AI-AGENTS.md)** - Работа с требованиями
- **[🗺️ MVP Roadmap](requirements/mvp-roadmap-priorities.md)** - Дорожная карта разработки
- **[🎭 User Stories](requirements/user-stories/)** - Пользовательские истории
- **[🔧 Технические спецификации](requirements/specifications/)** - Детальные спецификации
- **[🌟 Описание функций](requirements/features/)** - Полное описание функций
- **[🔌 API спецификации](requirements/api/)** - API документация
- **[📋 Шаблоны](requirements/templates/)** - Шаблоны документов

### 💎 [Gem'ы](gems/)
- **[🤖 ruby_llm](gems/ruby_llm/)** - AI/LLM интеграция
- **[📱 telegram-bot](gems/telegram-bot/)** - Telegram бот интеграция

## 🎯 Ключевые принципы разработки

### 🚨 Обязательные требования (Product Constitution)
1. **Dialogue-Only Interaction** - взаимодействие ТОЛЬКО через диалог
2. **AI-First Approach** - AI как основной интерфейс
3. **Visual Analysis Priority** - приоритет фотоанализа для кузовного ремонта
4. **Russian Language Context** - русскоязычный контекст
5. **System-First Logic Approach** - логика через system prompts
6. **No File Operations in Tests** - безопасность тестов

### 📋 Процесс работы с требованиями
1. User Story → Feature Description → Technical Specification → Technical Solution
2. Technical Solutions сохраняются в `docs/requirements/technical-solutions/`
3. Соблюдать последовательность фаз в [ROADMAP.md](../ROADMAP.md)

### 🤖 Автоматическое обучение AI
- Telegram бот: [протокол обучения](../.claude/telegram-bot-learning.md)
- Ruby LLM: [протокол обучения](../.claude/ruby_llm-learning.md)

## 🔄 Поиск информации

### По задачам:
- **Разработка функций** → [requirements/features/](requirements/features/)
- **Технические детали** → [requirements/specifications/](requirements/specifications/)
- **API интеграция** → [requirements/api/](requirements/api/)
- **Gem документация** → [gems/](gems/)

### По технологиям:
- **Telegram бот** → [gems/telegram-bot/](gems/telegram-bot/)
- **AI/LLM integration** → [gems/ruby_llm/](gems/ruby_llm/)

## 📝 Навигация по документации

### Последовательное чтение:
1. [Product Constitution](product/constitution.md) - ОБЯЗАТЕЛЬНО
2. [Requirements Overview](requirements/README.md) - для понимания системы
3. [MVP Roadmap](requirements/mvp-roadmap-priorities.md) - для планирования

### Быстрый доступ:
- **Конфигурация** → [gems/ruby_llm/examples/configuration.rb](gems/ruby_llm/examples/configuration.rb)
- **Примеры кода** → [gems/*/examples/](gems/)
- **Шаблоны документов** → [requirements/templates/](requirements/templates/)
- **Прайс-листы** → [product/data-examples/](product/data-examples/)

## 🚀 Начало работы

**Основные документы для изучения:**
- [Product Constitution](product/constitution.md) - ОБЯЗАТЕЛЬНО
- [Requirements Overview](requirements/README.md) - система требований
- [MVP Roadmap](requirements/mvp-roadmap-priorities.md) - дорожная карта

---

**⚠️ ВАЖНО:** Всегда начинайте работу с изучения [Product Constitution](product/constitution.md) и [ROADMAP.md](../ROADMAP.md) перед разработкой!