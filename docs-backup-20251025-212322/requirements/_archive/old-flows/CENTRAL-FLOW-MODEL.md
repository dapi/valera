# 🔄 Централизованная модель управления требованиями

**Статус:** Proposed
**Версия:** 2.0
**Создан:** 25.10.2025
**Назначение:** Единый источник правды для всех процессов работы с требованиями

## 🎯 Принцип централизации

Этот документ - **ЕДИНЫЙ ИСТОЧНИК ПРАВДЫ** для всех процессов. Другие документы ссылаются сюда, а не дублируют информацию.

## 📋 Жизненный цикл требований (Unified Lifecycle)

### Phase 1: Идея и анализ (Idea & Analysis)
```
💡 Идея → 🔍 Анализ → 📋 User Story Draft
```

#### Этапы:
1. **💡 Идея** - Business requirement/request
2. **🔍 Анализ** - User Story Agent собирает информацию
3. **📋 User Story Draft** - Создание черновика по шаблону

### Phase 2: Спецификация (Specification)
```
📋 User Story Approved → 🔧 Technical Specification → 🏗️ Technical Solution
```

#### Этапы:
4. **📋 User Story Approved** - Утверждение бизнес-требования
5. **🔧 Technical Specification** - Технические требования (TS-XXX)
6. **🏗️ Technical Solution** - Архитектурное решение (TSOL-XXX) для сложных задач

### Phase 3: Реализация (Implementation)
```
📝 Implementation Plan → 🚀 Development → ✅ Testing → 🚀 Deployment
```

#### Этапы:
7. **📝 Implementation Plan** - План в `.protocols/`
8. **🚀 Development** - Разработка
9. **✅ Testing** - Тестирование
10. **🚀 Deployment** - Развертывание

## 🎯 Роли и зоны ответственности

### 📝 User Story Agent (Claude)
**Зона:** Phase 1 (Идея и анализ)
**Ответственность:**
- Сбор информации через структурированный диалог
- Создание User Story по шаблону
- Проверка соответствия Product Constitution
- Генерация номера документа (US-XXX)

**Триггеры активации:**
- Ключевые слова: "user story", "требование", "функция", "хочу добавить"
- Работа с файлами в `docs/requirements/`

**Процесс работы:**
1. **Автоопределение типа задачи** (автосервис, AI, telegram)
2. **Структурированный опрос** (максимум 7 вопросов)
3. **Генерация документа** по шаблону
4. **Рекомендация следующих шагов**

### 👤 Product Owner
**Зона:** Phase 1-2 (Утверждение)
**Ответственность:**
- Утверждение User Story ( Draft → Approved )
- Приоритизация задач
- Утверждение бизнес-ценности
- User Acceptance Testing

### 🏗️ Tech Lead
**Зона:** Phase 2-3 (Техническая реализация)
**Ответственность:**
- Создание/Review Technical Specification
- Оценка Story Points
- Архитектурные решения (TSOL-XXX)
- Code review и техническое качество

### 👨‍💻 Developer
**Зона:** Phase 3 (Реализация)
**Ответственность:**
- Создание Implementation Plan
- Разработка по плану
- Unit/E2E тестирование
- Documentation

## 📋 Единые критерии качества

### ✅ User Acceptance Criteria (UAC)
**Формат:** "Как [тип пользователя] Я могу/понимаю/чувую [действие/результат/ощущение] когда [условие]"

**Правила:**
- Максимум 5 критериев
- Простой язык без технических терминов
- Фокус на результате и ощущениях пользователя
- Обязательно тестирование с реальными пользователями

### 🤖 Functional Criteria (FC)
**Формат:** Given-When-Then

**Правила:**
- Максимум 5 критериев
- Технические требования к системе
- Measurable и testable

### 📊 Performance Criteria (PC)
**Формат:** Конкретные метрики

**Правила:**
- Время ответа < X секунд
- Нагрузка: Y одновременных пользователей
- Доступность: Z% uptime

