# 🔄 FLOW работы с документацией

**Обновлено:** 27.10.2025
**Версия:** 4.0 (Optimized)
**Цель:** От идеи к коду за 3-5 часов без бюрократии

## 🎯 Философия

**User Story + Technical Design Document = Быстрая реализация качественных фич**

- **User Story** - ЧТО хочет пользователь (бизнес-потребность)
- **Technical Design** - КАК реализовать технически
- **Скорость > Бюрократии** - от идеи к коду за 3-5 часов

## 🔄 Процесс работы (3-5 часов)

### Phase 1: User Story Creation (1-2 часа)
1. Создать из шаблона: `docs/requirements/templates/user-story-hybrid-template.md`
2. Определить бизнес-потребность и User Acceptance Criteria
3. Оценить бизнес-ценность и метрики
4. Сохранить как `docs/requirements/user-stories/US-XXX-название.md`

### Phase 2: Technical Design (2-3 часа)
1. Создать из шаблона: `docs/requirements/templates/technical-specification-document-template.md`
2. Спроектировать архитектуру и технические требования
3. Составить план реализации и оценить риски
4. Сохранить как `docs/requirements/tsd/TSD-XXX-название.md`

### Phase 3: Implementation
1. Следовать плану из TSD
2. Обновлять статусы US-XXX и TSD-XXX
3. Добавлять implementation notes в оба документа

## 🎯 Когда использовать FLOW

**✅ Идеально подходит:**
- Новые функции бота, интеграции, рефакторинги
- Small teams (1-5 человек)

**❌ Не подходит:**
- Simple bug fixes (< 1 часа), documentation updates, configuration changes

## 🔄 Выбор подхода: FIP vs US+TSD

### FIP (Feature Implementation Plan)
**Когда использовать:** Внутренняя/техническая функциональность
- Оптимизация производительности базы данных
- Добавление системы логирования
- Документ: `FIP-XXX-название.md` в `docs/requirements/`

### US+TSD (User Story + Technical Specification)
**Когда использовать:** Четкая пользовательская история ("Как пользователь, я хочу...")
- "Как пользователь, я хочу видеть историю своих заявок"
- Документы: `US-XXX-название.md` + `TSD-XXX-название.md`

**Decision Tree:**
```
Новая задача → Пользовательская история? → [ДА] US+TSD : [НЕТ] FIP
```

## 📋 Templates и структура

**Templates:** `docs/requirements/templates/`
- User Story: business-потребность + acceptance criteria
- Technical Design: архитектура + implementation plan

**Quick Checklist:**
- Перед US: определить пользователя и бизнес-проблему
- Перед TSD: прочитать US, оценить технические риски
- После: обновить статусы, добавить implementation notes

## 📊 Метрики

**Target:** < 5 часов до кода, < 25% времени на документацию, > 95% completion rate

---

## 🔗 Связанные документы

- **[Product Constitution](product/constitution.md)** - ОБЯЗАТЕЛЬНО перед началом
- **[Memory Bank](../.claude/memory-bank.md)** - Архитектурные решения
- **[Gems Documentation](gems/)** - ruby_llm и telegram-bot
- **[Requirements Overview](requirements/README.md)** - Детали структуры

---

**Flow Principle:** Единственный источник правды по процессу работы с документацией