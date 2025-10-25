# 📚 Documentation Index - Полный указатель документации

Centralised index всех документов проекта Valera с быстрым навигатором.

---

## 🎯 Быстрый старт

**Новичок?** Начни отсюда:
1. [.claude/memory-bank.md](.claude/memory-bank.md) - Архитектурные решения и WHY
2. [CLAUDE.md](CLAUDE.md) - Практические инструкции и HOW
3. [docs/product/constitution.md](docs/product/constitution.md) - Неприкосновенные требования

---

## 📂 Структура документации

### 🧠 Архитектурные решения (WHY)

| Документ | Назначение | Приоритет |
|----------|-----------|----------|
| [.claude/memory-bank.md](.claude/memory-bank.md) | Ключевые архитектурные решения, критерии качества, team structure | 🔴 КРИТИЧЕСКИЙ |
| [docs/product/constitution.md](docs/product/constitution.md) | Неприкосновенные принципы продукта (dialogue-only, AI-first и т.д.) | 🔴 КРИТИЧЕСКИЙ |
| [docs/ROADMAP.md](docs/ROADMAP.md) | План разработки по фазам, приоритизация | 🟠 ВЫСОКИЙ |

### 🛠️ Практические инструкции (HOW)

| Документ | Назначение | Для кого |
|----------|-----------|---------|
| [CLAUDE.md](CLAUDE.md) | Основные команды, технологический стек, процессы | AI Agents |
| [docs/README.md](docs/README.md) | Структура документации и навигация | Разработчики |
| [docs/FLOW.md](docs/FLOW.md) | Workflow разработки, создание новых функций | Team |

### 📖 Обучающие протоколы

| Документ | Тема | Обязательно |
|----------|------|-----------|
| [.claude/README.md](.claude/README.md) | Конфигурация Claude для проекта | ✅ Да |
| [.claude/telegram-bot-learning.md](.claude/telegram-bot-learning.md) | Обучение для работы с Telegram | ✅ Перед telegram |
| [.claude/ruby_llm-learning.md](.claude/ruby_llm-learning.md) | Обучение для работы с LLM | ✅ Перед LLM |

### 📋 Система требований

| Документ | Содержит | Организация |
|----------|----------|-------------|
| [docs/requirements/](docs/requirements/) | User Stories, TDD, templates | |
| [docs/requirements/user-stories/](docs/requirements/user-stories/) | Пользовательские истории | US-XXX |
| [docs/requirements/tdd/](docs/requirements/tdd/) | Test-Driven Development спецификации | TDD-XXX |
| [docs/requirements/templates/](docs/requirements/templates/) | Шаблоны для новых документов | .md templates |

### 📚 Документация по Gems

| Документ | Gem | Использование |
|----------|-----|--------------|
| [docs/gems/telegram-bot/README.md](docs/gems/telegram-bot/README.md) | telegram-bot | Основная документация |
| [docs/gems/telegram-bot/api-reference.md](docs/gems/telegram-bot/api-reference.md) | telegram-bot | API методы и параметры |
| [docs/gems/telegram-bot/patterns.md](docs/gems/telegram-bot/patterns.md) | telegram-bot | Архитектурные паттерны |
| [docs/gems/ruby_llm/README.md](docs/gems/ruby_llm/README.md) | ruby_llm | Основная документация |
| [docs/gems/ruby_llm/api-reference.md](docs/gems/ruby_llm/api-reference.md) | ruby_llm | API и методы |
| [docs/gems/ruby_llm/patterns.md](docs/gems/ruby_llm/patterns.md) | ruby_llm | Архитектурные паттерны |

### 📊 Примеры и данные

| Документ | Содержит | Использование |
|----------|----------|--------------|
| [docs/gems/telegram-bot/examples/](docs/gems/telegram-bot/examples/) | Практические примеры | Reference для реализации |
| [docs/gems/ruby_llm/examples/](docs/gems/ruby_llm/examples/) | Примеры использования LLM | Reference для реализации |
| [docs/product/data-examples/](docs/product/data-examples/) | System prompts, ценовые листы | Ready-to-use материалы |

