# 🤖 Документация требований для AI-агентов

**Создано:** 26.10.2025
**Автор:** Claude AI Agent
**Назначение:** Инструкции для AI-агентов с интеграцией в централизованную модель
**Версия:** 2.0 (Интеграция с CENTRAL-FLOW-MODEL.md)
**Статус:** 🚨 **КРИТИЧЕСКИ ВАЖНО ДЛЯ ПРОЧТЕНИЯ ПЕРЕД ЛЮБОЙ РАБОТОЙ**

## 🎯 **Обязательное чтение для AI-агентов**

**ПЕРВОЕ ДЕЛО ПЕРЕД ЛЮБОЙ РАБОТОЙ:** Прочитать в указанном порядке.

## 🔄 **Единый источник правды**

**Основной источник:** [CENTRAL-FLOW-MODEL.md](CENTRAL-FLOW-MODEL.md)

Этот документ содержит:
- **3 фазы разработки** с четкими границами
- **Роли и зоны ответственности** для всех участников
- **Единые критерии качества** документации
- **Product Constitution compliance**

## 📋 **Быстрый старт для AI-агентов**

### **🔥 Приоритет 1: Архитектурные принципы**

1. **[Memory Bank](../../.claude/memory-bank.md)** - **ОБЯЗАТЕЛЬНО К ИЗУЧЕНИЮ**
   - Product Constitution (НЕПРИКОСНОВЕННЫЕ принципы)
   - Критерии качества документации (4 критерия)
   - Team structure (single developer)
   - История архитектурных решений

2. **[CENTRAL-FLOW-MODEL.md](CENTRAL-FLOW-MODEL.md)** - **Единая модель процессов**
   - 3 фазы разработки (Phase 1-3)
   - Зоны ответственности для каждой роли
   - Definition of Done unified

### **🎯 Приоритет 2: Рабочие документы (конкретные задачи)**

#### **Phase 1: MVP (сейчас в работе)**
- **[US-001](user-stories/US-001-telegram-auto-greeting.md)** - Приветствие (3 story points)
- **[US-002a](user-stories/US-002a-telegram-basic-consultation.md)** - Базовая консультация (1 story point)
- **[US-002b](user-stories/US-002b-telegram-recording-booking.md)** - Запись на осмотр (2 story points)

**Итого Phase 1: 6 story points, 4-5 дней разработки**

#### **Технические спецификации:**
- **[TS-001](specifications/TS-001-telegram-welcome-experience.md)** - Спецификация приветствия

#### **Стратегия:**
- **[ROADMAP.md](../../ROADMAP.md)** - Общая стратегия разработки

## 🤖 **Зоны ответственности AI-агентов**

### **User Story Agent** ([.claude/user-story-agent.md](../../.claude/user-story-agent.md))
**Зона:** ТОЛЬКО Phase 1 (Идея и анализ)
- Создание User Stories по шаблону
- Проверка Product Constitution compliance
- Структурированный опрос (максимум 7 вопросов)
- НЕ собирает технические детали, story points, сроки

### **Technical Agent** (будет создан)
**Зона:** Phase 2-3 (Спецификация и реализация)
- Создание Technical Specifications
- Оценка Story Points
- Создание Implementation Plans

## 🔄 **Процесс работы для AI-агентов**

### **🔍 ПРОВЕРКА СООТВЕТСТВИЯ ПЕРЕД РАБОТОЙ:**

AI-агент ДОЛЖЕН проверить:
```
□ Прочитал Memory Bank и CENTRAL-FLOW-MODEL.md?
□ Понял dialogue-only принцип?
□ Изучил релевантные User Stories?
□ Проверил зависимости между задачами?
□ Убедился в отсутствии кнопок/команд?
□ Понял свою зону ответственности?
```

### **1. Перед началом работы:**
1. Прочитать Memory Bank (ОБЯЗАТЕЛЬНО)
2. Изучить CENTRAL-FLOW-MODEL.md
3. Определить свою зону ответственности
4. Проверить Product Constitution compliance

### **2. Во время работы:**
1. Следовать своей зоне ответственности
2. Применять 4 критерия качества документации
3. Использовать ссылки вместо копирования
4. Проверять соответствие конституции

### **3. После завершения:**
1. Проверить соответствие 4 критериям качества
2. Обновить статус документов
3. Проверить ссылки и зависимости
4. Убедиться в отсутствии нарушений

## 📏 **Шаблоны документов**

### **User Story формат:**
- **Основной шаблон:** `user-story-template.md`
- **Интеграция:** ссылается на CENTRAL-FLOW-MODEL.md
- **Создает:** User Story Agent (только Phase 1)

### **Technical Specification формат:**
- **Основной шаблон:** `technical-specification-template.md`
- **Интеграция:** ссылается на CENTRAL-FLOW-MODEL.md
- **Создает:** Technical Agent (Phase 2)

## 📊 **Быстрые ссылки для AI-агентов**

### **🔥 Критически важные:**
- **[Memory Bank](../../.claude/memory-bank.md)** - Архитектурные решения
- **[CENTRAL-FLOW-MODEL.md](CENTRAL-FLOW-MODEL.md)** - Все процессы и роли

### **🤖 Для работы с Telegram:**
- [Telegram Bot Learning Protocol](../../.claude/telegram-bot-learning.md)
- [Telegram Bot Documentation](../../docs/gems/telegram-bot/)

### **🧠 Для работы с AI:**
- [Ruby LLM Learning Protocol](../../.claude/ruby_llm-learning.md)
- [Ruby LLM Documentation](../../docs/gems/ruby_llm/)

### **📋 Рабочие документы:**
- **[User Stories](user-stories/)** - Конкретные задачи
- **[Technical Specs](specifications/)** - Технические требования
- **[ROADMAP.md](../../ROADMAP.md)** - Стратегия разработки

## ⚡ **Финальный чек-лист качества**

Перед завершением задачи:

**🔍 Zone Responsibility:**
- [ ] Я в своей зоне ответственности?
- [ ] Не нарушаю зоны других агентов?

**📏 Documentation Quality (4 критерия):**
- [ ] Zero дублирования?
- [ ] Четкие зоны ответственности?
- [ ] Быстрое обновление?
- [ ] Поиск < 30 секунд?

**🚨 Constitution Compliance:**
- [ ] Dialogue-only interaction?
- [ ] AI-first подход?
- [ ] Russian language context?
- [ ] No file operations in tests?

## 🚨 **Если что-то непонятно**

1. **Сначала** проверь Memory Bank и CENTRAL-FLOW-MODEL.md
2. **Потом** поищи ответ в существующих документах
3. **Если нет ответа** - уточни у пользователя
4. **Не делай предположений** - следуй принципам

---

**Ключевой принцип:** Centralized Flow Model = Single Source of Truth

**Если сомневаешься:** Выбери более простой вариант и оставайся в своей зоне ответственности.