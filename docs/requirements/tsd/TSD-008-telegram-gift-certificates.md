# Technical Specification Document: TSD-008 - AI-персонализированные Подарочные Сертификаты

**Статус:** Draft
**Сложность:** Complex
**Приоритет:** High
**Создан:** 28.10.2025
**Обновлен:** 28.10.2025
**User Story:** [US-008-telegram-gift-certificates.md](../user-stories/US-008-telegram-gift-certificates.md)

## 🎯 Технические требования

### Functional Requirements
- [ ] **[FR-001]:** AI-детектирование "уходящих" клиентов из диалога
- [ ] **[FR-002]:** Персонализация предложения на основе анализа диалога
- [ ] **[FR-003]:** Автоматическая генерация уникальных промокодов
- [ ] **[FR-004]:** Естественная презентация сертификата через dialogue
- [ ] **[FR-005]:** Интеграция с системой применения скидок
- [ ] **[FR-006]:** Отслеживание использования сертификатов

### Non-Functional Requirements
- [ ] **Performance:**
  - Departure detection: < 5 секунд для анализа диалога
  - Certificate generation: < 3 секунд
  - Redemption processing: < 1 секунда
- [ ] **AI Quality:**
  - Departure detection accuracy: > 85%
  - Personalization relevance: > 80%
  - Natural dialogue integration: > 90%
- [ ] **Security:**
  - Unique code generation: криптографическая защита промокодов
  - Fraud prevention: защита от многократного использования
  - Data privacy: защита персональных данных клиентов
- [ ] **Reliability:**
  - Certificate availability: > 99.5%
  - Redemption processing: > 99%成功率
  - Error handling: graceful degradation при проблемах

## 🏗️ Архитектура

### Components
1. **DepartureDetectorService** - AI-анализ ухода клиента
2. **CertificatePersonalizer** - персонализация предложений
3. **PromoCodeGenerator** - генерация уникальных кодов
4. **CertificateManager** - управление жизненным циклом
5. **RedemptionService** - применение сертификатов
6. **CertificateAnalytics** - отслеживание эффективности

### Data Flow Architecture
```
Dialogue Analysis → Departure Detection → Personalization → Certificate Creation → User Notification
                                      ↓                              ↓
                               User Profile Analytics         Redemption System
                                      ↓                              ↓
                             Offer Optimization            Usage Analytics
```

### Integration Points
- **Ruby_LLM:** анализ диалога и генерация ответов
- **PromoCode System:** создание и валидация сертификатов
- **Booking System:** применение скидок при записи
- **Analytics:** отслеживание ROI и эффективности
- **User Profile:** хранение истории взаимодействий

## 📝 Implementation Plan

### Phase 1: Departure Detection (4 дня)
```ruby
# app/services/departure_detector_service.rb
class DepartureDetectorService
  def initialize(dialogue_history, user_context)
    @dialogue = dialogue_history
    @context = user_context
  end

  def detect_departure?
    # AI-анализ признаков ухода:
    # - Пользователь говорит о необходимости подумать
    # - Прощание без следующего шага
    # - Длительное отсутствие ответа
    # - Вопросы о конкурентах
    analyze_dialogue_signals
  end

  private

  def analyze_dialogue_signals
    # Использование Ruby_LLM для анализа диалога
    prompt = build_departure_analysis_prompt
    response = RubyLLM.analyze(prompt, @dialogue)
    parse_departure_signals(response)
  end
end
```

### Phase 2: Personalization Engine (3 дня)
```ruby
# app/services/certificate_personalizer.rb
class CertificatePersonalizer
  def personalize_certificate(user_id, dialogue_content)
    user_profile = build_user_profile(user_id)
    interests = extract_interests(dialogue_content)
    offer_type = select_certificate_type(user_profile, interests)

    {
      type: offer_type,
      discount: calculate_discount(offer_type, user_profile),
      services: recommend_services(interests),
      personalization: build_personalization_message(user_profile, interests)
    }
  end
end
```

