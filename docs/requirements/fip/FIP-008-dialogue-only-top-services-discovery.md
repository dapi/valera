# Feature Implementation Plan: FIP-008 - Dialogue-Only Top Services Discovery

**Статус:** Draft
**Приоритет:** High
**Версия:** 1.0
**Создан:** 28.10.2025
**Автор:** AI Assistant
**Product Owner:** Pending Approval
**Ожидаемое время реализации:** 3 дня
**Фактическое время реализации:** [заполняется по ходу]

## 📋 Executive Summary

### Бизнес-проблема
Пользователи при запуске бота не знают о спектре услуг автосервиса и нуждаются в навигации по популярным услугам. Текущая система приветствия не предоставляет контекстных предложений, что снижает конверсию в первую заявку.

### Предлагаемое решение
Реализовать dialogue-only систему discovery топ-4 услуг через AI-ассистента. При запуске бот будет представляться и перечислять самые популярные услуги с ценами, поддерживая 100% соответствие Product Constitution (никаких кнопок/меню).

### Бизнес-ценность
- **Конверсия ↑:** Увеличение конверсии в заявку с 8-12% до 15-20% за счет актуальных предложений
- **User Experience ↑:** Пользователи сразу понимают спектр услуг и ценовой диапазон
- **Support Load ↓:** AI самостоятельно определяет нужные услуги, снижая нагрузку на менеджеров
- **ROI:** 2-3 месяца за счет увеличения количества заявок

## 🎯 Влияние на существующие User Stories

### **US-001: Telegram Auto Greeting**
**Текущее состояние:**
- [ ] **Welcome response time:** ~2 секунды
- [ ] **New user conversion:** 5-8%

**С данной функцией:**
- ✅ **Welcome response time:** <2 секунды (доп. контент)
- ✅ **New user conversion:** 15-20% (топ-услуги как триггеры)

### **US-002a: Telegram Basic Consultation**
**Текущее состояние:**
- [ ] **Service recognition accuracy:** ~60%
- [ ] **User clarification rate:** 40% (требуют уточнений)

**С данной функцией:**
- ✅ **Service recognition accuracy:** >90% (топ-услуги в system prompt)
- ✅ **User clarification rate:** <10% (конкретные предложения)

## 🎯 Target KPI

### **Основные бизнес-метрики:**
- **New user conversion rate:** 15-20% (+7-12pp)
- **Service selection accuracy:** >90%
- **Time to first service selection:** <3 диалога
- **User satisfaction (NPS):** >40

### **Технические метрики:**
- **Performance:** Welcome message <2 сек
- **Availability:** 99.9%
- **Response time:** AI ответы <2 сек, image handling <5 сек

## 🔧 Технические требования

### **Архитектура системы:**
```
User → /start → WelcomeService → System Prompt Enhancement → AI Response
                                ↓
                          TopService Model ← Database
                                ↓
                          Service Recognition → Booking Creation
```

### **Core Components:**
1. **TopService Model** - хранение топ-услуг с изображениями и статистикой
2. **Enhanced WelcomeService** - динамическая генерация приветствий
3. **System Prompt v3** - дополненный инструкциями для топ-услуг
4. **Service Recognition Patterns** - AI паттерны для распознавания услуг
5. **Analytics Enhancement** - трекинг популярности услуг

### **Database Schema:**
- **top_services** - name, description, image_url, price_range, popularity_rank, active
- **Indexes:** popularity_rank, active
- **Relationships:** belongs_to account (для multi-tenancy)

### **Интеграции:**
- **Telegram Bot API** - отправка изображений услуг
- **ruby_llm** - расширенные system prompts
- **AnalyticsService** - трекинг эффективности топ-услуг

## ⚡ Implementation Plan

### **Phase 1: Data Model & Basic Infrastructure (1 день)**
**Утро (4 часа):**
- [ ] **Task 1:** Создание TopService модели и миграции
- [ ] **Task 2:** Наполнение таблицы данными (покраска бампера, PDR, фары, сколы)
- [ ] **Task 3:** Индексация для производительности

**После обеда (4 часа):**
- [ ] **Task 4:** Модификация WelcomeService для работы с топ-услугами
- [ ] **Task 5:** Базовые тесты модели и сервиса

### **Phase 2: System Prompt Enhancement & AI Integration (1 день)**
**Утро (4 часа):**
- [ ] **Task 1:** Обновление system prompt с инструкциями для топ-услуг
- [ ] **Task 2:** Добавление паттернов распознавания услуг
- [ ] **Task 3:** Интеграция изображений услуг в приветствие

**После обеда (4 часа):**
- [ ] **Task 4:** Тестирование диалоговых сценариев
- [ ] **Task 5:** Настройка аналитики для трекинга эффективности

### **Phase 3: Testing & Polish (1 день)**
**Утро (4 часа):**
- [ ] **Task 1:** End-to-end тестирование новых пользователей
- [ ] **Task 2:** Тестирование распознавания разнообразных запросов
- [ ] **Task 3:** Performance тестирование (время ответа)

**После обеда (4 часа):**
- [ ] **Task 4:** Финальная полировка system prompt
- [ ] **Task 5:** Документация и передача в QA

## 📊 Success Metrics & Acceptance Criteria

### **Technical Acceptance Criteria:**
- [ ] **Welcome message delivery:** <2 секунды для 95% запросов
- [ ] **Service recognition accuracy:** >90% для топ-4 услуг
- [ ] **Database performance:** TopServices загрузка <100ms
- [ ] **Image handling:** Все изображения оптимизированы под Telegram (<10MB)

