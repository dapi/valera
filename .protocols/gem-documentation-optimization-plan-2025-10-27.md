# Gem Documentation Optimization Plan

**Дата создания:** 27.10.2025
**Статус:** 📋 Planned
**Приоритет:** Критичный (дублирование gem документации)

---

## 🎯 Проблема

**Дублирование gem документации между `.claude/` и `docs/gems/`:**

### Текущая ситуация:
- `.claude/telegram-bot-learning.md` (165 строк) + `.claude/telegram-checklist.md` (165 строк)
- `.claude/ruby_llm-learning.md` (150+ строк) + `.claude/ruby_llm-checklist.md` (185 строк)
- **Итого:** ~665 строк избыточной документации

### Проблемы:
1. **Дублирование последовательностей изучения** в learning protocols и checklists
2. **Повторяющиеся ссылки** на docs/gems/ в нескольких местах
3. **Избыточный объем** - сложная навигация для AI
4. **Неэффективное использование контекста** - лишняя информация

---

## 🚀 Оптимизированная структура

### Шаг 1: Объединить в `.claude/`

**Telegram:**
- `telegram-bot-learning.md` + `telegram-checklist.md` → `telegram-bot-protocol.md`
- **Сокращение:** с 330 строк до ~150 строк (55% reduction)

**Ruby LLM:**
- `ruby_llm-learning.md` + `ruby_llm-checklist.md` → `ruby_llm-protocol.md`
- **Сокращение:** с 335 строк до ~150 строк (55% reduction)

### Шаг 2: Структура unified protocols

```markdown
# [Gem] Protocol for Claude

## 🎯 Objective
Краткая цель протокола для AI

## 🔄 Auto-Learning Triggers
Ключевые слова и файлы для авто-активации

## 📚 Study Sequence (5 + 10 + 10 + 15 min)
- Core Documentation (5 min)
- API Reference (10 min)
- Architecture Patterns (10 min)
- Code Examples (15 min)

## ✅ Pre-Work Checklist (компактный)
- Documentation Study Completed
- Current Implementation Analyzed
- Knowledge Validation Passed
- Task Preparation Complete

## 🧠 Knowledge Validation
Ключевые вопросы для проверки понимания

## ⚡ Quick Reference
Таблицы: Common Tasks → Documentation, Error Codes → Documentation

## 🔄 Refresh Schedule
График обновлений знаний
```

### Шаг 3: Удалить избыточность

**Что убрать:**
- Повторяющиеся ссылки на docs/gems/
- Длинные описания последовательностей
- Избыточные пояснения и примеры
- Дублирующиеся секции timeout/schedule

**Что сохранить:**
- Auto-learning triggers (критично для AI)
- Quick reference таблицы
- Knowledge validation вопросы
- Essential ссылки на документацию

---

## 📋 План реализации

### Phase 1: Создание unified protocols
1. Создать `telegram-bot-protocol.md`
2. Создать `ruby_llm-protocol.md`
3. Объединить лучшее содержание из существующих документов

### Phase 2: Удаление избыточности
1. Удалить `telegram-bot-learning.md`
2. Удалить `telegram-checklist.md`
3. Удалить `ruby_llm-learning.md`
4. Удалить `ruby_llm-checklist.md`

### Phase 3: Валидация
1. Проверить что все essential функции сохранены
2. Убедиться что ссылки работают
3. Проверить что AI protocols остаются функциональными

---

## 🎯 Ожидаемые результаты

### Количественные метрики:
- **Сокращение объема:** ~400 строк (60% reduction)
- **Количество документов:** с 4 до 2 в `.claude/`
- **Размер каждого protocol:** ~150 строк

### Качественные улучшения:
- **Устранение дублирования** - Single source of truth для каждого gem
- **Четкая структура** - легко navigable для AI
- **Эффективный контекст** - только существенная информация
- **Быстрый доступ** - quick reference таблицы сохранены

### Сохраненная функциональность:
- ✅ Auto-learning triggers
- ✅ Knowledge validation
- ✅ Quick reference tables
- ✅ Links to docs/gems/
- ✅ Refresh schedules
- ✅ Pre-work checklists (compact)

---

## 🔗 Связанные документы

- [Gem Documentation](../docs/gems/) - Полная документация
- [Memory Bank](../.claude/memory-bank.md) - Архитектурные принципы
- [Claude Instructions](../CLAUDE.md) - Основная документация проекта

---

**Версия:** 1.0
**Дата создания:** 27.10.2025
**Тип документа:** Optimization Plan
**Ответственный:** Tech Lead / AI Agent

## 📝 Implementation Notes

### Critical Success Factors:
1. **Сохранить auto-learning functionality** - это критично для AI агента
2. **Быстрые reference таблицы** - нужны для эффективной работы
3. **Четкие ссылки на docs/gems/** - основной источник правды
4. **Validation вопросы** - обеспечить качество работы AI

### Risk Mitigation:
- **Backup существующих документов** перед удалением
- **Пошаговая валидация** после каждого изменения
- **Тестирование AI functionality** после оптимизации