### Phase 3: Certificate Generation (2 дня)
```ruby
# app/services/promo_code_generator.rb
class PromoCodeGenerator
  def generate_certificate(personalization)
    loop do
      code = generate_unique_code
      break code unless Certificate.exists?(code: code)
    end
  end

  private

  def generate_unique_code
    # Криптографически безопасный генератор
    "GIFT#{SecureRandom.hex(4).upcase}"
  end
end

# app/models/certificate.rb
class Certificate < ApplicationRecord
  belongs_to :user
  belongs_to :telegram_user

  validates :code, uniqueness: true
  validates :discount, numericality: { greater_than: 0, less_than_or_equal_to: 100 }

  scope :active, -> { where(expires_at: ..., used_at: nil) }
end
```

### Phase 4: Integration with Booking System (2 дня)
```ruby
# app/services/redemption_service.rb
class RedemptionService
  def redeem_certificate(code, booking_params)
    certificate = Certificate.find_by(code: code, used_at: nil)

    raise InvalidCertificateError unless certificate&.active?

    ActiveRecord::Base.transaction do
      # Применение скидки к записи
      booking = create_booking_with_discount(booking_params, certificate)

      # Маркировка сертификата как использованного
      certificate.update!(used_at: Time.current, booking: booking)

      booking
    end
  end
end
```

## 🔧 Technical Details

### AI Departure Detection Algorithm
```ruby
def build_departure_analysis_prompt
  {
    system: "Анализируй диалог и определяй признаки ухода клиента. Оцени вероятность ухода от 0 до 100.",
    user: format_dialogue_for_analysis,
    response_format: { type: "json_schema", schema: DEPARTURE_SCHEMA }
  }
end

DEPARTURE_SCHEMA = {
  type: "object",
  properties: {
    departure_probability: { type: "number" },
    departure_signals: { type: "array", items: { type: "string" } },
    recommended_action: { type: "string" }
  }
}
```

### Certificate Types Logic
```ruby
def select_certificate_type(user_profile, interests)
  case
  when user_profile.first_time_visitor?
    :first_time_discount
  when interests.has_specific_service?
    :service_specific
  when user_profile.price_sensitive?
    :fixed_amount
  when interests.has_urgent_need?
    :express_service
  else
    :general_discount
  end
end

def calculate_discount(type, profile)
  discounts = {
    first_time_discount: 15,
    service_specific: 20,
    fixed_amount: 2000,
    express_service: 10,
    general_discount: 10
  }

  base_discount = discounts[type]
  apply_personal_factors(base_discount, profile)
end
```

### Natural Certificate Presentation
```ruby
def build_certificate_presentation(certificate, personalization)
  prompt = {
    system: "Предложи подарочный сертификат естественно и эмпатично, без навязчивости.",
    user: format_certificate_context(certificate, personalization),
    temperature: 0.8
  }

  RubyLLM.generate(prompt)
end
```

## 🧪 Testing Strategy

### Unit Tests
- DepartureDetectorService - AI departure detection accuracy
- CertificatePersonalizer - personalization logic
- PromoCodeGenerator - uniqueness and security

### Integration Tests
- Ruby_LLM integration tests for departure detection
- Certificate redemption flow tests
- Analytics tracking verification

### End-to-End Tests
- Full certificate lifecycle: detection → generation → redemption
- Multiple personalization scenarios
- Edge cases and error handling

### AI Quality Tests
- Departure detection accuracy validation
- Personalization relevance assessment
- Natural dialogue integration testing

## 📊 Success Metrics

### Technical KPIs
- **Departure detection accuracy:** > 85%
- **Certificate generation time:** < 3 seconds
- **Redemption success rate:** > 99%
- **Personalization relevance:** > 80%

### Business KPIs
- **Return rate of departing users:** 15% → 35%
- **Customer lifetime value:** +25%
- **Certificate ROI:** 8-10 months payback
- **Customer satisfaction:** NPS improvement +15 points

---

**Сложность реализации:** Complex
**Оценка времени:** 11 дней
**Необходимые ресурсы:** 1 developer + AI specialist
**Риски:** Средние (точность AI-детекции, качество персонализации)