### **Business Acceptance Criteria:**
- [ ] **Conversion rate increase:** +7-12pp для новых пользователей
- [ ] **User feedback:** >80% положительных отзывов на понятность предложений
- [ ] **Support reduction:** <10% запросов требуют помощи менеджера
- [ ] **Product Constitution Compliance:** 0% кнопок/меню в интерфейсе

### **Performance Acceptance Criteria:**
- [ ] **Response time:** AI ответы с топ-услугами <2 сек
- [ ] **Memory usage:** <50MB дополнительной памяти
- [ ] **Error rate:** <1% ошибок при обработке приветствий

## 🔗 Dependencies & Risks

### **Dependencies (Зависимости):**
- **ruby_llm gem:** корректная работа расширенных system prompts
- **Telegram API:** поддержка отправки изображений с текстом
- **Existing WelcomeService:** минимизация конфликтов с текущей логикой
- **Product Constitution compliance:** обязательное сохранение dialogue-only подхода

### **Technical Risks:**
- **System Prompt Complexity:** Слишком сложные инструкции могут снизить качество AI
  - **Impact:** Средний - может потребоваться несколько итераций
- **Image Performance:** Большие изображения могут замедлить загрузку
  - **Impact:** Низкий - решается оптимизацией
- **Service Recognition:** AI может неправильно распознавать синонимы
  - **Impact:** Средний - требует тестирования и дообучения

### **Business Risks:**
- **User Overwhelm:** 4 услуги могут быть слишком много для первого сообщения
  - **Impact:** Средний - можно сократить до 3-х услуг
- **Price Transparency:** Открытые цены могут отпугнуть часть клиентов
  - **Impact:** Низкий - используется "от Х рублей"

### **Mitigation Strategies:**
- **A/B Testing:** Тестирование 3 vs 4 услуг в приветствии
- **Progressive Enhancement:** Постепенное усложнение system prompt
- **Fallback Mechanism:** Если AI не справляется → упрощенное приветствие
- **Analytics Monitoring:** Ежедневный мониторинг метрик эффективности

## 🎯 Business Case & ROI

### **Investment:**
- **Development time:** 3 дня (≈24 рабочих часа)
- **Infrastructure cost:** $0 (использует существующую инфраструктуру)
- **Ongoing cost:** $0/месяц (минимальные затраты на поддержку)

### **Expected Returns:**
- **Return 1:** [+150% конверсия новых пользователей] с 8% до 20%
- **Return 2:** [+50% снижение времени до первой заявки] с 5 диалогов до 2
- **Return 3:** [Качественное улучшение] пользователи сразу понимают спектр услуг

### **ROI Timeline:**
- **Month 1:** Окупаемость за счет увеличения количества заявок на 40%
- **Month 2:** Стабильная конверсия 15-20%, ROI 120%
- **Month 3+::** Масштабирование на другие аккаунты, ROI 200%+

## 🔄 Post-Implementation Plan

### **Day 1-7: Monitoring & Optimization**
- [ ] Ежедневный мониторинг конверсии новых пользователей
- [ ] Сбор feedback от пользователей о понятности предложений
- [ ] Оптимизация system prompt на основе реальных диалогов

### **Week 2-4: Performance Analysis**
- [ ] Анализ самых популярных услуг из выборов
- [ ] Корректировка ранжирования топ-услуг
- [ ] Расширение паттернов распознавания синонимов

### **Month 2+: Feature Evolution**
- [ ] Добавление сезонных услуг в топ
- [ ] Персонализация топ-услуг на основе истории диалога
- [ ] Расширение до топ-6 услуг при положительных результатах

## 🔗 Связанные документы

### **Документация:**
- **[Product Constitution](../product/constitution.md)** - обязательные требования к dialogue-only подходу
- **[US-001](../user-stories/US-001-telegram-auto-greeting.md)** - базовое приветствие
- **[US-002a](../user-stories/US-002a-telegram-basic-consultation.md)** - консультации

### **Техническая документация:**
- **[Architecture Decisions](../architecture/decisions.md)** - принципы разделения User Stories
- **[Error Handling Patterns](../patterns/error-handling.md)** - обработка ошибок
- **[Development README](../../README.md)** - процесс разработки

### **Dependencies:**
- **Ruby on Rails 8.1** (уже используется)
- **ruby_llm gem** (уже используется)
- **Telegram Bot API** (уже используется)

---

## ✅ Approval Process

### **Утверждение:**
- [ ] **Product Owner:** ____________________ Date: _______
- [ ] **Tech Lead:** __________________________ Date: _______
- [ ] **Stakeholders:** _______________________ Date: _______

### **Выполненные шаги:**
1. [ ] Анализ Product Constitution на соответствие
2. [ ] Создание технического плана реализации
3. [ ] Оценка рисков и бизнес-кейса
4. [ ] Проверка зависимости от существующих User Stories

### **Результаты:**
- [ ] **Dialogue-only compliance:** 100% соответствие конституции
- [ ] **Performance targets:** <2 сек на приветствие
- [ ] **Business metrics:** 15-20% конверсия в заявку
- [ ] **Technical quality:** >90% распознавание услуг

---

**Версия:** 1.0
**Дата создания:** 28.10.2025
**Ожидаемая дата завершения:** 31.10.2025
**Тип документа:** Feature Implementation Plan (FIP)
**Статус реализации:** Draft
**Связанные документы:**
- Product Constitution
- US-001, US-002a
- Architecture Decisions