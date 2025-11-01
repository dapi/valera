# CLAUDE.md

**Critical Rules для Claude Code при работе с проектом Valera**

**Quick Start:** @docs/README.md

## ⚙️ Critical Rules

🚨 **Models:** ВСЕГДА `rails generate model` (модель + миграция вместе)
🚨 **Error Handling:** `ErrorLogger` вместо `Bugsnag.notify()`
🚨 **Configuration:** Только `anyway_config`, никаких `.env*` файлов
🚨 **Documentation:** НЕ архивировать FIP/US/TSD документы из `docs/requirements/`
🚨 **Testing:** Без `File.write/File.delete` и изменения ENV в тестах

## 📋 Ссылки

**Process:** @docs/FLOW.md | **Development:** @docs/development/README.md | **Error Handling:** @docs/patterns/error-handling.md | **Architecture:** @docs/architecture/decisions.md | **Gems:** @docs/gems/README.md

## 🎯 Работа с требованиями (Critical для AI-агентов)

### 📁 Структура управления требованиями

**ROADMAP.md** - Активные фазы разработки
- Только запланированные к реализации фазы
- Четкие timeline и зависимости
- Текущий фокус: Phase 1 → Phase 1.5 → Phase 2 → Phase 3 → Phase 4

**BACKLOG.md** - Очередь на рассмотрение
- Утвержденные идеи с бизнес-ценностью, но без конкретных сроков
- Требуют уточнения или дополнительного анализа
- Ежемесячные review для перемещения в ROADMAP

**ICEBOX.md** - Отложенные indefinitely
- "Maybe someday" идеи с низким приоритетом
- Технически сложные или рискованные концепции
- Ежеквартальные review при изменении обстоятельств

**DEPRECATED.md** - Архив отклоненных идей
- Признанные нецелесообразными решения
- Исторический контекст для избежания повторения ошибок
- Lessons learned и успешные отклонения

### 🤖 Инструкции для AI-агентов

#### При работе с User Stories и требованиями:

1. **ВСЕГДА проверять статус документа** перед началом работы:
   - Если статус "Draft" → сначала уточни требования у пользователя
   - Если статус "Ready" или "In Progress" → можно начинать реализацию
   - Если статус "Completed" → не трогать, создай новую версию при необходимости

2. **Для новых требований:**
   - Определи категорию: User Story (US), FIP, или Technical Design (TSD)
   - Создай в соответствующей папке `docs/requirements/{user-stories,fip,tsd}/`
   - Используй шаблоны из `docs/requirements/templates/`
   - Установи начальный статус "Draft"

3. **Для существующих требований:**
   - НЕ изменяй документы со статусом "Completed" или "Production"
   - Для активных документов обновляй статусы следуя workflow:
     ```
     Draft → BusinessAnalyzes → SystemAnalyzes → Ready → In Progress → Completed → Production
     ```

4. **При работе сROADMAP:**
   - Функции из ROADMAP.md имеют высший приоритет
   - BACKLOG.md можно предлагать к перемещению в ROADMAP при наличии ресурсов
   - ICEBOX.md - только при стратегическом изменении приоритетов

5. **Процесс создания новых требований:**
   ```
   Идея → Обсуждение → Draft документ → Business Analyzes → System Analyzes → Ready → Implementation
   ```

### 🔄 Workflow принятия решений

**Новая функция появляется:**
1. Создать Draft документ в соответствующей категории
2. Провести бизнес-анализ (ценность, ROI, метрики)
3. Провести системный анализ (сложность, риски, зависимости)
4. Определить приоритет и место в структуре:
   - Высокий приоритет + четко → ROADMAP.md
   - Есть ценность + timing неясен → BACKLOG.md
   - Интересно + низкий приоритет → ICEBOX.md
   - Плохая идея → DEPRECATED.md

**Регулярные ревью:**
- **Ежемесячно (1-го числа):** BACKLOG review
- **Ежеквартально:** ICEBOX review
- **При изменениях:** ROADMAP-ARCHIVE.md обновляется

### 🚨 Critical Rules для требований

🚨 **НЕ изменять** документы со статусом "Completed" или "Production"
🚨 **ВСЕГДА** следовать workflow статусов (не перескакивать через этапы)
🚨 **НЕ архивировать** активные документы - используй префикс `[DEPRECATED]`
🚨 **ИСПОЛЬЗУЙ** шаблоны из `docs/requirements/templates/` для новых документов
🚨 **ОБНОВЛЯЙ** ROADMAP-ARCHIVE.md при значительных изменениях приоритетов
/file:.claude-on-rails/context.md
