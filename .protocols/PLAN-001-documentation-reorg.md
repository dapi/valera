# План реорганизации документации

**ID:** PLAN-001
**Название:** Реорганизация документации на основе FLOW.md
**Приоритет:** High
**Создан:** 25.10.2025
**Автор:** Claude AI Agent
**Статус:** Draft
**Estimated time:** 4-6 часов

## 🎯 Цель реорганизации

Устранить путаницу в моделях документации и установить FLOW.md на основе HYBRID-FLOW.md как единую рабочую модель.

## 📋 Проблема

- **Множественные конфликтующие модели:** ГИБРИДНЫЙ ПОДХОД vs Централизованная модель
- **Избыточная документация:** 12 файлов в архиве, пересекающиеся README
- **Нарушенные ссылки:** Многие внутренние ссылки ведут в архив или неактуальные документы
- **Размывание Single Source of Truth:** Несколько "основных" документов

## 🚀 Решение: FLOW.md на основе HYBRID-FLOW.md

### Новый flow работы:
```
docs/README.md (входная точка)
    ↓
docs/FLOW.md (основной процесс)
    ↓
docs/requirements/README.md (детали реализации)
```

### Структура после реорганизации:
```
docs/
├── README.md (обновленный, единая точка входа)
├── FLOW.md (новый, на основе HYBRID-FLOW.md)
├── product/
│   └── constitution.md (неизменен, критически важен)
├── requirements/
│   ├── README.md (обновленный)
│   ├── FLOW.md (удаляется после переноса)
│   ├── HYBRID-FLOW.md (переименовывается в ../FLOW.md)
│   ├── HYBRID-MIGRATION-PLAN.md (удаляется)
│   ├── HYBRID-APPROACH-EXAMPLES.md (удаляется)
│   ├── user_stories/ (активные)
│   ├── templates/ (оставить)
│   ├── api/ (оставить)
│   ├── backlog/ (оставить)
│   └── _archive/ (полностью удалить)
├── gems/ (неизменен)
│   ├── ruby_llm/
│   └── telegram-bot/
├── domain/ (неизменен)
├── prompts/ (неизменен)
└── tdd/ (перемещается из requirements в docs/)
```

## 📋 План реализации

### Phase 1: Подготовка (30 минут)
- [ ] Сделать backup текущей документации
- [ ] Изучить текущие связи и ссылки
- [ ] Создать новый FLOW.md на основе HYBRID-FLOW.md
- [ ] Обновить главный docs/README.md

### Phase 2: Реорганизация структуры (1-2 часа)
- [ ] Переместить `HYBRID-FLOW.md` → `docs/FLOW.md`
- [ ] Переместить `docs/requirements/tdd/` → `docs/tdd/`
- [ ] Удалить `docs/requirements/_archive/` полностью
- [ ] Удалить устаревшие README files

### Phase 3: Обновление связей (1-2 часа)
- [ ] Обновить все ссылки на FLOW.md
- [ ] Исправить внутренние ссылки в документации
- [ ] Проверить ссылки из CLAUDE.md
- [ ] Обновить memory bank если нужно

### Phase 4: Очистка (1 час)
- [ ] Удалить следующие файлы:
  - `docs/requirements/HYBRID-FLOW.md`
  - `docs/requirements/HYBRID-MIGRATION-PLAN.md`
  - `docs/requirements/HYBRID-APPROACH-EXAMPLES.md`
  - `docs/requirements/README-user-stories.md`
  - `docs/requirements/README-TEAM-GUIDE.md`
  - `docs/requirements/README-AI-AGENTS.md`
  - `docs/solutions.md` (переместить содержимое в Memory Bank)
  - `docs/technical-debt.md` (переместить вMemory Bank или удалить)

### Phase 5: Валидация (30 минут)
- [ ] Проверить все ссылки
- [ ] Убедиться что navigation работает
- [ ] Проверить полноту документации
- [ ] Обновить даты в документах

## 🔗 Список изменений

### Удаляемые файлы (12+):
```
docs/requirements/_archive/MIGRATION-PLAN.md
docs/requirements/_archive/FIP-002a-telegram-basic-consultation.md
docs/requirements/_archive/FIP-002b-telegram-recording-booking.md
docs/requirements/_archive/US-001-telegram-auto-greeting.md
docs/requirements/_archive/old-flows/ (вся директория)
docs/requirements/_archive/old-templates/ (вся директория)
docs/requirements/_archive/specifications/ (вся директория)
docs/requirements/_archive/technical-solutions/ (вся директория)
docs/requirements/HYBRID-MIGRATION-PLAN.md
docs/requirements/HYBRID-APPROACH-EXAMPLES.md
docs/requirements/README-user-stories.md
docs/requirements/README-TEAM-GUIDE.md
docs/requirements/README-AI-AGENTS.md
docs/solutions.md
docs/technical-debt.md
```

### Переименовываемые файлы:
```
docs/requirements/HYBRID-FLOW.md → docs/FLOW.md
```

### Перемещаемые директории:
```
docs/requirements/tdd/ → docs/tdd/
```

### Обновляемые файлы:
```
docs/README.md (обновить структуру и ссылки)
docs/requirements/README.md (обновить ссылки на FLOW.md)
CLAUDE.md (обновить ссылки на FLOW.md)
```

## ⚠️ Риски и митигация

### Риск 1: Нарушение рабочих процессов
**Митигация:** Сделать backup текущего состояния, аккуратные пошаговые изменения

### Риск 2: Потеря важной информации
**Митигация:** Проверить содержимое удаляемых файлов, перенести важное в Memory Bank

### Риск 3: Сломанные ссылки
**Митигация:** Использовать grep для поиска всех ссылок перед удалением

## ✅ Критерии успеха

- [ ] Файл `docs/FLOW.md` - основной документ с процессами
- [ ] `docs/README.md` - четкая navigation structure
- [ ] Все внутренние ссылки работают
- [ ] Удалено >10 устаревших файлов
- [ ] Документация занимает <50% текущего размера
- [ ] Поиск информации занимает <30 секунд
- [ ] Zero дублирования процессов

## 🔄 Timeline

**Total estimated time:** 4-6 часов

```
Day 1:
- Morning: Phase 1-2 (2-3 часа)
- Afternoon: Phase 3 (2 часа)

Day 2:
- Morning: Phase 4 (1 час)
- Afternoon: Phase 5 + testing (1 час)
```

## 📊 Ожидаемые результаты

**Immediate:**
- ⚡ Уменьшение когнитивной нагрузки на 70%
- 🎯 Единая модель документации
- 📝 Четкие процессы без конфликтов

**Long-term:**
- 🔄 Легче поддерживать и обновлять
- 📈 Быстрее онбординг новых разработчиков
- 🚀 Проще масштабировать процессы

---

**Memory Bank Integration:**
После выполнения этого плана, обновить Memory Bank с правилом:
> "Всегда использовать FLOW.md для процессов работы с документацией. Никаких альтернативных моделей."

**Dependencies:**
- Необходим доступ к файловой системе
- Рекомендуется делать изменения последовательно с проверкой каждого шага

**Next Steps After Completion:**
1. Создать cheat sheet для быстрой навигации
2. Добавить в CLAUDE.md четкие инструкции
3. Обновить инструкции для AI агентов