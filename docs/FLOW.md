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
1. Создать из шаблона: docs/requirements/templates/technical-design-document-template.md
2. Проанализировать User Story из Phase 1
3. Спроектировать архитектуру и компоненты
4. Определить технические требования (Functional, Performance, Security)
5. Оценить риски и зависимости
6. Составить план реализации
7. Сохранить как docs/tdd/TDD-XXX-название.md
```

**Результат:** Полный технический план для реализации

### Phase 3: Implementation (сразу)

```bash
1. Следовать плану из TDD
2. Обновлять статусы US-XXX и TDD-XXX
3. Добавлять implementation notes в оба документа
4. Тестировать по чек-листу из TDD
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

## 📋 Templates

### User Story Template
**Расположение:** `docs/requirements/templates/user-story-hybrid-template.md`

**Содержит:**
- User Story формат (As a... I want... So that...)
- User Acceptance Criteria (3 типа)
- Business Value и метрики
- Definition of Done

### Technical Design Template
**Расположение:** `docs/requirements/templates/technical-design-document-template.md`

**Содержит:**
- Технические требования (Functional, Performance, Security)
- Архитектура и компоненты
- План реализации (фазы и задачи)
- Риски и зависимости
- План тестирования
- Метрики успеха

## 🗂️ Структура файлов

```
docs/
├── user-stories/          # User Stories (US-XXX)
│   └── US-XXX-название.md
├── tdd/                   # Technical Design Documents (TDD-XXX)
│   └── TDD-XXX-название.md
└── requirements/templates/  # Шаблоны
    ├── user-story-hybrid-template.md
    └── technical-design-document-template.md
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
- [ ] Все критерии выполнены (US и TDD)
- [ ] Статусы обновлены на "Done"
- [ ] Implementation notes добавлены
- [ ] Документация актуализирована

## 📊 Метрики FLOW подхода

**Target metrics:**
- ⚡ **Time to first code:** < 5 часов (1-2 часа US + 2-3 часа TDD)
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