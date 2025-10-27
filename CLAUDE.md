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
- **[Тестирование](docs/development/README.md#testing)** - правила тестирования
- **[Технологический стек](docs/development/stack.md)** - полный стек технологий
- **[Обработка ошибок](docs/patterns/error-handling.md)** - паттерны ErrorLogger

---
**Версия:** 3.0 | **Последнее обновление:** 27.10.2025
