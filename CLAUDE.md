# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 📋 Правило разделения документации

**WHY → [.claude/memory-bank.md](.claude/memory-bank.md)** | **HOW → CLAUDE.md**

## 🚀 Quick Start

**Основная документация:** [docs/README.md](docs/README.md) | **Архитектура:** [.claude/memory-bank.md](.claude/memory-bank.md) | **Разработка:** [docs/development/README.md](docs/development/README.md)

## Project Overview

Valera - AI-powered чат-бот для автоматизации автосервиса на Ruby on Rails 8.1 с использованием `ruby_llm` и интеграцией с Telegram.

## 🚨 ErrorLogger (КРИТИЧЕСКИ ВАЖНО)

**КРИТИЧЕСКИ ВАЖНО:** ВСЕГДА использовать `log_error(e, context)` вместо `Bugsnag.notify(e)`!

```ruby
include ErrorLogger

rescue => e
  log_error(e, { user_id: user.id, action: "process_booking" })
end
```

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
- ВСЕГДА используй `rails generate model` для создания моделей
- Используй `ErrorLogger` вместо `Bugsnag.notify()`
- Не использовать `.env*` файлы
- В тестах не использовать File.write/File.delete и не изменять ENV

## 📚 Полезные ссылки

- **[Development Guide](docs/development/README.md)** - полный гайд разработчика
- **[Product Constitution](docs/product/constitution.md)** - требования к продукту
- **[FLOW.md](docs/FLOW.md)** - процесс работы с требованиями
- **[Гемы](docs/gems/README.md)** - документация по ключевым gem'ам
- **[Тестирование](docs/development/README.md#testing)** - правила тестирования

---
**Версия:** 3.0 | **Последнее обновление:** 27.10.2025