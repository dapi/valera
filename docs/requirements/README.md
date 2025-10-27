# 📋 Требования к продукту Valera

**Обновлено:** 25.10.2025
**Статус:** ✅ **Документация готова к разработке (FLOW-based подход)**

## 🎯 Обзор

Этот каталог содержит **структуру требований** для AI-powered Telegram бота Valera, специализирующегося на кузовном ремонте и покраске автомобилей.

**🚀 FLOW ПОДХОД:** User Story (фокус на пользователе) + Technical Specification Document (фокус на реализации).

## 🚀 Критически важные документы (Обязательно к прочтению)

### 1. **Product Constitution** (`../docs/product/constitution.md`)
**ОБЯЗАТЕЛЬНО К ИЗУЧЕНИЮ!** Критичные принципы: Dialogue-Only Interaction, AI-First Approach.
→ [Полная информация](../docs/product/constitution.md)

### 2. **🔄 FLOW** (`../FLOW.md`) - **КРИТИЧЕСКИ ВАЖНО**
- **Двухдокументный подход:** User Story + Technical Specification Document
- Фокус на пользователе + техническая глубина
- От идеи к коду за 3-5 часов

### 3. **Memory Bank** (`../.claude/memory-bank.md`)
- Ключевые архитектурные решения
- Правила для AI-проектов
- Принципы работы Claude


## 📋 **FLOW структура документации**

### 📂 **Текущая структура:**

#### 📝 **User Stories** (`docs/requirements/user-stories/`)
Фокус на потребностях пользователя:
- User Story (As a... I want... So that...)
- User Acceptance Criteria (3 типа)
- Business Value и метрики
- Definition of Done
- 🔗 Связь с TSD-XXX

#### 🏗️ **Technical Specification Documents** (`docs/requirements/tsd/`)
Фокус на технической реализации:
- Технические требования (Functional, Performance, Security)
- Архитектура и компоненты
- Implementation Plan (фазы и задачи)
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
- `technical-specification-document-template.md` - **ОСНОВНОЙ шаблон TSD**

## 🔄 Процесс разработки функции

**🚀 ПОЛНЫЙ ПРОЦЕСС:** [FLOW.md](../FLOW.md) - **читай это перед созданием новой функции!**

Процесс разработки состоит из трех этапов:
1. **User Story** (1-2 часа) → `docs/requirements/user-stories/US-XXX.md` - фокус на потребностях пользователя
2. **Technical Specification** (2-3 часа) → `docs/requirements/tsd/TSD-XXX.md` - техническая реализация
3. **Implementation** - разработка согласно плану в TSD

**Исключения (без US+TDD):** Simple bug fixes (< 1 часа), Documentation updates, Configuration changes, Small refactors (< 2 часов)

Детально о процессе, статусах, вариативности и примерах см. в [FLOW.md](../FLOW.md).

## 🔄 FIP vs US+TSD подходы

### FIP (Feature Implementation Plan)
Используется для внутренней/технической функциональности, не связанной с пользовательскими историями.
- Любая техническая/внутренняя функциональность
- Требует контекстной документации для будущей поддержки
- Implementation Plan встроен в FIP

**Формат:** `FIP-XXX-название.md` в `docs/requirements/`

### US+TSD (User Story + Technical Specification)
Используется для пользовательских историй с четкой бизнес-ценностью.
- Четкое user story со стороны пользователя ("Как пользователь, я хочу...")
- Фокус на бизнес-ценности для пользователя
- TSD включает Implementation Plan

**Формат:**
- `US-XXX-название.md` в `docs/requirements/user-stories/`
- `TSD-XXX-название.md` в `docs/requirements/tsd/`

### Decision Tree
```
Новая задача
    │
    ├─ Это пользовательская история со стороны пользователя?
    │   └─ [ДА] → US + TSD
    │        ├── US: "Как пользователь, я хочу..."
    │        └── TSD: Техническая спецификация + Implementation Plan
    │
    └─ Это внутренняя/техническая функциональность?
        └─ [ДА] → FIP (Implementation Plan встроен)
```

## 🔗 Связанные ресурсы

- [CLAUDE.md](../../CLAUDE.md) - Основная документация проекта
- [Gems Documentation](../gems/) - Документация по technical gems
- [Technical Solutions](./technical-solutions/) - Технические решения
- [Project Repository](../../) - Основной код проекта

---

**Последнее обновление:** 26.10.2025
**Версия документации:** 1.0
**Тип документа:** HOW (Практические инструкции)

📈 **[Метрики использования](../docs-usage-metrics.md#docsrequirementsreadmemd)** - см. централизованный документ метрик