### 🎨 Различные

| Документ | Назначение |
|----------|-----------|
| [docs/glossary.md](docs/glossary.md) | Глоссарий терминов проекта |
| [docs/domain/](docs/domain/) | Domain-specific документация (справочная) |

---

## 🔍 Поиск по типам задач

### 🚀 Добавляю новую функцию

1. Прочитать [Product Constitution](docs/product/constitution.md)
2. Изучить [FLOW.md](docs/FLOW.md) для workflow
3. Создать User Story в [docs/requirements/user-stories/](docs/requirements/user-stories/)
4. Написать TDD в [docs/requirements/tdd/](docs/requirements/tdd/)
5. Реализовать функцию

### 🐛 Отлаживаю Telegram бота

1. Прочитать [.claude/telegram-bot-learning.md](.claude/telegram-bot-learning.md)
2. Обратиться к [docs/gems/telegram-bot/api-reference.md](docs/gems/telegram-bot/api-reference.md)
3. Изучить примеры в [docs/gems/telegram-bot/examples/](docs/gems/telegram-bot/examples/)
4. Проверить [docs/gems/telegram-bot/patterns.md](docs/gems/telegram-bot/patterns.md)

### 🤖 Работаю с LLM/AI функциональностью

1. Прочитать [.claude/ruby_llm-learning.md](.claude/ruby_llm-learning.md)
2. Изучить [docs/gems/ruby_llm/api-reference.md](docs/gems/ruby_llm/api-reference.md)
3. Посмотреть примеры в [docs/gems/ruby_llm/examples/](docs/gems/ruby_llm/examples/)
4. Применить паттерны из [docs/gems/ruby_llm/patterns.md](docs/gems/ruby_llm/patterns.md)

### 📚 Изучаю архитектуру проекта

1. Начни с [.claude/memory-bank.md](.claude/memory-bank.md)
2. Прочитай [docs/product/constitution.md](docs/product/constitution.md)
3. Посмотри [CLAUDE.md](CLAUDE.md) для HOW
4. Изучи [docs/ROADMAP.md](docs/ROADMAP.md) для плана

### ✅ Создаю документацию

1. Обратись к [docs/requirements/templates/](docs/requirements/templates/)
2. Следуй критериям качества из [.claude/memory-bank.md](.claude/memory-bank.md#4-критерии-качества-документации-обязательные-для-всех-агентов)
3. Проверь правило WHY/HOW в [CLAUDE.md](CLAUDE.md)

---

## 📊 Статистика документации

- **Всего документов:** 40+
- **Критических:** 3 (memory-bank, constitution, CLAUDE)
- **Основных:** 8 (roadmap, flow, requirements, gems)
- **Справочных:** 30+
- **Примеров кода:** 15+

---

## 🔄 Процесс обновления документации

Все документы содержат:
- ✅ Четкое назначение (WHY или HOW)
- ✅ Быстрый поиск инструкций
- ✅ Ссылки на связанные документы
- ✅ Примеры и templates

Следуй правилу **Zero дублирования**: каждая информация в одном месте, остальные - ссылки.

---

## 🎯 Часто используемые документы

**По популярности:**

1. 🔴 [.claude/memory-bank.md](.claude/memory-bank.md) - 10+ обращений в день
2. 🔴 [CLAUDE.md](CLAUDE.md) - Reference для команды
3. 🔴 [docs/product/constitution.md](docs/product/constitution.md) - Проверка перед разработкой
4. 🟠 [docs/FLOW.md](docs/FLOW.md) - Workflow разработки
5. 🟠 [docs/gems/telegram-bot/README.md](docs/gems/telegram-bot/README.md) - Справка по боту

---

**Последнее обновление:** 25.10.2025
**Ответственный:** Documentation System
**Версия:** 1.0
