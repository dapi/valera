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
- **[🔄 Flow](FLOW.md)** - ОСНОВНОЙ процесс работы с документацией
- **[📖 Обзор](requirements/README.md)** - Система управления требованиями
- **[🗺️ Roadmap](ROADMAP.md)** - Дорожная карта разработки
- **[🎭 User Stories](user-stories/)** - Пользовательские истории
- **[🏗️ Technical Design Documents](tdd/)** - Технические проекты
- **[🌟 Описание функций](features/)** - Полное описание функций
- **[🔌 API спецификации](api/)** - API документация
- **[📋 Шаблоны](templates/)** - Шаблоны документов

### 💎 [Gem'ы](gems/)
- **[🤖 ruby_llm](gems/ruby_llm/)** - AI/LLM интеграция
- **[📱 telegram-bot](gems/telegram-bot/)** - Telegram бот интеграция
- **[📝 Markdown Parser Comparison](gems/markdown-parser-comparison.md)** - Анализ парсеров для Markdown очистки

### 🛠 [Разработка](development/)
- **[📝 Тестирование промптов](development/prompt-testing-guide.md)** - Инструкция по созданию и оптимизации системных промптов

## 🎯 Ключевые принципы разработки

### 🚨 Обязательные требования (Product Constitution)
**ОБЯЗАТЕЛЬНО ПРОЧИТАТЬ:** [Product Constitution](product/constitution.md) - содержит неотъемлемые требования к продукту, которые **НЕ МОГУТ БЫТЬ НАРУШЕНЫ** при разработке.

### 📋 Процесс работы с требованиями
1. **User Story + Technical Design Document** (гибридный подход)
2. **Flow процесс:** docs/FLOW.md (ОСНОВНОЙ документ)
3. User Stories в `user_stories/`, TDD в `tdd/`
4. Соблюдать последовательность фаз в [ROADMAP.md](../ROADMAP.md)

### 🤖 Автоматическое обучение AI
- Telegram бот: [протокол обучения](../.claude/telegram-bot-learning.md)
- Ruby LLM: [протокол обучения](../.claude/ruby_llm-learning.md)

## 🔄 Поиск информации

### По задачам:
- **Flow процессы** → [FLOW.md](FLOW.md) (ОСНОВНОЙ)
- **Разработка функций** → [requirements/features/](requirements/features/)
- **User Stories** → [user-stories/](user-stories/)
- **Technical Design** → [tdd/](tdd/)
- **API интеграция** → [requirements/api/](requirements/api/)
- **Gem документация** → [gems/](gems/)

### По технологиям:
- **Telegram бот** → [gems/telegram-bot/](gems/telegram-bot/)
- **AI/LLM integration** → [gems/ruby_llm/](gems/ruby_llm/)

## 📝 Навигация по документации

### Последовательное чтение:
1. [Product Constitution](product/constitution.md) - ОБЯЗАТЕЛЬНО
2. [FLOW.md](FLOW.md) - ОСНОВНОЙ процесс работы
3. [Requirements Overview](requirements/README.md) - для понимания системы
4. [Roadmap](ROADMAP.md) - для планирования

### Быстрый доступ:
- **Конфигурация** → [gems/ruby_llm/examples/configuration.rb](gems/ruby_llm/examples/configuration.rb)
- **Примеры кода** → [gems/*/examples/](gems/)
- **Шаблоны документов** → [requirements/templates/](requirements/templates/)
- **Прайс-листы** → [product/data-examples/](product/data-examples/)

## 🚀 Начало работы

**Основные документы для изучения:**
- [Product Constitution](product/constitution.md) - ОБЯЗАТЕЛЬНО
- [FLOW.md](FLOW.md) - ОСНОВНОЙ процесс работы
- [Requirements Overview](requirements/README.md) - система требований
- [Roadmap](ROADMAP.md) - дорожная карта

## 🔧 Поддержка документации (регламент)

### 📋 Кто и когда будет запускать скрипты:

**Еженедельно (по пятницам):**
- **Lead Developer** - полный аудит документации
```bash
./docs/scripts/documentation-audit.sh
```

**Перед релизами:**
- **Product Owner** - проверка критических файлов
```bash
./docs/scripts/check-product-constitution.sh
```

**Перед commit изменений:**
- **Разработчик** - быстрая проверка
```bash
./docs/scripts/validate-links.sh
```

Подробнее о скриптах см. [🛠 Scripts README](scripts/README.md)

---

**⚠️ ВАЖНО:** Всегда начинайте работу с изучения [Product Constitution](product/constitution.md) и [ROADMAP.md](ROADMAP.md) перед разработкой!
