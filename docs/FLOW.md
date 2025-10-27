# 🔄 FLOW работы с документацией

**Обновлено:** 25.10.2025
**Версия:** 3.0 (Streamlined)
**Цель:** От идеи к коду за 3-5 часов без бюрократии

## 🎯 Философия

**User Story + Technical Design Document = Быстрая реализация качественных фич**

- **User Story** - ЧТО хочет пользователь (бизнес-потребность)
- **Technical Design** - КАК реализовать технически
- **Скорость > Бюрократии** - от идеи к коду за 3-5 часов

## 🚀 Quick Navigation

**Что вам нужно?**
- [Создать новую фичу?] → Phase 1: User Story Creation
- [Реализовать технически?] → Phase 2: Technical Design
- [Найти шаблоны?] → Templates section
- [Примеры реализации?] → Examples
- [Когда использовать?] → Usage Guidelines

## 🔄 Процесс работы (3-5 часов)

### Phase 1: User Story Creation (1-2 часа)

```bash
1. Создать из шаблона: docs/requirements/templates/user-story-hybrid-template.md
2. Определить бизнес-потребность
3. Сформулировать User Acceptance Criteria (3 типа)
4. Оценить бизнес-ценность и метрики
5. Сохранить как docs/user-stories/US-XXX-название.md
```

**Результат:** Готовый User Story с четкими критериями приемки

### Phase 2: Technical Design (2-3 часа)

```bash
1. Создать из шаблона: docs/requirements/templates/technical-specification-document-template.md
2. Проанализировать User Story из Phase 1
3. Спроектировать архитектуру и компоненты
4. Определить технические требования (Functional, Performance, Security)
5. Оценить риски и зависимости
6. Составить план реализации
7. Сохранить как docs/requirements/tsd/TSD-XXX-название.md
```

**Результат:** Полный технический план для реализации

### Phase 3: Implementation (сразу)

```bash
1. Следовать плану из TSD
2. Обновлять статусы US-XXX и TSD-XXX
3. Добавлять implementation notes в оба документа
4. Тестировать по чек-листу из TSD
```

**Результат:** Работающая фича с полным описанием процесса

## 🎯 Когда использовать FLOW

### ✅ **Идеально подходит:**
- Новые функции бота
- Интеграции с внешними сервисами
- Крупные рефакторинги
- Проекты с технической сложностью
- Small teams (1-5 человек)

### ❌ **Не подходит:**
- Simple bug fixes (< 1 часа)
- Documentation updates
- Configuration changes
- Очень простые задачи

## 🔄 Выбор подхода: FIP vs US+TSD

Проект использует **оба подхода** в зависимости от типа задачи.

### Когда использовать FIP (Feature Implementation Plan)

**Критерии:**
- ✅ Требуется контекстная документация для будущей поддержки
- ✅ Есть бизнес-логика, требующая обоснования решений
- ✅ НЕ является пользовательской историей (не со стороны пользователя)
- ✅ Любая техническая/внутренняя функциональность

**Примеры:**
- Оптимизация производительности базы данных
- Добавление системы логирования
- Внутренняя фича автоматизации процессов

**Документ:** `FIP-XXX-название.md` в `docs/requirements/`

### Когда использовать US+TSD (User Story + Technical Specification)

**Критерии:**
- ✅ Четкое user story с конкретной пользовательской ценностью
- ✅ Пишется со стороны пользователя ("Как пользователь, я хочу...")
- ✅ Фокус на бизнес-ценности для пользователя
- ✅ Требуется TSD для технической реализации

**Примеры:**
- "Как пользователь, я хочу видеть историю своих заявок"
- "Как клиент, я хочу получать уведомления о статусе ремонта"

**Документы:**
- `US-XXX-название.md` в `docs/requirements/user-stories/`
- `TSD-XXX-название.md` в `docs/requirements/tsd/`

### Структура Implementation Plan

**Для User Story:**
```
US-XXX-название.md (бизнес-потребность)
└── TSD-XXX-название.md (техническая реализация)
    ├── Технические требования
    ├── Архитектура
    └── Implementation Plan (часть TSD)
```

**Для FIP:**
```
FIP-XXX-название.md (полный план реализации)
    ├── Бизнес-обоснование (если нужно)
    ├── Технические требования
    ├── Архитектура
    └── Implementation Plan (встроен в FIP)
```

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

### Практические советы

**Используй FIP когда:**
- Нужно показать "полную картину" технической реализации
- Внутренняя логика системы требует документации
- Будущая поддержка требует понимания технических решений

**Используй US+TSD когда:**
- Четкая пользовательская ценность и история
- Фокус на решении проблемы пользователя
- Нужно отделить бизнес-потребность от технической реализации

## 📋 Templates

### User Story Template
**Расположение:** `docs/requirements/templates/user-story-hybrid-template.md`

**Содержит:**
- User Story формат (As a... I want... So that...)
- User Acceptance Criteria (3 типа)
- Business Value и метрики
- Definition of Done

### Technical Specification Template
**Расположение:** `docs/requirements/templates/technical-specification-document-template.md`

**Содержит:**
- Технические требования (Functional, Performance, Security)
- Архитектура и компоненты
- Implementation Plan (фазы и задачи)
- Риски и зависимости
- План тестирования
- Метрики успеха

## 🗂️ Структура файлов

```
docs/
├── user-stories/              # User Stories (US-XXX)
│   └── US-XXX-название.md
└── requirements/
    ├── tsd/                   # Technical Specification Documents (TSD-XXX)
    │   └── TSD-XXX-название.md
    ├── fip/                   # Feature Implementation Plans (FIP-XXX)
    │   └── FIP-XXX-название.md
    └── templates/             # Шаблоны
        ├── user-story-hybrid-template.md
        └── technical-specification-document-template.md
```

## ✅ Quick Checklist

### Перед созданием User Story:
- [ ] Определить целевого пользователя
- [ ] Понять бизнес-проблему
- [ ] Оценить приоритет и сложность

### Перед созданием Technical Design:
- [ ] Прочитать и понять User Story
- [ ] Определить технические ограничения
- [ ] Оценить зависимости и риски

### Перед реализацией:
- [ ] Оба документа созданы и согласованы
- [ ] План реализации понятен
- [ ] Product Constitution compliance проверен

### После завершения:
- [ ] Все критерии выполнены (US и TSD)
- [ ] Статусы обновлены на "Done"
- [ ] Implementation notes добавлены
- [ ] Документация актуализирована

## 📊 Метрики FLOW подхода

**Target metrics:**
- ⚡ **Time to first code:** < 5 часов (1-2 часа US + 2-3 часа TSD)
- 📝 **Documentation overhead:** < 25% времени
- 🎯 **Feature completion rate:** > 95%
- 🔄 **Iteration speed:** 1-2 дня на функцию
- 📈 **User satisfaction:** ↑ (четкий фокус на потребностях)
- 🏗️ **Technical quality:** ↑ (глубокая проработка)

---

## 🔗 Связанные документы

- **[Product Constitution](product/constitution.md)** - ОБЯЗАТЕЛЬНО перед началом
- **[Memory Bank](../.claude/memory-bank.md)** - Архитектурные решения
- **[Gems Documentation](gems/)** - ruby_llm и telegram-bot
- **[Requirements Overview](requirements/README.md)** - Детали структуры

---

**Flow Principle:** Этот документ = единственный источник правды по процессу работы с документацией