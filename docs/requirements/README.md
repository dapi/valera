# 📋 Требования к продукту Valera

**Обновлено:** 25.10.2025
**Статус:** ✅ **Документация готова к разработке (FLOW-based подход)**

## 🎯 Обзор

Этот каталог содержит **структуру требований** для AI-powered Telegram бота Valera, специализирующегося на кузовном ремонте и покраске автомобилей.

**🚀 FLOW ПОДХОД:** См. **[../FLOW.md](../FLOW.md)** - процесс разработки (User Story + Technical Specification Document).

## 🚀 Критически важные документы (Обязательно к прочтению)

### 1. **Product Constitution** (`../product/constitution.md`)
**ОБЯЗАТЕЛЬНО К ИЗУЧЕНИЮ!** Критичные принципы: Dialogue-Only Interaction, AI-First Approach.
→ [Полная информация](../product/constitution.md)

### 2. **🔄 FLOW** (`../FLOW.md`) - **КРИТИЧЕСКИ ВАЖНО**
- **Двухдокументный подход:** User Story + Technical Specification Document
- Фокус на пользователе + техническая глубина
- От идеи к коду за 3-5 часов

### 3. **Memory Bank** (`../.claude/memory-bank.md`)
- Ключевые архитектурные решения
- Правила для AI-проектов
- Принципы работы Claude


## 📋 **Структура документации**

Подробное описание процесса и структуры в **[../FLOW.md](../FLOW.md)**

### 📂 **Основные каталоги:**
- **User Stories** (`user-stories/`) - Потребности пользователей
- **Technical Specs** (`tsd/`) - Техническая реализация
- **Templates** (`templates/`) - Шаблоны документов
- **FIP** (`fip/`) - Feature Implementation Plans
- **Product Requirements** (`pr/`) - Продуктовые требования
- **API Specifications** (`api/`) - API документация

### 📂 `/user-stories/` - User Stories
Формат: `US-XXX-короткое-название.md`

**📋 Текущие User Stories:**
- **US-001** - Telegram Auto Greeting (базовое приветствие)
- **US-002a** - Telegram Basic Consultation (консультация по стоимости)
- **US-002b** - Telegram Recording + Booking (запись на сервис)
- **US-003** - Telegram Photo Damage Assessment (оценка повреждений по фото)
- **US-004** - Telegram Insurance Automation (автоматизация страховки)
- **US-005** - Telegram Booking Confirmation (подтверждение записи)

### 📂 `/templates/` - FLOW шаблоны
- `user-story-template.md` - **ОСНОВНОЙ шаблон User Story**
- `user-story-examples.md` - Примеры User Story по типам функций
- `technical-specification-document-template.md` - **ОСНОВНОЙ шаблон TSD`

### 📂 `/pr/` - Product Requirements
Формат: `PR-XXX-название.md`
- Продуктовые требования высокого уровня
- Бизнес-требования и спецификации

### 📂 `/api/` - API Specifications
Формат: `api-название-vX.md`
- Спецификации API
- Документация endpoint'ов
- Контракты интеграции

## 🔄 Процесс разработки

**🚀 ПОЛНЫЙ ПРОЦЕСС:** См. **[../FLOW.md](../FLOW.md)**

Детально о процессе, статусах, вариативности и примерах см. в [FLOW.md](../FLOW.md).

## 🔄 FIP vs US+TSD подходы

### FIP (Feature Implementation Plan)
Используется для внутренней/технической функциональности, не связанной с пользовательскими историями.
- Любая техническая/внутренняя функциональность
- Требует контекстной документации для будущей поддержки
- Implementation Plan встроен в FIP

**Формат:** `FIP-XXX-название.md` в корне `docs/requirements/`

### US+TSD (User Story + Technical Specification)
Используется для пользовательских историй с четкой бизнес-ценностью.
- Четкое user story со стороны пользователя ("Как пользователь, я хочу...")
- Фокус на бизнес-ценности для пользователя
- TSD включает Implementation Plan

**Формат:**
- `US-XXX-название.md` в `user-stories/`
- `TSD-XXX-название.md` в `tsd/`

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
- [Technical Solutions](../technical-solutions/) - Технические решения
- [Project Repository](../../) - Основной код проекта

---

**Последнее обновление:** 26.10.2025
**Версия документации:** 1.0
**Тип документа:** HOW (Практические инструкции)

📈 **[Бизнес-метрики](../business-metrics.md)** - KPI и цели проекта