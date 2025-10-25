# 📋 Требования к продукту Valera

**Обновлено:** 25.10.2025
**Статус:** ✅ **Документация готова к разработке (УПРОЩЕННЫЙ ПОДХОД)**

## 🎯 Обзор

Этот каталог содержит **упрощенную структуру требований** для AI-powered Telegram бота Valera, специализирующегося на кузовном ремонте и покраске автомобилей.

**🚀 НОВЫЙ ПОДХОД:** Один документ на функцию (**Feature Implementation Plan**) вместо трех раздельных документов.

## 🚀 Критически важные документы (Обязательно к прочтению)

### 1. **Product Constitution** (`product/constitution.md`)
- **ОБЯЗАТЕЛЬНО К ИЗУЧЕНИЮ ПЕРЕД ЛЮБОЙ РАБОТОЙ**
- Dialogue-Only Interaction (ТОЛЬКО диалог, НИКАКИХ кнопок)
- AI-First Approach (AI как основной интерфейс)
- Visual Analysis Priority (фотоанализ для кузовного ремонта)
- Russian Language Context (русскоязычный контекст)

### 2. **🆕 Новый Flow работы** (`FLOW-NEW.md`) - **КРИТИЧЕСКИ ВАЖНО**
- **Упрощенный подход:** Feature Implementation Plan вместо 3 документов
- Скорость > Бюрократии - от идеи к коду за 2-4 часа
- Практические инструкции и шаблоны

### 3. **Memory Bank** (`../.claude/memory-bank.md`)
- Ключевые архитектурные решения
- Правила для AI-проектов
- Принципы работы Claude

### 4. **План миграции** (`MIGRATION-PLAN.md`)
- Подробная инструкция по переходу к упрощенной документации
- Шаги миграции и критерии успеха
- Rollback план

## 🆕 **НОВАЯ структура документации (УПРОЩЕННАЯ)**

### 📂 `/` - Корень requirements
- **Feature Implementation Plans** - основные документы для разработки
- **User Stories** - исторический контекст (сохраняются)
- **Templates** - шаблон FIP
- **Archive** - старые документы (Technical Specs, Solutions)

### 📂 `FIP-XXX-название.md` - Feature Implementation Plans
**ОСНОВНОЙ документ для разработки:**
- User Story + критерии приемки
- Технический подход и архитектура
- План реализации (фазы, задачи)
- Риски и зависимости
- Тестирование и метрики

### 📂 `/user-stories/` - Исторические User Stories
Формат: `US-XXX-короткое-название.md` (сохраняются для контекста)

### 📂 `/templates/` - Шаблоны
- `feature-implementation-plan-template.md` - **ОСНОВНОЙ шаблон**
- `user-story-template.md` - legacy (не используется)

### 📂 `/_archive/` - Архив старых документов
- `/specifications/` - Technical Specifications (TS-XXX)
- `/technical-solutions/` - Technical Solutions (TSOL-XXX)
- `/old-templates/` - старые шаблоны

## 🔄 **НОВЫЙ процесс работы с требованиями**

### 1. Создание новой функции (УПРОЩЕННЫЙ)
```
Feature Implementation Plan → Implementation
      (2-4 часа)                (сразу)
```

### 2. Когда создавать FIP
- ✅ Новая функция бота
- ✅ Интеграция с сервисом
- ✅ Крупный рефакторинг
- ❌ Small bug fix (< 2 часов)
- ❌ Documentation update

### 3. Версионирование и статус
- **Draft** - черновик
- **In Progress** - в работе
- **Done** - завершено

## 🚀 **Быстрый старт (НОВЫЙ)**

### Создание новой функции:
```bash
# Копируем шаблон FIP
cp docs/requirements/templates/feature-implementation-plan-template.md docs/requirements/FIP-XXX-new-feature.md

# Заполняем User Story и технический подход
# Сразу начинаем реализацию!
```

### Поиск FIP документов:
```bash
# Найти все Feature Implementation Plans
find docs/requirements -name "FIP-*" -type f

# Поиск по содержимому
grep -r "Feature Implementation Plan" docs/requirements/
```

### Проверка статуса:
```bash
# Показать все черновики FIP
grep -l "Status: Draft" docs/requirements/FIP-*.md
```

## 🤖 **Инструкции для AI агента Claude (НОВЫЕ)**

### При создании новой функции:

1. **Автоматически создавать FIP:**
   - Использовать шаблон `templates/feature-implementation-plan-template.md`
   - Создавать уникальный номер (FIP-XXX)
   - Заполнять User Story и технический подход

2. **При планировании разработки:**
   - Читать связанный User Story для контекста (если есть)
   - Следовать плану реализации из FIP
   - Обновлять статус по ходу работы

3. **При обновлении документации:**
   - Обновлять статус FIP при изменениях
   - Добавлять implementation notes
   - Сохранять историю в change log

### Автоматическое определение:

Claude автоматически создает FIP при ключевых словах:
- "создать функцию", "добавить feature", "новая функциональность"
- "спецификация", "требования", "technical solution"
- "реализовать", "разработать", "добавить"
- Complexity > 2 часов

### Исключения (без FIP):
- Small bug fixes (< 2 часов)
- Documentation updates
- Configuration changes
- Code optimization

## 📊 **Метрики нового подхода**

**Target metrics:**
- ⚡ Time to first code: < 4 часов
- 📝 Documentation overhead: < 20% времени
- 🎯 Feature completion rate: > 90%
- 🔄 Iteration speed: 1-2 дня на функцию

## 🔗 Связанные ресурсы

- [CLAUDE.md](../../CLAUDE.md) - Основная документация проекта
- [Gems Documentation](../gems/) - Документация по technical gems
- [Technical Solutions](./technical-solutions/) - Технические решения
- [Project Repository](../../) - Основной код проекта

---

**Последнее обновление:** #{Time.now.strftime('%d.%m.%Y %H:%M')}
**Версия документации:** 1.0