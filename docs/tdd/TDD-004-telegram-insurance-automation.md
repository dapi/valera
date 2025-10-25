# Technical Design Document: TDD-004 - Автоматизация страховых случаев (ОСАГО/КАСКО)

**Статус:** Draft
**Сложность:** Complex
**Приоритет:** Low
**Создан:** 25.10.2025
**Обновлен:** 25.10.2025
**User Story:** [../requirements/user-stories/US-004-telegram-insurance-automation.md](../requirements/user-stories/US-004-telegram-insurance-automation.md)

## 🎯 User Story

**As a** владелец автомобиля, попавший в ДТП
**I want to** получить помощь с оформлением страхового случая через Telegram бот
**so that** я могу быстро и правильно подготовить документы и избежать ошибок при общении со страховой компанией

### Критерии приемки
- [ ] **Functional:** Клиент получает пошаговую помощь с оформлением документов
- [ ] **User Experience:** 90% пользователей успешно готовят документы, экономия времени > 2 часов
- [ ] **Performance:** Генерация документов < 30 секунд, точность заполнения > 95%

## 🎯 Технические требования

### Functional Requirements
- [ ] **FR-001:** AI определяет тип страховки (ОСАГО/КАСКО) и необходимые документы
- [ ] **FR-002:** Пошаговая инструкция по действиям после ДТП
- [ ] **FR-003:** Автоматическое заполнение шаблонов документов (извещение о ДТП, заявление)
- [ ] **FR-004:** Расчет ориентировочной суммы страхового возмещения
- [ ] **FR-005:** Чек-лист необходимых фото и документов
- [ ] **FR-006:** Интеграция с базой данных страховых компаний и их требований

### Non-Functional Requirements
- [ ] **Security:** Конфиденциальность данных о ДТП и страховке
- [ ] **Performance:** Генерация документов < 30 секунд
- [ ] **Accuracy:** Точность заполнения документов > 95%
- [ ] **Compliance:** Соответствие законодательству об ОСАГО/КАСКО
- [ ] **Multilingual:** Поддержка русского языка с юридической терминологией

## 🏗️ Architecture & Design

### System Components
```
┌─────────────────┐    ┌──────────────┐    ┌─────────────────┐
│   Telegram Bot  │───▶│  Insurance   │───▶│ Document        │
│                 │    │  Classifier  │    │ Generator       │
└─────────────────┘    └──────────────┘    └─────────────────┘
                                                      │
                                                      ▼
┌─────────────────┐    ┌──────────────┐    ┌─────────────────┐
│   Guidance      │◀───│ Template     │◀───│ Legal Database  │
│   System        │    │ Engine       │    │                 │
└─────────────────┘    └──────────────┘    └─────────────────┘
```

### Data Models
```ruby
class InsuranceClaim < ApplicationRecord
  belongs_to :chat

  # Детали ДТП
  string :insurance_type # 'osago' or 'kasko'
  string :accident_date
  string :accident_location
  text :accident_description

  # Участники
  jsonb :participants_info
  jsonb :witnesses_info
  jsonb :vehicle_info

  # Документы
  jsonb :required_documents
  jsonb :generated_documents
  jsonb :photo_requirements

  # Оценка
  decimal :estimated_compensation
  string :recommendations

  # Статус
  string :status, default: 'initial'
  datetime :completed_at
end
```

### Document Templates
```ruby
class DocumentGenerator
  def generate_osago_notification(claim_info)
    # Generate standardized ОСАГО извещение о ДТП
  end

  def generate_kasko_statement(claim_info)
    # Generate КАСКО заявление о страховом случае
  end

  def generate_photo_checklist(claim_info)
    # Generate checklist of required photos
  end
end
```

## 💾 Database Schema

### New Tables
```sql
CREATE TABLE insurance_claims (
  id BIGINT PRIMARY KEY,
  chat_id BIGINT REFERENCES chats(id),

  -- Accident details
  insurance_type VARCHAR(20),
  accident_date DATE,
  accident_location TEXT,
  accident_description TEXT,

  -- Participants
  participants_info JSONB,
  witnesses_info JSONB,
  vehicle_info JSONB,

  -- Documents
  required_documents JSONB,
  generated_documents JSONB,
  photo_requirements JSONB,

  -- Assessment
  estimated_compensation DECIMAL(12,2),
  recommendations TEXT,

  -- Status
  status VARCHAR(50) DEFAULT 'initial',
  completed_at TIMESTAMP,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);

CREATE TABLE insurance_templates (
  id BIGINT PRIMARY KEY,
  template_type VARCHAR(100), -- 'osago_notification', 'kasko_statement'
  insurance_company VARCHAR(100),
  template_content TEXT,
  required_fields JSONB,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);
```

