# 📋 Требования к продукту Valera

**Обновлено:** 25.10.2025
**Статус:** ✅ **Документация готова к разработке (FLOW-based подход)**

## 🎯 Обзор

Этот каталог содержит **структуру требований** для AI-powered Telegram бота Valera, специализирующегося на кузовном ремонте и покраске автомобилей.

**🚀 FLOW ПОДХОД:** User Story (фокус на пользователе) + Technical Design Document (фокус на реализации).

## 🚀 Критически важные документы (Обязательно к прочтению)

### 1. **Product Constitution** (`../docs/product/constitution.md`)
**ОБЯЗАТЕЛЬНО К ИЗУЧЕНИЮ!** Критичные принципы: Dialogue-Only Interaction, AI-First Approach.
→ [Полная информация](../docs/product/constitution.md)

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

#### 📝 **User Stories** (`docs/requirements/user-stories/`)
Фокус на потребностях пользователя:
- User Story (As a... I want... So that...)
- User Acceptance Criteria (3 типа)
- Business Value и метрики
- Definition of Done
- 🔗 Связь с TDD-XXX

#### 🏗️ **Technical Design Documents** (`docs/requirements/tdd/`)
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

## 🔄 Процесс разработки функции

**🚀 ПОЛНЫЙ ПРОЦЕСС:** [FLOW.md](../FLOW.md) - **читай это перед созданием новой функции!**

**Quick Summary (TL;DR):**
1. Создать User Story (1-2 часа) → `docs/requirements/user-stories/US-XXX.md`
2. Создать Technical Design (2-3 часа) → `docs/requirements/tdd/TDD-XXX.md`
3. Начать реализацию согласно плану в TDD

**Исключения (без US+TDD):**
- Simple bug fixes (< 1 часа)
- Documentation updates
- Configuration changes
- Small refactors (< 2 часов)

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

**Последнее обновление:** 26.10.2025
**Версия документации:** 1.0
**Тип документа:** HOW (Практические инструкции)

## 📈 Метрики использования

- **Среднее время чтения:** ~15 минут
- **Целевая аудитория:** Разработчики, Product Owner, AI Agents
- **Частота обращений:** 3-5 раз в неделю
- **Критичность:** 🟠 Средняя
- **Статус:** ✅ Актуально
- **Следующий пересмотр:** 26.01.2026