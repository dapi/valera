# 📋 Требования к продукту Valera

**Обновлено:** 27.10.2025
**Процесс:** FLOW-based подход (User Story + TSD)

## 🎯 Критически важные документы

1. **[Product Constitution](../product/constitution.md)** - ОБЯЗАТЕЛЬНО! Dialogue-Only Interaction, AI-First Approach
2. **[FLOW.md](../FLOW.md)** - КРИТИЧЕСКИ ВАЖНО! Полный процесс разработки
3. **[Architecture Decisions](../architecture/decisions.md)** - Архитектурные решения и принципы

## 📂 Структура каталогов

- **user-stories/** - Потребности пользователей (`US-XXX-название.md`)
- **tsd/** - Технические спецификации (`TSD-XXX-название.md`)
- **templates/** - Шаблоны документов
- **fip/** - Feature Implementation Plans (внутренняя функциональность)
- **pr/** - Продуктовые требования (`PR-XXX-название.md`)
- **api/** - API документация (`api-название-vX.md`)

## 🔄 Подходы к разработке

### US+TSD (User Story + Technical Specification)
Для пользовательских историй: `"Как пользователь, я хочу..."` + техническая реализация

### FIP (Feature Implementation Plan)
Для внутренней/технической функциональности с встроенным Implementation Plan

## 🔗 Связанные ресурсы

- **[INDEX.md](../INDEX.md)** - Навигация по документации
- **[business-metrics.md](../product/business-metrics.md)** - KPI и цели проекта
- **[gems/](../gems/)** - Техническая документация

## 📊 Статусы документов

### Основные статусы
- **Draft** 📝 - Черновик, находится в разработке
- **Ready for Development** ✅ - Готов к реализации
- **In Progress** 🚧 - В процессе разработки
- **Completed** ✅ - Завершен и протестирован
- **Approved** ✅ - Утвержден к реализации
- **Production** 🚀 - В продакшене

### Расширенные статусы
- **Ready for Implementation** 🟡 - Готов к реализации (технические документы)
- **Ready for Review** 👀 - Готов к проверке
- **Archived** 📦 - Архивный документ (использовать `[DEPRECATED]` в названии)

### Правила использования статусов
1. **Документы не архивируются** - вместо этого используется префикс `[DEPRECATED]`
2. **Статусы обновляются в процессе работы** - Draft → In Progress → Completed
3. **Апгрейд статусов** возможен только вперед по workflow
4. **Финальный статус** для активных документов - Completed или Production

## Другие форматы требований

- PDR
- Feature Brief: Краткое описание функции (1-2 абзаца)
- Technical Specification: Детальные технические спецификации
- User Story Map: Карта пользовательских историй
- Epic Breakdown: Декомпозиция эпиков на задачи

---

**📋 Полный процесс:** см. [FLOW.md](../FLOW.md)
