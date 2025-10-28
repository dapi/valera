# Technical Specification Document: TSD-009 - Запрос обратного звонка и запись на покрасочные работы

**Статус:** Draft
**Сложность:** Complex
**Приоритет:** High
**Создан:** 28.10.2025
**Обновлен:** 28.10.2025
**User Story:** [US-009-telegram-callback-paint-services.md](../user-stories/US-009-telegram-callback-paint-services.md)

## 🎯 Технические требования

### Functional Requirements
- [ ] **[FR-001]:** AI-сбор информации через естественный диалог
- [ ] **[FR-002]:** Автоматическое определение типа услуги (покраска/кузовной ремонт)
- [ ] **[FR-003]:** Сбор данных об автомобиле (марка, модель, год)
- [ ] **[FR-004]:** Сбор описания повреждений и объема работ
- [ ] **[FR-005]:** Создание заявок на обратный звонок
- [ ] **[FR-006]:** Создание записей на услуги в системе
- [ ] **[FR-007]:** Уведомление менеджеров о новых заявках

### Non-Functional Requirements
- [ ] **Performance:**
  - Information collection: < 3 минут для полного сбора данных
  - Request creation: < 30 секунд
  - AI response time: < 2 секунд на каждое сообщение
- [ ] **AI Quality:**
  - Information extraction accuracy: > 95%
  - Natural dialogue flow: > 90% user satisfaction
  - Service identification accuracy: > 98%
- [ ] **Reliability:**
  - Request creation success rate: > 99%
  - Manager notification reliability: > 99%
  - Data validation accuracy: > 98%
- [ ] **Scalability:**
  - Concurrent dialog handling: 100+ одновременных сборов
  - Request processing throughput: 500+ заявок/час
  - 24/7 availability для приема заявок

## 🏗️ Архитектура

### Components
1. **CallbackBookingService** - основная логика сбора информации
2. **InformationExtractor** - AI-экстракция данных из диалога
3. **ServiceClassifier** - определение типа услуги
4. **VehicleInfoProcessor** - обработка данных об автомобиле
5. **RequestCreator** - создание заявок и записей
6. **ManagerNotifier** - уведомление менеджеров
7. **BookingValidator** - валидация собранных данных

### Dialogue Flow Architecture
```
User Input → Intent Recognition → Information Collection → Validation → Request Creation
     ↓                ↓                     ↓              ↓             ↓
  Dialogue AI    Service Classifier   Data Extractor  Validator   Booking System
     ↓                ↓                     ↓              ↓             ↓
  Context Store   Service Mapping    Structured Data   Quality Check  Manager Notification
```

### Integration Points
- **Ruby_LLM:** AI-диалог и экстракция информации
- **Booking System:** создание записей и заявок
- **Manager Dashboard:** уведомления и обработка
- **Vehicle Database:** валидация данных об автомобилях
- **Service Catalog:** классификация услуг и ценообразование

## 📝 Implementation Plan

### Phase 1: Dialogue Information Collection (5 дней)
```ruby
# app/services/callback_booking_service.rb
class CallbackBookingService
  def initialize(telegram_user)
    @user = telegram_user
    @context = BookingContext.new
    @state_machine = BookingStateMachine.new
  end

  def process_message(message)
    intent = analyze_intent(message)
    response = handle_intent(intent, message)
    update_context(intent, message)
    response
  end

  private

  def analyze_intent(message)
    # AI-анализ намерения пользователя
    prompt = build_intent_analysis_prompt(message, @context)
    RubyLLM.analyze(prompt)
  end

  def handle_intent(intent, message)
    case @state_machine.current_state
    when :initial
      handle_initial_intent(intent, message)
    when :collecting_vehicle_info
      handle_vehicle_info(intent, message)
    when :collecting_damage_info
      handle_damage_info(intent, message)
    when :collecting_contact_info
      handle_contact_info(intent, message)
    end
  end
end
```

### Phase 2: Information Extraction AI (4 дня)
```ruby
# app/services/information_extractor.rb
class InformationExtractor
  def extract_vehicle_info(message)
    prompt = {
      system: "Извлеки информацию об автомобиле из сообщения. Верни JSON с полями: make, model, year, color.",
      user: message,
      response_format: { type: "json_object" }
    }

    response = RubyLLM.extract(prompt)
    parse_vehicle_info(response)
  end

  def extract_damage_info(message)
    prompt = {
      system: "Проанализируй повреждения автомобиля. Верни JSON с полями: damage_type, severity, affected_areas, estimated_work.",
      user: message,
      response_format: { type: "json_object" }
    }

    response = RubyLLM.extract(prompt)
    parse_damage_info(response)
  end

  def extract_contact_info(message)
    prompt = {
      system: "Извлеки контактную информацию. Верни JSON с полями: name, phone, preferred_time.",
      user: message,
      response_format: { type: "json_object" }
    }

    response = RubyLLM.extract(prompt)
    parse_contact_info(response)
  end
end
```

### Phase 3: Service Classification (3 дня)
```ruby
# app/services/service_classifier.rb
class ServiceClassifier
  PAINTING_SERVICES = %w[покраска кузовной ремонт малярные работы полировка]
  BODY_WORK_SERVICES = %w[кузовной ремонт ремонт кузова рихтовка]
  DETAILING_SERVICES = %w[полировка химчистка detailing]

  def classify_service(description, damage_info)
    keywords = extract_keywords(description)
    damage_keywords = extract_damage_keywords(damage_info)

    scores = calculate_service_scores(keywords, damage_keywords)
    determine_primary_service(scores)
  end

  private

  def calculate_service_scores(keywords, damage_keywords)
    {
      painting: calculate_paint_score(keywords, damage_keywords),
      body_work: calculate_body_score(keywords, damage_keywords),
      detailing: calculate_detailing_score(keywords)
    }
  end
end
```

