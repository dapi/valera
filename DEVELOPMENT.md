# Development Guide

**Дата создания:** 26.10.2025
**Версия:** 1.0
**Целевая аудитория:** Разработчики проекта Valera
**Тип документа:** HOW (Практическое руководство)

> **Важно:** Это руководство для разработчиков ПРОЕКТА Valera.
> О продукте (AI-боте) см. [docs/product/](docs/product/)

---

## 🚀 Быстрый старт для разработчиков

### Установка окружения

```bash
# Клонирование
git clone <repo-url>
cd valera

# Зависимости
bundle install

# База данных
bin/rails db:create db:migrate

# Запуск
bin/dev
```

### Первые шаги

1. [CLAUDE.md](CLAUDE.md) - инструкции и архитектура
2. [Product Constitution](docs/product/constitution.md) - требования к продукту
3. [FLOW.md](docs/FLOW.md) - процесс разработки
4. [Глоссарий](docs/glossary.md) - терминология проекта

---

## 🛠️ Инструменты разработчика

### Документация gems

**Быстрый доступ:**
```bash
# Telegram Bot
bin/docs telegram-bot patterns
bin/docs telegram-bot examples photo-handling
bin/docs telegram-bot api-reference

# Ruby LLM
bin/docs ruby_llm patterns
bin/docs ruby_llm examples visual-analysis
bin/docs ruby_llm api-reference

# Поиск
bin/docs search "damage assessment"
bin/docs list
```

**Структура:**
- `docs/gems/telegram-bot/` - Telegram интеграция
- `docs/gems/ruby_llm/` - AI/LLM интеграция
- Каждый gem: README, API reference, patterns, examples

### Development команды

```bash
# Разработка
bin/dev                    # Dev сервер
bin/rails console          # Console
bin/rails test             # Тесты
bin/rubocop               # Code style
bin/rubocop -a            # Auto-fix
bin/brakeman              # Security
bin/ci                    # Все проверки

# База данных
bin/rails db:migrate      # Миграции
bin/rails db:rollback     # Откат
bin/rails db:reset        # Пересоздать

# Telegram Bot
bin/rails telegram:bot:poller  # Polling режим (dev)
```

### Интеграция с Claude AI

**Автоматическое обучение:**
- Telegram задачи → изучает telegram-bot docs
- LLM задачи → изучает ruby_llm docs
- Features → изучает requirements/, FLOW.md

**Ручной запуск:**
```bash
ruby .claude/pre-work-hook.rb "your task description"
```

**См. подробнее:**
- [.claude/README.md](.claude/README.md)
- [.claude/telegram-bot-learning.md](.claude/telegram-bot-learning.md)
- [.claude/ruby_llm-learning.md](.claude/ruby_llm-learning.md)

---

## 📋 Процесс разработки

### Workflow новой функции

1. **User Story** (опционально)
   - Шаблон: `docs/requirements/templates/`

2. **Technical Design Document**
   - Шаблон: `docs/requirements/templates/`

3. **Реализация**
   - Следовать [Product Constitution](docs/product/constitution.md)
   - Использовать паттерны из `docs/gems/`
   - TDD подход

4. **Code Review**
   ```bash
   bin/ci  # Запустить локально
   ```

**См. подробнее:** [FLOW.md](docs/FLOW.md)

---

## 🧪 Testing

### Запуск тестов

```bash
# Все
bin/rails test

# Файл
bin/rails test test/models/chat_test.rb

# Конкретный тест
bin/rails test test/models/chat_test.rb:12
```

### Правила тестирования

⚠️ **ВАЖНО:**
- ❌ НЕ использовать `File.write`, `File.delete`
- ❌ НЕ изменять ENV переменные
- ❌ Логирование НЕ мокается и НЕ проверяется

**Подробнее:** [CLAUDE.md](CLAUDE.md#testing)

---

## 🤖 AI Development с Claude

### Workflow с Claude Code

1. Задать задачу Claude
2. Claude изучает документацию (авто)
3. Claude создает план → `.protocols/`
4. Реализация с паттернами
5. Code review и тесты

**Оптимизация:**
- Автообучение при Telegram/LLM работе
- Готовые паттерны в `docs/gems/`
- Примеры кода для быстрого старта

---

## 📚 Полезные ссылки

- [CLAUDE.md](CLAUDE.md) - Инструкции
- [Product Constitution](docs/product/constitution.md) - Требования к продукту
- [FLOW.md](docs/FLOW.md) - Процесс
- [ROADMAP.md](docs/ROADMAP.md) - План
- [Глоссарий](docs/glossary.md) - Терминология
- [DOCUMENTATION_INDEX.md](DOCUMENTATION_INDEX.md) - Навигация

---

## 🔧 Troubleshooting

**Зависимости:**
```bash
bundle install
bin/rails db:reset
```

**Тесты:**
```bash
RAILS_ENV=test bin/rails db:reset
bin/rails test
```

**Telegram Bot:**
- Проверить `config/configs/application_config.rb`
- `bin/docs telegram-bot troubleshooting`

---

**Версия:** 1.0
**Дата создания:** 26.10.2025
**Последнее обновление:** 26.10.2025
**Ответственный:** Development Team
