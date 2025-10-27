# 🤖 Навигация для AI-агентов

**Создано:** 2025-01-27
**Цель:** Оптимизация поиска информации для AI-агентов
**Аудитория:** Claude Code и другие AI-агенты

---

## 🚖 Критически важные документы (изучить первыми)

### **FLOW.md** - Процесс разработки
- **Приоритет:** Критический
- **Содержание:** Двухдокументный подход (User Story + TSD)
- **Когда читать:** Перед любой разработческой задачей
- **Ключевые моменты:** FLOW-подход, быстрое прототипирование

### **CLAUDE.md** - Технические инструкции
- **Приоритет:** Критический
- **Содержание:** Технический стек, команды, архитектура
- **Когда читать:** При работе с кодом проекта
- **Ключевые моменты:** Ruby on Rails 8.1, ruby_llm, telegram-bot

### **glossary.md** - Базовая терминология
- **Приоритет:** Высокий
- **Содержание:** Базовые термины проекта
- **Когда читать:** При работе с доменной областью
- **Ключевые моменты:** PDR, ЛКП, ДТП, базовые понятия

### **domain/terminology.md** - Расширенная терминология
- **Приоритет:** Высокий
- **Содержание:** Полная терминология + бизнес-правила
- **Когда читать:** Для глубокой экспертизы домена
- **Ключевые моменты:** Расширенные термины, правила общения

---

## 🔄 Процессы разработки

### **Основной процесс**
- **[FLOW.md](./FLOW.md)** - Подробное описание процесса разработки
- **[requirements/README.md](./requirements/README.md)** - Работа с требованиями

### **Шаблоны и примеры**
- **[requirements/templates/](./requirements/templates/)** - Шаблоны документов
- **[requirements/user-stories/](./requirements/user-stories/)** - Примеры User Stories
- **[requirements/tsd/](./requirements/tsd/)** - Примеры технических спецификаций

---

## 💼 Техническая документация

### **Gem интеграции**
- **[gems/telegram-bot/](./gems/telegram-bot/)** - Telegram интеграция
  - README.md - Основная документация
  - examples/ - Практические примеры
  - patterns.md - Архитектурные паттерны
- **[gems/ruby_llm/](./gems/ruby_llm/)** - AI функциональность
  - README.md - Основная документация
  - examples/ - Примеры использования
  - patterns.md - Архитектурные паттерны

### **Разработка**
- **[development/README.md](./development/README.md)** - Quick start для разработчиков
- **[development/YARD_DOCUMENTATION_STANDARDS.md](./development/YARD_DOCUMENTATION_STANDARDS.md)** - Стандарты документации кода

---

## 🔍 Поиск информации по задачам

### **Telegram-related задачи**
```yaml
primary_source: "gems/telegram-bot/"
examples: "gems/telegram-bot/examples/"
patterns: "gems/telegram-bot/patterns.md"
integration: "CLAUDE.md (раздел Telegram Bot)"
```

### **AI/LLM задачи**
```yaml
primary_source: "gems/ruby_llm/"
examples: "gems/ruby_llm/examples/"
patterns: "gems/ruby_llm/patterns.md"
configuration: "ApplicationConfig"
```

### **Аналитика и метрики**
```yaml
dashboard: "business-metrics.md"
implementation: "analytics/"
sql_examples: "analytics/sql/"
```

### **Бизнес-логика и домен**
```yaml
terminology: "domain/terminology.md"
models: "domain/domain-models.md"
business_rules: "domain/terminology.md#бизнес-правила"
```

### **Требования и разработка**
```yaml
process: "FLOW.md"
user_stories: "requirements/user-stories/"
technical_specs: "requirements/tsd/"
feature_plans: "requirements/fip/"
```

---

## 📋 Карта быстрых ссылок

### **По типу задачи:**
- **Создать User Story:** `requirements/templates/user-story-template.md`
- **Создать TSD:** `requirements/templates/technical-specification-document-template.md`
- **Изучить Telegram:** `gems/telegram-bot/README.md`
- **Изучить AI:** `gems/ruby_llm/README.md`
- **Понять домен:** `domain/terminology.md`

### **По типу документа:**
- **Процессы:** `FLOW.md`, `requirements/README.md`
- **Техническое:** `CLAUDE.md`, `development/`
- **Бизнес:** `product/constitution.md`, `business-metrics.md`
- **Архитектура:** `.claude/memory-bank.md`

---

## 🚨 Правила использования

1. **Всегда начинать с FLOW.md** для новых задач
2. **Проверить CLAUDE.md** перед технической реализацией
3. **Использовать terminology.md** для доменной экспертизы
4. **Смотреть в examples/** перед реализацией паттернов
5. **Проверить templates/** для создания новых документов

---

## 🔄 Обновление и поддержка

**Ответственный:** Documentation-auditor агент
**Частота обновления:** Ежемесячно
**Последняя проверка:** 2025-01-27

---

*Этот документ создан для оптимизации работы AI-агентов с проектом Valera. Основная цель - сократить время поиска информации на 40-60% и устранить 80% противоречий.*