### Phase 4: Request Creation System (3 дня)
```ruby
# app/services/request_creator.rb
class RequestCreator
  def create_callback_request(booking_data)
    ActiveRecord::Base.transaction do
      request = CallbackRequest.create!(
        telegram_user: booking_data[:user],
        name: booking_data[:contact][:name],
        phone: booking_data[:contact][:phone],
        preferred_time: booking_data[:contact][:preferred_time],
        service_type: booking_data[:service][:type],
        vehicle_info: booking_data[:vehicle],
        damage_info: booking_data[:damage],
        status: :pending
      )

      notify_managers(request)
      request
    end
  end

  def create_booking_request(booking_data)
    ActiveRecord::Base.transaction do
      booking = Booking.create!(
        telegram_user: booking_data[:user],
        service_type: booking_data[:service][:type],
        vehicle_info: booking_data[:vehicle],
        damage_description: booking_data[:damage][:description],
        estimated_duration: estimate_duration(booking_data),
        preferred_date: booking_data[:contact][:preferred_time],
        status: :pending_confirmation
      )

      notify_managers(booking)
      booking
    end
  end

  private

  def notify_managers(request)
    ManagerNotificationJob.perform_later(request)
  end
end
```

### Phase 5: Validation System (2 дня)
```ruby
# app/services/booking_validator.rb
class BookingValidator
  def validate_complete_data(booking_data)
    errors = []

    errors << validate_vehicle_info(booking_data[:vehicle])
    errors << validate_damage_info(booking_data[:damage])
    errors << validate_contact_info(booking_data[:contact])
    errors << validate_service_consistency(booking_data)

    errors
  end

  private

  def validate_vehicle_info(vehicle)
    errors = []
    errors << "Марка автомобиля обязательна" if vehicle[:make].blank?
    errors << "Модель автомобиля обязательна" if vehicle[:model].blank?
    errors << "Год выпуска должен быть валидным" unless valid_year?(vehicle[:year])
    errors
  end

  def validate_damage_info(damage)
    errors = []
    errors << "Опишите повреждения" if damage[:description].blank?
    errors << "Укажите тип повреждения" if damage[:type].blank?
    errors
  end

  def validate_contact_info(contact)
    errors = []
    errors << "Имя обязательно" if contact[:name].blank?
    errors << "Телефон обязателен" unless valid_phone?(contact[:phone])
    errors
  end
end
```

## 🔧 Technical Details

### AI Prompt Engineering
```ruby
def build_information_collection_prompt(context, current_field)
  case current_field
  when :vehicle
    {
      system: "Ты - вежливый ассистент автосервиса. Собери информацию об автомобиле естественно.",
      user: "Мне нужно узнать марку, модель и год выпуска автомобиля для точной консультации."
    }
  when :damage
    {
      system: "Спроси о повреждениях подробно, но вежливо.",
      user: "Опишите пожалуйста какие повреждения нужно исправить?"
    }
  when :contact
    {
      system: "Собери контактную информацию для связи.",
      user: "Как с вами связаться и когда вам удобно?"
    }
  end
end
```

### State Machine Implementation
```ruby
# app/services/booking_state_machine.rb
class BookingStateMachine
  STATES = {
    initial: [:collect_vehicle_info, :collect_damage_info, :collect_contact_info],
    collecting_vehicle_info: [:collect_damage_info, :collect_contact_info],
    collecting_damage_info: [:collect_contact_info],
    collecting_contact_info: [:complete]
  }.freeze

  def initialize
    @current_state = :initial
  end

  def transition(intent, extracted_data)
    case @current_state
    when :initial
      handle_initial_state(intent, extracted_data)
    when :collecting_vehicle_info
      handle_vehicle_collection(intent, extracted_data)
    # ... другие состояния
    end
  end
end
```

### Error Handling Strategy
```ruby
def handle_extraction_error(error_type, context)
  case error_type
  when :ai_service_unavailable
    fallback_to_manual_collection
  when :information_incomplete
    request_clarification(context)
  when :validation_failed
    provide_validation_feedback(context)
  end
end
```

## 🧪 Testing Strategy

### Unit Tests
- CallbackBookingService - dialogue flow management
- InformationExtractor - AI extraction accuracy
- ServiceClassifier - service identification logic

### Integration Tests
- Ruby_LLM integration tests for information extraction
- Request creation with Booking System
- Manager notification workflow

### End-to-End Tests
- Full callback request flow
- Full booking request flow
- Multiple service types and scenarios

### AI Quality Tests
- Information extraction accuracy validation
- Natural dialogue flow testing
- Service classification accuracy verification

## 📊 Success Metrics

### Technical KPIs
- **Information collection time:** < 3 minutes (average)
- **Data extraction accuracy:** > 95%
- **Request creation success rate:** > 99%
- **AI response time:** < 2 seconds (p95)

### Business KPIs
- **After-hours requests:** +40% from 6PM-9AM
- **Booking conversion:** +15-20% improvement
- **Staff workload reduction:** -25% routine tasks
- **Customer satisfaction:** NPS > 45

---

**Сложность реализации:** Complex
**Оценка времени:** 17 дней
**Необходимые ресурсы:** 1 developer + AI specialist
**Риски:** Средние (качество AI-экстракции, интеграция с системой записи)