# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 🚀 Quick Start

**Основная документация:** [docs/README.md](docs/README.md) | **Архитектура:** [docs/architecture/decisions.md](docs/architecture/decisions.md) | **Разработка:** [docs/development/README.md](docs/development/README.md) | **Продукт:** [docs/product/constitution.md](docs/product/constitution.md)

## Project Overview

**Valera** - AI-powered чат-бот для автоматизации автосервиса на Ruby on Rails 8.1 с использованием `ruby_llm` и интеграцией с Telegram.

### 🎯 Ключевая концепция
- **ПРОЕКТ:** Open-source репозиторий для владельцев автосервисов
- **ПРОДУКТ:** Telegram бот для клиентов автосервиса
- **ПОДХОД:** Dialogue-only взаимодействие через AI

### 🏗️ Технологический стек
- **Backend:** Ruby on Rails 8.1
- **AI:** ruby_llm gem
- **Database:** PostgreSQL
- **Integration:** Telegram Bot API
- **Configuration:** anyway_config

## 🛡️ Error Handling

**КРИТИЧЕСКИ ВАЖНО:** Используй централизованную систему обработки ошибок через `ErrorLogger`

**Основной источник:** [docs/patterns/error-handling.md](docs/patterns/error-handling.md) - полная документация по паттернам обработки ошибок

## 🏗️ Архитектура

**Core Technologies:** Ruby on Rails 8.1 + ruby_llm + PostgreSQL + Telegram-bot

**Core Models:**
- **Chat** - Основная сущность разговора (`acts_as_chat`)
- **Message** - Сообщения с вложениями
- **ToolCall** - LLM tool вызовы
- **Booking** - Заявки на автосервис (связь с Chat)
- **TelegramUser** - Пользователи Telegram
- **AnalyticsEvent** - Аналитика событий

**Configuration Management:** Использует `anyway_config` с классом `ApplicationConfig`. Подробности в [docs/gems/](docs/gems/) и [docs/development/README.md](docs/development/README.md)

## ⚙️ Критические правила разработки

**🚨 КРИТИЧЕСКИ ВАЖНО:**
- **Models:** ВСЕГДА используй `rails generate model` для создания моделей и миграций одновременно
- **Error Handling:** Используй `ErrorLogger` вместо `Bugsnag.notify()`
- **Configuration:** Не использовать `.env*` файлы, только `anyway_config`
- **Documentation:** НИКОГДА не архивировать FIP/US/TSD/PR и любые другие документы их папки ./docs/requirements
- **Testing:** В тестах не использовать File.write/File.delete и не изменять ENV
- **Documentation:** Документация создается для AI-агентов в первую очередь
- **AI Architecture:** User Stories разделяются по уровням system prompt, не по бизнес-функциям

**Подробнее:** [docs/development/stack.md](docs/development/stack.md) и [docs/development/README.md](docs/development/README.md)

### 🎯 Архитектурные принципы
Подробная информация в [docs/architecture/decisions.md](docs/architecture/decisions.md)


## 📚 Полезные ссылки

- **[Development Guide](docs/development/README.md)** - полный гайд разработчика
- **[Product Constitution](docs/product/constitution.md)** - требования к продукту
- **[FLOW.md](docs/FLOW.md)** - процесс работы с требованиями
- **[Гемы](docs/gems/README.md)** - документация по ключевым gem'ам

## 🔄 Процесс разработки новых функций

### 🎯 Feature Implementation Plans (FIP) - ОСНОВНОЙ ПОДХОД

**Ключевой принцип:** Один документ на функцию (**Feature Implementation Plan**) вместо трех (User Story + Tech Spec + Tech Solution).

#### 📋 Создание новой функции
```bash
# Процесс: FIP → Implementation
1. Копировать шаблон: docs/requirements/templates/FIP-template.md
2. Создать FIP-XXX-название.md в docs/requirements/fip/
3. Заполнить все разделы
4. Получить утверждение
5. Сразу начинать реализацию
```

#### 🎯 Когда создавать FIP
- ✅ Новая функция бота
- ✅ Интеграция с сервисом
- ✅ Крупный рефакторинг
- ✅ Изменения в архитектуре
- ❌ Small bug fix (< 2 часов)
- ❌ Documentation update
- ❌ Minor configuration changes

