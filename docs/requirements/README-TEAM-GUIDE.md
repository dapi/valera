# Руководство для работы с требованиями (Single Developer)

**Статус:** Approved
**Версия:** 2.0 (Интеграция с CENTRAL-FLOW-MODEL.md)
**Аудитория:** Single Developer (Danil)
**Обновлено:** #{Time.now.strftime('%d.%m.%Y')}

## 🎯 Цель руководства

Это руководство объясняет процесс работы с требованиями в проекте Valera для single developer.

> **🚨 ВАЖНО:** В проекте только один разработчик - Danil
> **Роли:** Product Owner, Tech Lead, Developer - один человек

## 🔄 Единый источник правды

**Основная модель:** [CENTRAL-FLOW-MODEL.md](CENTRAL-FLOW-MODEL.md)

Содержит:
- **3 фазы разработки** с четкими границами
- **Зоны ответственности** для каждой роли
- **Единые критерии качества** документации

## 👤 Командная структура (Team of One)

### **Danil = Все роли:**

#### **Product Owner**
- Инициация User Stories
- Утверждение бизнес-требований
- User Acceptance Testing
- Приоритизация задач

#### **Tech Lead**
- Оценка Story Points
- Создание Technical Specifications
- Архитектурные решения (Technical Solutions)
- Code review

#### **Developer**
- Разработка по Implementation Plans
- Unit/E2E тестирование
- CI/CD процессы
- Deployment

## 📋 Процесс работы для Single Developer

### **Phase 1: Идея и анализ** (Product Owner роль)
```
💡 Идея → 🔍 User Story Agent → 📋 User Story Draft → 📋 User Story Approved
```

**Задачи как Product Owner:**
- **Определить** бизнес-потребность
- **Использовать** User Story Agent для создания US
- **Утвердить** User Story (Draft → Approved)
- **Приоритизировать** задачу

### **Phase 2: Спецификация** (Tech Lead роль)
```
📋 User Story Approved → 🔧 Technical Specification → 🏗️ Technical Solution
```

**Задачи как Tech Lead:**
- **Оценить** Story Points
- **Создать** Technical Specification (TS-XXX)
- **Разработать** Technical Solution (TSOL-XXX) для сложных задач
- **Создать** Implementation Plan в `.protocols/`

### **Phase 3: Реализация** (Developer роль)
```
📝 Implementation Plan → 🚀 Development → ✅ Testing → 🚀 Deployment
```

**Задачи как Developer:**
- **Разработать** по плану имплементации
- **Написать** тесты (unit + integration + E2E)
- **Провести** сам code review
- **Развернуть** и протестировать на production

## 📋 Ежедневный workflow

### **Утро (Product Owner):**
1. **Review** новых User Stories от агента
2. **Approval** или запрос изменений
3. **Prioritization** задач на день

### **День (Developer):**
1. **Development** по Implementation Plan
2. **Testing** новой функциональности
3. **Code review** собственных изменений

### **Вечер (Tech Lead):**
1. **Story Points estimation** для новых задач
2. **Technical Specification** для утвержденных User Stories
3. **Implementation Planning** на следующий день

## 📏 Качество документации

**4 критерия качества:** [CENTRAL-FLOW-MODEL.md#критерии-качества-документации-обязательные](CENTRAL-FLOW-MODEL.md#критерии-качества-документации-обязательные)

### **При создании документов:**
- **Zero дублирования** - ссылаться на CENTRAL-FLOW-MODEL.md
- **Четкие зоны** - понимать свою роль в каждой фазе
- **Быстрое обновление** - использовать шаблоны
- **Поиск < 30 секунд** - понятная навигация

## 🔗 Роли в документах

### **Как Product Owner:**
- **Создает и утверждает** User Stories
- **Проверяет** User Acceptance Criteria
- **Тестирует** с реальными пользователями

### **Как Tech Lead:**
- **Оценивает** сложность (Story Points)
- **Создает** Technical Specifications
- **Проектирует** архитектурные решения

### **Как Developer:**
- **Реализует** по Technical Specifications
- **Пишет** и поддерживает тесты
- **Развертывает** в production

## ⚠️ Common Pitfalls для Single Developer

### **❌ Что избегать:**
- **Ролевое смешение** - не делать всё сразу
- **Пропуск фаз** - не разрабатывать без спецификации
- **Технические детали** в User Stories
- **Отсутствие тестирования** - "успею потом"

### **✅ Что делать:**
- **Следовать фазам** - четкое разделение ролей
- **Документировать** решения
- **Тестировать** на каждой фазе
- **Рефлексировать** после каждой задачи

## 🚀 Инструменты и ресурсы

### **🔥 Критически важные:**
- **[Memory Bank](../../.claude/memory-bank.md)** - Архитектурные решения
- **[CENTRAL-FLOW-MODEL.md](CENTRAL-FLOW-MODEL.md)** - Процессы и роли
- **[Product Constitution](../product/constitution.md)** - Недвижимые принципы

### **📋 Рабочие документы:**
- **[User Stories](user-stories/)** - Бизнес-требования
- **[Technical Specs](specifications/)** - Технические требования
- **[Implementation Plans](../../.protocols/)** - Плаs разработки

### **🤖 AI-агенты:**
- **[User Story Agent](../../.claude/user-story-agent.md)** - Создание User Stories
- **README-AI-AGENTS.md** - Инструкции для агентов

## 📊 Метрики успеха

### **Для Product Owner роли:**
- **User Stories creation rate** - 1-2 в неделю
- **Approval time** - < 24 часов
- **User satisfaction** - фидбэк от пользователей

### **Для Tech Lead роли:**
- **Technical Specification quality** - полнота и ясность
- **Story Points accuracy** - отклонение < 20%
- **Architecture consistency** - следование принципам

### **Для Developer роли:**
- **Code quality** - coverage > 80%
- **Deployment success rate** - > 95%
- **Bug fix time** - < 4 часов

## 🔍 Быстрые референсы

### **Когда нужно ПОЧЕМУ:**
```bash
# Архитектурные решения
cat .claude/memory-bank.md

# Полная модель процессов
cat docs/requirements/CENTRAL-FLOW-MODEL.md
```

### **Когда нужно КАК:**
```bash
# Технологический стек и команды
cat CLAUDE.md

# Инструкции для AI-агентов
cat docs/requirements/README-AI-AGENTS.md
```

### **Когда нужно ЧТО ДЕЛАТЬ:**
```bash
# Текущие User Stories
ls docs/requirements/user-stories/

# План разработки
cat docs/requirements/README.md
```

---

**Ключевой принцип:** Четкое разделение ролей даже в single developer команде

**Если сомневаешься:** Следуй фазам и не смешивай роли в одной задаче