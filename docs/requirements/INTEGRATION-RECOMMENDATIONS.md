# 📋 Рекомендации по интеграции с централизованной моделью

**Статус:** Proposed
**Цель:** Обновление существующих документов для устранения дублирования и интеграции с CENTRAL-FLOW-MODEL.md

## 🎯 Обзор проблемы

Текущая документация содержит множественные описания одних и тех же процессов:
- Разные lifecycle в разных документах
- Дублирование правил Product Constitution
- Противоречащие инструкции для агентов
- Отсутствие единого источника правды

## 📋 Предлагаемые обновления

### 1. 🔄 README-user-stories.md

**Проблема:** Дублирует lifecycle и критерии приемки

**Предлагаемые изменения:**

```markdown
## 🔄 Жизненный цикл User Story

Подробное описание жизненного цикла см. в [CENTRAL-FLOW-MODEL.md](CENTRAL-FLOW-MODEL.md).

**Краткая версия для Product Owner:**
- **Phase 1:** User Story Agent → Draft → Review → Approved
- **Phase 2:** Technical Specification → Technical Solution
- **Phase 3:** Implementation Plan → Development → Done

## ✅ Критерии приемки

Подробные критерии см. в [CENTRAL-FLOW-MODEL.md](CENTRAL-FLOW-MODEL.md#единые-критерии-качества).

**Краткая версия:**
- **User Acceptance Criteria** - от лица пользователя
- **Functional Criteria** - Given-When-Then
- **Performance Criteria** - конкретные метрики
```

### 2. 🤖 README-AI-AGENTS.md

**Проблема:** Дублирует инструкции и процессы

**Предлагаемые изменения:**

```markdown
## 🔄 Процесс работы для AI-агентов

**Единый источник правды:** [CENTRAL-FLOW-MODEL.md](CENTRAL-FLOW-MODEL.md)

### Для User Story Agent:
См. [user-story-agent.md](../../.claude/user-story-agent.md) - Phase 1 только

### Для других агентов:
Следовать ролям и зонам ответственности из CENTRAL-FLOW-MODEL.md

## ✅ Проверка качества

Все чек-листы см. в [CENTRAL-FLOW-MODEL.md](CENTRAL-FLOW-MODEL.md#definition-of-done-unified)
```

### 3. 📝 user-story-template.md

**Проблема:** Содержит инструкции, которые дублируются в CENTRAL-FLOW-MODEL.md

**Предлагаемые изменения:**

```markdown
# User Story: US-XXX - [Название]

> **📋 Создается:** User Story Agent в Phase 1
> **🔗 Процесс:** [CENTRAL-FLOW-MODEL.md](CENTRAL-FLOW-MODEL.md)
> **✅ Критерии:** см. Definition of Done в CENTRAL-FLOW-MODEL.md

## ✅ Критерии приемки

Подробные правила формулировки см. в [CENTRAL-FLOW-MODEL.md](CENTRAL-FLOW-MODEL.md#единые-критерии-качества)

### 👥 User Acceptance Criteria (Пользовательские критерии)
[Формулировки от лица пользователя по правилам из CENTRAL-FLOW-MODEL.md]

### 🤖 Functional Criteria (Технические требования)
[Given-When-Then по правилам из CENTRAL-FLOW-MODEL.md]

### 📊 Performance Criteria (Требования к производительности)
[Конкретные метрики по правилам из CENTRAL-FLOW-MODEL.md]

## ✅ Definition of Done

Полная версия в [CENTRAL-FLOW-MODEL.md](CENTRAL-FLOW-MODEL.md#definition-of-done-unified)

### 🚨 Обязательная проверка Product Constitution:
- [ ] Dialogue-Only Interaction (НИКАКИХ кнопок)
- [ ] AI-First Approach
- [ ] Russian Language Context
- [ ] Visual Analysis Priority (если применимо)
```

### 4. 👥 README-TEAM-GUIDE.md

**Проблема:** Дублирует процессы и роли

**Предлагаемые изменения:**

```markdown
## 🎯 Роли и процессы

**Единый источник правды:** [CENTRAL-FLOW-MODEL.md](CENTRAL-FLOW-MODEL.md)

### Краткие роли:
- **Product Owner:** Phase 1-2 утверждение
- **Tech Lead:** Phase 2-3 техническое руководство
- **Developer:** Phase 3 реализация

Подробности см. в [CENTRAL-FLOW-MODEL.md](CENTRAL-FLOW-MODEL.md#роли-и-зоны-ответственности)

## 📋 Процесс работы

Следовать фазам из [CENTRAL-FLOW-MODEL.md](CENTRAL-FLOW-MODEL.md):
1. Phase 1: Идея и анализ
2. Phase 2: Спецификация
3. Phase 3: Реализация
```

## 🚀 Порядок обновления

### Phase 1: Создание централизованной модели ✅
- [x] CENTRAL-FLOW-MODEL.md создан
- [x] user-story-agent.md обновлен

### Phase 2: Обновление связанных документов (предлагается)
1. **Обновить README-user-stories.md**
   - Ссылаться на CENTRAL-FLOW-MODEL.md
   - Удалить дублирующиеся разделы
   - Оставить только PO-специфичные инструкции

2. **Обновить README-AI-AGENTS.md**
   - Сделать CENTRAL-FLOW-MODEL.md основным источником
   - Упростить инструкции для агентов
   - Добавить ссылки на конкретные разделы

3. **Обновить шаблоны**
   - user-story-template.md ссылать на CENTRAL-FLOW-MODEL.md
   - Удалить дублирующиеся инструкции
   - Оставить только структуру документа

4. **Обновить README-TEAM-GUIDE.md**
   - Ссылаться на CENTRAL-FLOW-MODEL.md для процессов
   - Оставить только командную специфику

### Phase 3: Верификация
- Проверить все ссылки
- Убедиться в отсутствии дублирования
- Проверить полноту coverage процессов

## 📊 Ожидаемые результаты

### ✅ Преимущества:
- **Единый источник правды** - все процессы в одном месте
- **Устранение дублирования** - экономия времени при поддержке
- **Четкие зоны ответственности** - каждый понимает свою роль
- **Простота обновления** - изменения только в одном документе

### 📈 Метрики успеха:
- Количество дублирующихся разделов → 0
- Количество ссылок на CENTRAL-FLOW-MODEL.md → 15+
- Время на обновление документации ↓ 50%
- Консистентность процессов ↑ 100%

## 🔗 Интеграция с инструментами

### Для проверки ссылок:
```bash
# Проверить все ссылки на CENTRAL-FLOW-MODEL.md
grep -r "CENTRAL-FLOW-MODEL.md" docs/requirements/
```

### Для поиска дублирования:
```bash
# Найти дублирующиеся разделы
find docs/requirements -name "*.md" -exec grep -l "Жизненный цикл" {} \;
```

### Для валидации:
```bash
# Проверить наличие ссылок в шаблонах
grep -l "CENTRAL-FLOW-MODEL.md" docs/requirements/templates/*.md
```

---

**Следующие шаги:**
1. Утвердить CENTRAL-FLOW-MODEL.md
2. Последовательно обновить документы
3. Провести верификацию ссылок
4. Обновить чек-листы команд