#### 📁 Структура FIP файлов
- **Активные:** `docs/requirements/fip/FIP-XXX-название.md`
- **Архив:** `docs/archive/FIP-XXX-название.md` (завершенные)
- **Шаблон:** `docs/requirements/templates/FIP-template.md`

**User Story + Technical Design** - альтернативный workflow для малых функций

**📖 Подробнее:** [FLOW.md](docs/FLOW.md)
- **[Тестирование](docs/development/README.md#testing)** - правила тестирования
- **[Технологический стек](docs/development/stack.md)** - полный стек технологий
- **[Обработка ошибок](docs/patterns/error-handling.md)** - паттерны ErrorLogger

---
**Версия:** 3.0 | **Последнее обновление:** 27.10.2025
# 🧠 Memory Bank - Ключевые архитектурные решения

**Назначение:** Памятка ключевых решений для Claude AI Agent
**Статус:** 🚨 **КРИТИЧЕСКИ ВАЖНО ДЛЯ ЧТЕНИЯ ПЕРЕД РАБОТОЙ**

---

## 🚨 КРИТИЧЕСКИ ВАЖНОЕ ПРАВИЛО: БЕЗ АРХИВАЦИИ ДОКУМЕНТОВ

**🔴 ЗАПРЕЩЕНО:** Переносить FIP, US, TSD документы в `docs/archive/`

**Почему это критически важно:**
- **Сохранение нумерации:** FIP-001, FIP-002, FIP-003... должны оставаться в единой системе
- **Контекстовая целостность:** Архивация нарушает понимание полной картины проекта
- **Поиск и навигация:** Разделение по папкам усложняет поиск связанных документов
- **Историческая ценность:** Все документы представляют ценность для понимания эволюции проекта

**✅ Правильный подход:**
- Документы остаются на своих местах: `docs/requirements/fip/`, `docs/requirements/user-stories/`, `docs/requirements/tdd/`
- Статус документа обновляется внутри файла (Draft → In Progress → Done)
- Для пометки устаревших документов использовать префикс `[DEPRECATED]` в названии
- Ссылки на актуальные версии сохраняются в DOCUMENTATION_INDEX.md

---

## 🏗️ Архитектурные принципы

### **Разделение User Stories по уровням system prompt**

**Принцип:** Разделять User Stories по уровням сложности system prompt, а не по бизнес-функциям

**Почему это важно:**
- US-001: Basic system prompt (приветствие)
- US-002a: Enhanced system prompt (консультации)
- US-002b: Enhanced system prompt (консультации + запись)
- Эволюция идет от простого к сложному в рамках одного бизнес-процесса

**Как проверять:**
- Убедиться, что complexity растет последовательно
- Проверить соответствие Product Constitution

### **4. Критерии качества документации (ОБЯЗАТЕЛЬНЫЕ для всех агентов)**
**Применяется:** ВСЕГДА при создании ЛЮБЫХ документов

**Zero дублирования:**
- Каждый факт существует только в одном месте
- Использовать ссылки вместо копирования
- Перед созданием проверить существование

**Single source of truth:**
- Архитектурные решения → memory-bank.md
- Практические инструкции → CLAUDE.md
- User Stories → docs/requirements/user-stories/
- Технические спецификации → docs/requirements/tdd/

**Структурированная навигация:**
- Все документы должны быть в DOCUMENTATION_INDEX.md
- Четкие иерархии и связи между документами
- Быстрый поиск по типам задач

---

## 👥 Team Structure

**Критически важно:** В проекте только один человек

**Роли:**
- **CEO/Product Owner:** Бизнес-требования и приоритеты
- **Tech Lead:** Технические решения и архитектура
- **Developer:** Реализация и тестирование
- *Все роли выполняет один человек*

**Коммуникация:**
- Все решения документируются
- Self-review процессов
- Асинхронная работа с документами

---

## 📚 Документация

**Разделение по типам:**
- **User Stories:** Пользовательские истории в формате "As a... I want..."
- **TDD:** Test-Driven Development спецификации
- **FIP:** Feature Implementation Plans (комплексные документы)
- **Templates:** Шаблоны для создания новых документов

**Критерии качества:**
- Zero дублирования
- Single source of truth
- Структурированная навигация
- Актуальность ссылок

---

## 🧪 Тестирование Telegram бота через RSpec

**Решение:** Использовать RSpec для тестирования Telegram бота (webhook controller)
**Причина:** RSpec имеет лучшие возможности для тестирования webhook endpoints и JSON responses

**Структура тестов:**
```ruby
spec/
├── requests/
│   └── telegram/
│       └── webhook_controller_spec.rb  # Тесты webhook processing
├── services/
│   ├── telegram/
│   │   ├── webhooks/
│   │   │   └── processor_service_spec.rb  # Тесты business logic
│   │   └── message_handler_service_spec.rb
├── models/
│   ├── chat_spec.rb
│   ├── message_spec.rb
│   └── booking_spec.rb
└── factories/
    └── ...
```

**Key patterns:**
- Use `post :webhook` для тестирования webhook endpoints
- Mock external services (Telegram API, LLM)
- Test JSON responses and status codes
- Use FactoryBot для создания тестовых данных
- Test async processing with Solid Queue

---

## 🎯 Зафиксированные архитектурные решения (из docs/solutions.md)

### **Решение 1: Разделение User Stories для эволюции AI**

**Проблема:** Объединять или разделять US-002a (консультация) и US-002b (запись)

**Принятое решение:** **Разделять User Stories**

**Обоснование:**
- Эволюция сложности: basic → enhanced → enhanced + booking
- Четкие milestone для прогресса
- Возможность протестировать каждый этап
- Соответствует принципу "divide and conquer"

**Реализация:**
- US-001: Basic greeting (простой prompt)
- US-002a: Enhanced consultation (улучшенный prompt)
- US-002b: Enhanced + recording (консультация + запись)

### **Решение 2: Dialogue-Only Product Constitution**

**Проблема:** Нарушения Product Constitution в технических спецификациях

**Принятое решение:** **Строгое соблюдение dialogue-only принципа**

**Обоснование:**
- Конкурентное преимущество через AI dialogue
- Отказ от традиционных UI patterns
- Фокус на естественном общении

**Реализация:**
- Все функции работают через dialogue interface
- Никаких buttons, menus, или navigation
- AI обрабатывает все запросы через conversation

### **Решение 3: Реалистичные бизнес-метрики для MVP**

**Проблема:** Оптимистичные прогнозы (20% конверсия, 15,000₽ средний чек)

**Принятое решение:** **Консервативные метрики**

**Обоснование:**
- Более реалистичное планирование
- Устойчивое развитие
- Подготовка к worst case scenarios

**Реализация:**
- Конверсия: 10% (вместо 20%)
- Средний чек: 8,000₽ (вместо 15,000₽)
- TTF: 2-3 месяца (вместо 1 месяца)

---

## 🎯 Feature Implementation Plans (FIP) - КРИТИЧЕСКИ ВАЖНО

**Принцип:** FIP никогда не архивируются!

**Структура FIP:**
- Комплексный документ объединяющий User Story + Technical Design
- Находится в `docs/requirements/fip/`
- Нумерация сквозная и непрерывная

**Процесс работы:**
1. Создать FIP из шаблона
2. Заполнить все разделы
3. Получить утверждение
4. Реализовать функцию
5. Обновить статус на "Done"

**⚠️ ЗАПРЕЩЕНО:**
- Переносить FIP в `docs/archive/`
- Изменять нумерацию существующих FIP
- Создавать дубликаты с разными номерами

---

## 🔄 Process Integration

### **Когда использовать FIP:**
- Новая функция бота
- Интеграция с сервисом
- Крупный рефакторинг
- Изменения в архитектуре

### **Когда использовать US + TDD:**
- Маленькие изменения (< 2 часов)
- Bug fixes
- Documentation updates
- Minor configuration changes

### **Integration points:**
- FIP ссылается на соответствующие US
- TDD создается для complex technical задач
- Все документы связаны в DOCUMENTATION_INDEX.md

---

**🚨 ПРАВИЛО №1:** НИКОГДА не переносить FIP, US, TSD в архив!
**🚨 ПРАВИЛО №2:** Сохранять сквозную нумерацию документов!
**🚨 ПРАВИЛО №3:** Всегда проверять memory-bank.md перед началом работы!

---