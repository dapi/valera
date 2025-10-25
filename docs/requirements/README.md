# 📋 Требования к продукту Valera

**Обновлено:** 25.10.2025
**Статус:** ✅ **Документация готова к разработке (FLOW-based подход)**

## 🎯 Обзор

Этот каталог содержит **структуру требований** для AI-powered Telegram бота Valera, специализирующегося на кузовном ремонте и покраске автомобилей.

**🚀 FLOW ПОДХОД:** User Story (фокус на пользователе) + Technical Design Document (фокус на реализации).

## 🚀 Критически важные документы (Обязательно к прочтению)

### 1. **Product Constitution** (`product/constitution.md`)
- **ОБЯЗАТЕЛЬНО К ИЗУЧЕНИЮ ПЕРЕД ЛЮБОЙ РАБОТОЙ**
- Dialogue-Only Interaction (ТОЛЬКО диалог, НИКАКИХ кнопок)
- AI-First Approach (AI как основной интерфейс)
- Visual Analysis Priority (фотоанализ для кузовного ремонта)
- Russian Language Context (русскоязычный контекст)

### 2. **🔄 FLOW** (`../FLOW.md`) - **КРИТИЧЕСКИ ВАЖНО**
- **Двухдокументный подход:** User Story + Technical Design Document
- Фокус на пользователе + техническая глубина
- От идеи к коду за 3-5 часов

### 3. **Memory Bank** (`../.claude/memory-bank.md`)
- Ключевые архитектурные решения
- Правила для AI-проектов
- Принципы работы Claude


## 📋 **FLOW структура документации**

### 📂 **Текущая структура:**

#### 📝 **User Stories** (`../user-stories/`)
Фокус на потребностях пользователя:
- User Story (As a... I want... So that...)
- User Acceptance Criteria (3 типа)
- Business Value и метрики
- Definition of Done
- 🔗 Связь с TDD-XXX

#### 🏗️ **Technical Design Documents** (`../tdd/`)
Фокус на технической реализации:
- Технические требования (Functional, Performance, Security)
- Архитектура и компоненты
- План реализации (фазы и задачи)
- Риски и зависимости
- Тестирование и метрики
- 🔗 Связь с US-XXX

#### 📂 **Остальные каталоги:**
- **Templates** (`templates/`) - FLOW шаблоны
- **API** (`api/`) - API документация
- **Features** (`features/`) - описания функций
- **Backlog** (`backlog/`) - бэклог задач

### 📂 `/user-stories/` - User Stories
Формат: `US-XXX-короткое-название.md`

### 📂 `/templates/` - FLOW шаблоны
- `user-story-hybrid-template.md` - **ОСНОВНОЙ шаблон User Story**
- `technical-design-document-template.md` - **ОСНОВНОЙ шаблон TDD**

## 🔄 **FLOW процесс работы с требованиями**

### 1. Создание новой функции (FLOW)
```
User Story (1-2 часа) → Technical Design Document (2-3 часа) → Implementation
```

### 2. Когда использовать FLOW подход
- ✅ Новая функция бота
- ✅ Интеграция с сервисом
- ✅ Крупный рефакторинг
- ✅ Проекты с технической сложностью
- ❌ Small bug fix (< 1 часа)
- ❌ Documentation update

### 3. Версионирование и статус
- **Draft** - черновик
- **Approved** - одобрено
- **In Progress** - в работе
- **Done** - завершено

## 🚀 **Быстрый старт (ГИБРИДНЫЙ)**

### Создание новой функции:
```bash
# Шаг 1: Создать User Story
cp docs/requirements/templates/user-story-hybrid-template.md docs/user_stories/US-XXX-new-feature.md

# Шаг 2: Создать Technical Design Document
cp docs/requirements/templates/technical-design-document-template.md docs/tdd/TDD-XXX-new-feature.md

# Шаг 3: Заполнить оба документа и начать реализацию!
```

### Поиск документов:
```bash
# Найти все User Stories
find docs/user_stories -name "US-*" -type f

# Найти все Technical Design Documents
find docs/tdd -name "TDD-*" -type f

# Поиск по содержимому
grep -r "User Story\|Technical Design" docs/user_stories/ docs/tdd/
```

### Проверка статуса:
```bash
# Показать все черновики
grep -l "Status: Draft" docs/user_stories/US-*.md docs/tdd/TDD-*.md
```

## 🤖 **Инструкции для AI агента Claude (ГИБРИДНЫЕ)**

### При создании новой функции:

1. **Автоматически создавать User Story + TDD:**
   - Использовать шаблон `templates/user-story-hybrid-template.md`
   - Использовать шаблон `templates/technical-design-document-template.md`
   - Создавать связанную пару (US-XXX + TDD-XXX)
   - Заполнять User Story и технический подход

2. **При планировании разработки:**
   - Читать связанный User Story для контекста
   - Следовать плану реализации из TDD
   - Обновлять статусы обоих документов

3. **При обновлении документации:**
   - Обновлять статусы US и TDD при изменениях
   - Добавлять implementation notes в оба документа
   - Поддерживать связи между документами

### Автоматическое определение:

Claude автоматически создает User Story + TDD при ключевых словах:
- "создать функцию", "добавить feature", "новая функциональность"
- "спецификация", "требования", "technical solution"
- "реализовать", "разработать", "добавить"
- Complexity > 1 час

### Исключения (без US+TDD):
- Small bug fixes (< 1 часа)
- Documentation updates
- Configuration changes
- Code optimization

## 📊 **Метрики гибридного подхода**

**Target metrics:**
- ⚡ Time to first code: < 5 часов (1-2 часа US + 2-3 часа TDD)
- 📝 Documentation overhead: < 25% времени
- 🎯 Feature completion rate: > 95%
- 🔄 Iteration speed: 1-2 дня на функцию
- 🎯 User satisfaction: ↑ (четкий фокус на потребностях)
- 🏗️ Technical quality: ↑ (глубокая проработка)

## 🔗 Связанные ресурсы

- [CLAUDE.md](../../CLAUDE.md) - Основная документация проекта
- [Gems Documentation](../gems/) - Документация по technical gems
- [Technical Solutions](./technical-solutions/) - Технические решения
- [Project Repository](../../) - Основной код проекта

---

**Последнее обновление:** #{Time.now.strftime('%d.%m.%Y %H:%M')}
**Версия документации:** 1.0