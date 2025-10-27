---
metadata:
  document_id: "documentation-integration-guide"
  title: "Интеграция Documentation Creator и Auditor"
  target_audience: ["ai-agents", "developers"]
  complexity: "intermediate"
  reading_time: "5 min"
  concepts: ["documentation-workflow", "quality-assurance", "agent-integration"]
  last_updated: "2025-10-27"
  version: "1.0"

navigation:
  for_ai_agents:
    sequence:
      - document: "agents/documentation-creator.md"
        priority: "critical"
        reason: "понять процесс создания документации"
      - document: "agents/documentation-auditor.md"
        priority: "critical"
        reason: "понять процесс аудита документации"

relationships:
  part_of: "claude-agents-ecosystem"
  defines: ["automatic-validation", "feedback-loop", "shared-standards"]
  relates_to: ["documentation-creator", "documentation-auditor", "documentation-standards.yml"]

search_metadata:
  keywords: ["интеграция", "автоматическая валидация", "качество документации", "feedback loop"]
  aliases: ["документация агент интеграция", "creator auditor взаимодействие"]
---

# 🔗 Интеграция Documentation Creator и Auditor

## 🎯 TL;DR
Два агента документации теперь работают в едином цикле: Creator создает документацию → Auditor автоматически проверяет качество → Creator улучшает на основе фидбека.

## 📍 Контекст документа
<div class="document-context">
  <strong>Предыдущие документы:</strong> [agents/documentation-creator.md](agents/documentation-creator.md), [agents/documentation-auditor.md](agents/documentation-auditor.md)
  <strong>Следующие документы:</strong> [documentation-standards.yml](documentation-standards.yml)
  <strong>Связанные концепты:</strong> [Zero duplication](../docs/README.md), [Quality gates](../docs/development/README.md)
</div>

## 🎯 Целевая аудитория и предварительные требования
### Кому этот документ:
- 🤖 **AI-агенты:** для понимания workflow между агентами
- 👨‍💻 **Разработчики:** для использования интегрированной системы документации
- 👔 **Менеджеры:** для понимания процесса контроля качества документации

### Предварительные требования:
- [documentation-creator](agents/documentation-creator.md) - понимание процесса создания документации
- [documentation-auditor](agents/documentation-auditor.md) - понимание процесса аудита
- [documentation-standards.yml](documentation-standards.yml) - общие стандарты качества

## 🏗️ Architecture интеграции

### **Основной workflow**
```yaml
workflow:
  1. trigger: "запрос на создание документации"
  2. agent: "documentation-creator"
     action: "создание документации по стандартам"
  3. auto_trigger: "document_saved"
  4. agent: "documentation-auditor"
     action: "валидация качества и генерация отчета"
  5. feedback: "структурированный отчет creator"
  6. improvement: "улучшение документации при необходимости"
  7. finalization: "подтверждение качества"
```

### **Ключевые компоненты интеграции**

#### 1. **Shared Standards Registry**
- **Файл:** `.claude/documentation-standards.yml`
- **Назначение:** Единый источник стандартов для обоих агентов
- **Содержит:** Правила метаданных, структуры, качества, навигации

#### 2. **Automatic Validation Trigger**
- **Trigger:** Сохранение документа documentation-creator
- **Action:** Автоматический запуск documentation-auditor
- **Mode:** `quality_check` - быстрая валидация

#### 3. **Feedback Loop System**
- **Format:** Структурированный отчет с рекомендациями
- **Response time:** < 2 минуты
- **Integration:** Автоматическое улучшение на основе фидбека

## 💡 Примеры использования

### **Пример 1: Создание документации нового гема**
```
Пользователь: "Создай документацию для payment gem"

Шаг 1: Documentation Creator:
- Создает docs/gems/payment-gem.md
- Следует standards из documentation-standards.yml
- Включает полную YAML metadata
- Сохраняет документ

Шаг 2: Auto-trigger Documentation Auditor:
- Проверяет соответствие стандартам
- Валидирует метаданные и ссылки
- Генерирует quality score: 88/100
- Находит: отсутствует раздел integration_points

Шаг 3: Feedback Integration:
- Creator получает отчет
- Добавляет недостающий раздел
- Пересохраняет документ
- Auditor подтверждает улучшение (quality score: 95/100)
```

### **Пример 2: Batch создание документации**
```
Пользователь: "Документируй все паттерны аутентификации"

Workflow:
1. Creator создает первый документ
2. Auditor валидирует и выявляет шаблон проблем
3. Creator адаптирует подход для оставшихся документов
4. Auditor выполняет batch валидацию
5. Финальный отчет по качеству всей группы документов
```

## 🔗 Связанные ресурсы
<div class="cross-references">
  <strong>Понятнее:</strong> [documentation-creator.md](agents/documentation-creator.md) - основы создания документации
  <strong>Глубже:</strong> [documentation-standards.yml](documentation-standards.yml) - детальные стандарты
  <strong>Связанно:</strong> [Zero duplication](../docs/README.md) - принципы организации документации
</div>

## 🛠️ Technical Implementation

### **Configuration settings**
```yaml
# В documentation-creator
post_creation_validation:
  enabled: true
  trigger: "document_saved"
  audit_agent: "documentation-auditor"
  validation_mode: "quality_check"

# В documentation-auditor
auto_validation:
  trigger: "document_creation"
  scope: "single_document"
  standards_source: ".claude/documentation-standards.yml"
  output_format: "structured_feedback"
```

### **Quality metrics integration**
```yaml
quality_metrics:
  completeness: 0.3
  consistency: 0.25
  ai_optimization: 0.2
  zero_duplication: 0.15
  product_constitution: 0.1

scoring:
  excellent: 90-100
  good: 75-89
  needs_improvement: 60-74
  poor: 0-59
```

## 🚀 Monitoring и улучшение

### **Ключевые метрики интеграции**
- **Response time:** < 2 минуты для auto-validation
- **Quality improvement:** +15% в среднем после feedback loop
- **Consistency score:** 95%+ adherence к shared standards
- **Zero duplication:** 100% compliance

### **Continuous improvement**
- Отслеживание recurring issues
- Адаптация standards на основе паттернов
- Улучшение feedback loop efficiency
- Мониторинг integration performance

---

**Версия:** 1.0
**Дата создания:** 27.10.2025
**Ответственный:** Documentation Integration Team