## 🔗 Система ссылок и зависимостей

### Обязательные ссылки:
- **User Story (US-XXX)** → **Feature Description** (если есть)
- **User Story (US-XXX)** → **Technical Specification (TS-XXX)**
- **Complex US** → **Technical Solution (TSOL-XXX)**
- **All** → **Implementation Plan** (в `.protocols/`)

### Формат зависимостей:
```markdown
## 🔗 Связанные документы
- **Feature Description:** [ссылка]
- **Technical Specification:** [TS-XXX](ссылка)
- **Technical Solution:** [TSOL-XXX](ссылка) - если сложная задача
- **Implementation Plan:** [.protocols/план.md](ссылка)
- **Dependencies:** US-XXX, US-YYY
```

## 🎯 Definition of Done (Unified)

### ✅ Business Ready:
- [ ] Все User Acceptance Criteria пройдены
- [ ] Product Owner утвердил
- [ ] Проведено UAT с реальными пользователями

### ✅ Technical Ready:
- [ ] Все Functional Criteria реализованы
- [ ] Code review пройден
- [ ] Тестовое покрытие ≥ 80%
- [ ] Performance Criteria измерены

### ✅ Production Ready:
- [ ] Функциональность протестирована на staging
- [ ] Документация обновлена
- [ ] Мониторинг настроен
- [ ] Rollback план готов

## 🚨 Единые правила (Product Constitution Integration)

### ❌ Запрещено:
- Никаких кнопок, меню, команд (/start, /help)
- Никаких UI элементов кроме текста
- Никаких file operations в тестах

### ✅ Обязательно:
- Dialogue-only interaction
- AI-first approach
- Russian language context
- Visual analysis priority (для кузовного ремонта)

## 📞 Process Flow для разных типов задач

### 🚗 Автосервис задачи:
```
User Request → User Story Agent [автосервис шаблон] → US Draft → PO Review → TS → Implementation
```

### 🤖 AI/LLM задачи:
```
AI Request → User Story Agent [AI шаблон] → US Draft → Tech Lead Review → TSOL (если нужно) → Implementation
```

### 📱 Telegram Bot задачи:
```
Bot Request → User Story Agent [telegram шаблон] → US Draft → Constitution Check → TS → Implementation
```

## 🔗 Интеграция с документацией

### Этот документ является источником для:
- **README-AI-AGENTS.md** - процессы для AI
- **README-user-stories.md** - методология User Stories
- **README-TEAM-GUIDE.md** - процессы для команды
- **user-story-agent.md** - инструкции для агента
- **Все шаблоны** - структура документов

### Правило обновления:
**ЕСЛИ ПРОЦЕСС ИЗМЕНЯЕТСЯ → ОБНОВЛЯТЬ СНАЧАЛА ЭТОТ ДОКУМЕНТ, ЗАТЕМ ВСЕ ССЫЛКИ**

## 📏 Критерии качества документации (ОБЯЗАТЕЛЬНЫЕ)

При создании ЛЮБЫХ документов в проекте применять эти 4 критерия:

### 🚫 Zero дублирования
- Каждый процесс описан только в одном месте
- Использовать ссылки вместо копирования
- Single source of truth principle

### 👥 Четкие зоны ответственности
- Каждый документ имеет определенного "владельца"
- У каждой роли есть своя зона ответственности
- Нет пересечений и размытых границ

### ⚡ Быстрое обновление документации
- Использовать шаблоны и ссылки
- Не создавать дублирующиеся разделы
- Централизовать общие процессы
- Цель: время обновления ↓ 50%

### 🔎 Быстрый поиск (< 30 секунд)
- Понятная навигация
- Хорошие ссылки между документами
- Структурированное оглавление
- Ключевые слова для поиска

**ВАЖНО:** Эти критерии применяются ко ВСЕМ агентам при создании ЛЮБЫХ документов!

---

**Версия 2.0:** Унификация всех flow в один документ для исключения дублирования