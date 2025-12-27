# Technical Specification Document: TSD-007 - Dialogue-Only Services Discovery

**Статус:** Draft
**Сложность:** Complex
**Приоритет:** High
**Создан:** 28.10.2025
**Обновлен:** 28.10.2025
**User Story:** [US-007-telegram-services-discovery.md](../user-stories/US-007-telegram-services-discovery.md)

## 🎯 Технические требования

### Functional Requirements
- [ ] **[FR-001]:** AI-анализ первого сообщения пользователя для определения контекста
- [ ] **[FR-002]:** Автоматическая презентация топ-4 услуг с ценами
- [ ] **[FR-003]:** Естественная интеграция discovery в приветственный диалог
- [ ] **[FR-004]:** Динамическая адаптация предложений на основе контекста
- [ ] **[FR-005]:** Обработка уточняющих вопросов о конкретных услугах
- [ ] **[FR-006]:** Логирование эффективности discovery фазы

### Non-Functional Requirements
- [ ] **Performance:**
  - Response time: < 2000ms для AI-анализа и генерации ответа
  - LLM inference: < 1500ms для промпт обработки
  - Concurrent users: 50+ одновременных диалогов
- [ ] **AI Quality:**
  - Service relevance accuracy: > 95%
  - Natural dialogue score: > 90%
  - Price accuracy: 100% соответствие прайс-листу
- [ ] **Reliability:**
  - Service uptime: > 99%
  - Fallback behavior: graceful degradation при недоступности AI
  - Error recovery: автоматический retry механизмов
- [ ] **Scalability:**
  - AI model scaling: поддержка нескольких инстансов
  - Caching strategy: кэширование популярных услуг
  - Load balancing: распределение запросов

## 🏗️ Архитектура

### Components
1. **ServicesDiscoveryService** - основная логика discovery
2. **TopServicesSelector** - алгоритм выбора релевантных услуг
3. **AIPromptManager** - управление промптами для AI
4. **PriceService** - интеграция с прайс-листом
5. **DialogueAnalytics** - отслеживание эффективности

### AI System Architecture
```
User Message → Context Analysis → Service Selection → Prompt Generation → LLM → Response
     ↓                    ↓                ↓               ↓             ↓
  Analytics         User Profile     Service DB    Prompt Cache   Quality Check
```

### Integration Points
- **Ruby_LLM:** генерация AI-ответов
- **ApplicationConfig:** хранение промптов и настроек
- **Price Database:** актуальная информация об услугах
- **Analytics:** отслеживание conversion и engagement

## 📝 Implementation Plan

### Phase 1: Core Discovery Logic (3 дня)
```ruby
# app/services/services_discovery_service.rb
class ServicesDiscoveryService
  def initialize(message, user_context)
    @message = message
    @user_context = user_context
  end

  def discover_and_present
    services = select_top_services
    prompt = build_discovery_prompt(services)
    generate_response(prompt)
  end
end
```

### Phase 2: AI Prompts System (2 дня)
```yaml
# config/prompts/services_discovery.yml
welcome_with_services:
  system: |
    Ты - AI-ассистент автосервиса Super Valera. Представься и представь топ-4 услуги.
    Услуги: %{services}
    Цены: %{prices}

    Веди диалог естественно, без кнопок и меню.
```

### Phase 3: Service Selection Algorithm (2 дня)
```ruby
# app/services/top_services_selector.rb
class TopServicesSelector
  def select_services(user_context, message_content)
    # Алгоритм выбора релевантных услуг
    base_services = most_popular_services
    contextual_services = analyze_context(user_context, message_content)
    merge_and_rank(base_services, contextual_services).first(4)
  end
end
```

### Phase 4: Analytics Integration (1 день)
```ruby
# app/services/dialogue_analytics.rb
class DialogueAnalytics
  def track_discovery_impression(services_presented)
    # Отслеживание показов услуг
  end

  def track_service_interest(service)
    # Отслеживание интереса к услугам
  end
end
```

## 🔧 Technical Details

### Service Selection Algorithm
```ruby
def calculate_service_score(service, user_context, message)
  base_score = service.popularity_score
  context_score = analyze_relevance(service, user_context)
  message_score = extract_keywords(service, message)
  seasonal_score = apply_seasonal_factor(service)

  (base_score * 0.3 + context_score * 0.4 +
   message_score * 0.2 + seasonal_score * 0.1)
end
```

### AI Prompt Engineering
```ruby
def build_discovery_prompt(services)
  {
    system: SYSTEM_PROMPT,
    user: format_user_message(services),
    temperature: 0.7,
    max_tokens: 500
  }
end
```

### Response Validation
```ruby
def validate_discovery_response(response)
  # Проверка на наличие кнопок/меню
  # Проверка соответствия цен прайс-листу
  # Проверка естественности диалога
end
```

## 🧪 Testing Strategy

### Unit Tests
- ServicesDiscoveryService - core logic
- TopServicesSelector - selection algorithm
- AIPromptManager - prompt generation

### Integration Tests
- Ruby_LLM integration tests
- Price service integration
- Analytics tracking verification

### AI Quality Tests
- Service relevance validation
- Natural dialogue assessment
- Price accuracy verification

### End-to-End Tests
- Full discovery flow simulation
- Multiple user scenarios
- Edge cases handling

## 📊 Success Metrics

### Technical KPIs
- **Response time:** < 2 seconds (p95)
- **Service relevance:** > 95% accuracy
- **Natural dialogue score:** > 90%
- **System uptime:** > 99%

### Business KPIs
- **Conversion improvement:** 12% → 20%
- **User engagement:** 70% → 90%
- **Service discovery rate:** > 80% of conversations
- **Customer satisfaction:** NPS > 40

---

**Сложность реализации:** Complex
**Оценка времени:** 8 дней
**Необходимые ресурсы:** 1 developer + AI tuning
**Риски:** Средние (качество AI-ответов)