## 🔧 Implementation Details

### Insurance Processing Pipeline
```ruby
class InsurancePipeline
  def process_claim(user_input, chat)
    # 1. Определить тип страховки
    insurance_type = InsuranceClassifier.classify(user_input)

    # 2. Собрать информацию о ДТП
    accident_info = AccidentInfoCollector.collect(user_input)

    # 3. Определить необходимые документы
    required_docs = DocumentRequirements.get(insurance_type, accident_info)

    # 4. Сгенерировать шаблоны
    templates = DocumentGenerator.generate(insurance_type, accident_info)

    # 5. Предоставить пошаговую инструкцию
    guidance = GuidanceGenerator.generate(insurance_type, accident_info)
  end
end
```

### System Prompts for Insurance AI
```text
Ты - страховой эксперт с 15-летним опытом работы с ОСАГО и КАСКО.

Помоги клиенту с оформлением страхового случая:

1. Определи тип страховки (ОСАГО/КАСКО)
2. Собери информацию о ДТП (дата, место, участники)
3. Составь список необходимых документов
4. Предоставь пошаговую инструкцию
5. Заполни шаблоны документов
6. Рассчитай ориентировочную сумму возмещения

Используй точную юридическую терминологию, но объясняй понятным языком.
```

## 📱 User Experience Flow

```
Пользователь: "Попал в ДТП, что делать?"
Система: "Сочувствую! У вас ОСАГО или КАСКО?"

Пользователь: "ОСАГО"
Система: "Хорошо, помогу с оформлением. Несколько вопросов:
1. Дата и место ДТП?
2. Есть ли пострадавшие?
3. Вызывали ли ГИБДД?
4. Есть ли свидетели?"

[Сбор информации]

Система: "Вот пошаговая инструкция:
1. ✅ Оформите извещение о ДТП (я помогу заполнить)
2. 📸 Сделайте фото места ДТП с разных ракурсов
3. 📄 Подготовьте документы: права, СТС, полис ОСАГО
4. 🏢 Обратитесь в страховую в течение 5 дней

Заполню извещение о ДТП. Нужна информация о втором участнике..."
```

## 📋 Document Templates

### ОСАГО Извещение о ДТП
```ruby
class OsagoNotificationGenerator
  def fill_template(claim_info)
    {
      section_a: {
        driver_info: claim_info.driver_info,
        vehicle_info: claim_info.vehicle_info,
        insurance_info: claim_info.insurance_info
      },
      section_b: {
        accident_circumstances: claim_info.accident_details,
        damage_description: claim_info.damage_info,
        witness_info: claim_info.witnesses
      },
      section_c: {
        opinions: claim_info.disagreements,
        notes: claim_info.additional_info
      }
    }
  end
end
```

## 🧪 Testing Strategy

### Unit Tests
- [ ] Insurance classification accuracy
- [ ] Document template filling
- [ ] Legal requirement validation
- [ ] Compensation calculation

### Integration Tests
- [ ] Document generation
- [ ] Legal database queries
- [ ] Template rendering
- [ ] Error handling

### Compliance Tests
- [ ] ОСАГО/КАСКО regulation compliance
- [ ] Document format validation
- [ ] Legal accuracy verification

## 🔒 Security & Privacy

### Data Protection
- Encryption of sensitive claim information
- Automatic deletion of claim data after 30 days
- User consent for data processing
- Compliance with privacy laws

### Legal Compliance
- Regular updates to reflect legislation changes
- Legal review of all templates and procedures
- Disclaimer about non-legal-advice nature

## 🚀 Deployment & Monitoring

### Monitoring Metrics
- Claim processing success rate
- Document generation accuracy
- User satisfaction with guidance
- Time savings compared to manual process

### Error Handling
- Fallback to general guidance when specific templates unavailable
- Clear disclaimers about legal advice limitations
- Escalation to human experts for complex cases

## 📋 Open Questions

1. **Legal Liability:** Disclaimer requirements for insurance guidance
2. **Template Updates:** Process for updating templates with law changes
3. **Integration:** Integration with insurance company systems
4. **Multilingual:** Need for English templates

## 🔗 Dependencies

- **US-003:** Photo damage assessment for documentation
- **Legal Database:** Current insurance legislation and templates
- **Document Engine:** Template generation and filling system
- **User Management:** Secure claim information handling

---

**Implementation Priority:** Low (Phase 3 - Advanced)
**Estimated Effort:** 4-6 недель
**Team Required:** Backend Developer + Legal Consultant