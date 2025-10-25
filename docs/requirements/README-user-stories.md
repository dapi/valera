# User Story Методология

**Статус:** Approved
**Версия:** 2.0 (Интеграция с CENTRAL-FLOW-MODEL.md)
**Создан:** 25.10.2025
**Автор:** Product Owner

## 🎯 Цель документа

Этот документ описывает методологию работы с User Stories с точки зрения **Product Owner** для проекта Valera.

## 🔄 Единый источник правды

**Полное описание жизненного цикла и процессов:** [CENTRAL-FLOW-MODEL.md](CENTRAL-FLOW-MODEL.md)

### Краткая версия для Product Owner:

**Phase 1: Идея и анализ** (зона Product Owner)
```
💡 Идея → 🔍 User Story Agent → 📋 User Story Draft → 📋 User Story Approved
```

**Phase 2: Спецификация** (участие Product Owner)
```
📋 User Story Approved → 🔧 Technical Specification → 🏗️ Technical Solution
```

**Phase 3: Реализация** (контроль Product Owner)
```
📝 Implementation Plan → 🚀 Development → ✅ Testing → 🚀 Deployment
```

## 📋 Зона ответственности Product Owner

### ✅ Phase 1: Идея и анализ
- **Инициирование User Stories** на основе бизнес-потребностей
- **Утверждение User Stories** (Draft → Approved)
- **Приоритизация** задач
- **User Acceptance Testing** с реальными пользователями

### ✅ Phase 2: Спецификация
- **Утверждение бизнес-требований** в Technical Specification
- **Проверка соответствия** Product Constitution
- **Утверждение Technical Solution** для сложных функций

### ✅ Phase 3: Реализация
- **Финальная приемка** результатов
- **Утверждение релизов** и развертывания
- **Сбор feedback** от пользователей

## 📋 Критерии приемки (Acceptance Criteria)

**Полное описание критериев:** [CENTRAL-FLOW-MODEL.md#единые-критерии-качества](CENTRAL-FLOW-MODEL.md#единые-критерии-качества)

### Краткая версия для Product Owner:

#### 👥 User Acceptance Criteria (ПОЛЕЗНАЯ ИНФОРМАЦИЯ)
**Что:** Проверка что пользователь может решить свою задачу
**Как:** От лица пользователя, простым языком

**Примеры для автосервиса:**
```
Как новый клиент Я получаю понятное приветствие когда впервые пишу боту
Как клиент Я понимаю какие услуги доступны после разговора с ассистентом
Как пользователь Я чувствую что общаюсь с профессионалом по кузовному ремонту
```

**Правила для Product Owner:**
- Максимум 5 критериев на User Story
- Формулировки от лица пользователя ("Как клиент Я могу...")
- Фокус на результате и ощущениях
- Обязательно тестирование с реальными пользователями

#### 🤖 Functional Criteria (ДЛЯ ИНФОРМАЦИИ)
*Зона ответственности Tech Lead*

#### 📊 Performance Criteria (ДЛЯ ИНФОРМАЦИИ)
*Зона ответственности Tech Lead*

## 🔗 Связанные документы

**Полная иерархия:** [CENTRAL-FLOW-MODEL.md#система-ссылок-и-зависимостей](CENTRAL-FLOW-MODEL.md#система-ссылок-и-зависимостей)

### Что важно знать Product Owner:
- **User Story (US-XXX)** → **Technical Specification (TS-XXX)**
- **Complex US** → **Technical Solution (TSOL-XXX)**
- **All** → **Implementation Plan** (в `.protocols/`)

## 📝 Шаблон и примеры

### Шаблон:
- **Основной:** `user-story-template.md`
- **Интеграция:** Шаблон ссылается на CENTRAL-FLOW-MODEL.md

### Примеры готовых User Stories:
- `US-001-telegram-auto-greeting.md`
- `US-002a-telegram-basic-consultation.md`
- `US-002b-telegram-recording-booking.md`

## 🚀 Definition of Done

**Полная версия:** [CENTRAL-FLOW-MODEL.md#definition-of-done-unified](CENTRAL-FLOW-MODEL.md#definition-of-done-unified)

### Что важно Product Owner:
- **Business Ready:** User Acceptance Criteria пройдены, Product Owner утвердил
- **Production Ready:** Система готова к продакшену
- **Командная проверка:** Все соответствуют Product Constitution

## ⚠️ Распространенные ошибки для Product Owner

### ❌ Что НЕ делать:
- Добавлять технические детали в User Story
- Создавать больше 5 User Acceptance Criteria
- Игнорировать Product Constitution (dialogue-only!)
- Тестировать только с командой (нужны реальные пользователи)

### ✅ Что делать:
- Фокусироваться на потребностях пользователей
- Использовать реальные метрики успеха
- Проводить User Acceptance Testing с клиентами
- Регулярно обновлять статусы User Stories

## 🔧 Product Owner Workflow

### Ежедневные задачи:
1. **Review** новых User Stories от агента
2. **Approval** или запрос изменений
3. **Prioritization** задач в бэклоге
4. **User Testing** с реальными клиентами

### Еженедельные задачи:
1. **Planning** следующих User Stories
2. **Review** технических спецификаций
3. **Demo** и приемка готовых функций
4. **Feedback** сбор и анализ

---

**Интеграция с CENTRAL-FLOW-MODEL.md:** Все детали процессов см. в едином источнике правды

---

**История изменений:**
- 25.10.2025 - Создание методологии
- Добавление требований по User Acceptance Criteria
- Детализация процесса согласования