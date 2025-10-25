# Protocol: RSpec Integration for Telegram Bot Testing

**Created:** 26.10.2025
**Status:** 🚀 Ready for Implementation
**Priority:** High (for Telegram bot functionality)

## 🎯 Executive Summary

Интеграция RSpec для тестирования Telegram бота в проекте Valera, сохраняя при этом Minitest для основной части Rails приложения.

## 📋 Context and Rationale

**Current State:**
- Valera project uses Minitest for all Rails testing
- Telegram bot webhook controller needs comprehensive testing
- Complex bot interactions require expressive test syntax

**Decision:**
- **RSpec** → Telegram webhook controller и сервисы
- **Minitest** → Основная часть приложения (модели, обычные контроллеры)
- **Изоляция** → Telegram тесты отдельно от основной кодовой базы

**Why RSpec for Telegram:**
- Встроенные хелперы `Telegram::Bot::RSpec::Integration`
- Более выразительный DSL для сложных сценариев бота
- Лучшие matchers для Telegram-specific структур данных
- Удобное мокирование Telegram API вызовов через `expect(Telegram.bot.api)`
- Простые fixtures вместо сложных factories для тестовых данных

## 🚀 Implementation Plan

### Phase 1: RSpec Installation (10 min)

#### 1.1 Gemfile Addition
```ruby
# Add to group :development, :test
group :development, :test do
  gem 'rspec-rails', '~> 6.0'
end
```

#### 1.2 Installation Commands
```bash
bundle install
rails generate rspec:install
```

### Phase 2: Basic Configuration (15 min)

#### 2.1 Telegram Helpers
**File: spec/support/telegram_helpers.rb**
```ruby
require 'telegram/bot/rspec/integration/rspec'

RSpec.configure do |config|
  config.include Telegram::Bot::RSpec::Integration, type: :request
  # Note: Telegram client is already stubbed in config/initializers for test mode
end
```

### Phase 3: Basic Webhook Test Template (15 min)

#### 3.1 Base Webhook Controller Test
**File: spec/controllers/telegram/webhook_controller_spec.rb**
```ruby
require 'rails_helper'

RSpec.describe Telegram::WebhookController, type: :request do
  include Telegram::Bot::RSpec::Integration

  let(:chat) { Telegram::Bot::Types::Chat.new(id: 12345, type: 'private') }
  let(:from) { Telegram::Bot::Types::User.new(id: 12345, first_name: 'Test', is_bot: false) }
  # Note: Telegram client is already stubbed in config/initializers for test mode

  describe 'POST #webhook' do
    context 'with /start command' do
      let(:message) { Telegram::Bot::Types::Message.new(text: '/start', chat: chat, from: from) }

      it 'returns 200 status' do
        dispatch_message(message)
        expect(response).to have_http_status(:ok)
      end

      it 'sends welcome message' do
        expect(Telegram.bot.api).to receive(:send_message).with(
          chat_id: chat.id,
          text: include('Добро пожаловать'),
          parse_mode: 'Markdown'
        )
        dispatch_message(message)
      end
    end
  end
end
```

#### 3.2 Additional Test Coverage
*Additional message type tests (photo, document, location, callback) will be created during User Story implementation as needed*

### Phase 4: Test Structure Setup (10 min)

#### 4.1 Directory Preparation
```bash
# Create directories for future test development
mkdir -p spec/services/telegram
mkdir -p spec/integration
```

#### 4.2 Future Test Coverage
*Service layer tests and integration tests will be created during User Story implementation as needed:*
- Message Handler Service tests (when implementing message processing logic)
- State Machine tests (when implementing conversation flows)
- Integration tests (when implementing end-to-end user journeys)

## 📋 File Structure

### Initial Setup
```
spec/
├── rails_helper.rb                 # Main RSpec configuration
├── spec_helper.rb                  # Base RSpec configuration
├── support/
│   ├── telegram_helpers.rb         # Telegram-specific helpers
│   └── message_fixtures.rb         # Test data fixtures
└── controllers/
    └── telegram/
        └── webhook_controller_spec.rb  # Basic webhook test
```

### Future Expansion (during User Stories)
```
spec/
├── services/telegram/              # Created when needed
│   └── message_handler_spec.rb     # When implementing services
└── integration/                    # Created when needed
    └── bot_conversation_spec.rb    # When testing end-to-end flows
```

## 🎯 Success Criteria

### Must Have (Critical)
- [ ] RSpec successfully installed alongside Minitest
- [ ] Telegram webhook controller tests pass
- [ ] All message types have test coverage
- [ ] Telegram API calls properly mocked
- [ ] Tests run in CI/CD without conflicts

### Should Have (Future User Stories)
- [ ] Service layer tests (created when implementing services)
- [ ] Integration tests (created when implementing user journeys)
- [ ] Error scenario testing (created during feature development)

### Could Have (Future Enhancements)
- [ ] Performance tests (created when needed)
- [ ] Visual regression tests (created when UI complexity increases)

## 🚨 Critical Implementation Notes

### Security Testing
```ruby
# Test webhook signature validation
it 'rejects unsigned webhook requests' do
  post '/telegram/webhook', params: malicious_payload
  expect(response).to have_http_status(:unauthorized)
end

# Test rate limiting
it 'applies rate limiting for excessive requests' do
  # Simulate rapid requests
  expect(response).to have_http_status(:too_many_requests)
end
```

### Product Constitution Compliance
```ruby
# Test dialogue-only principle
it 'does not use buttons or commands in responses' do
  dispatch_message(message)
  expect(Telegram.bot.api).not_to receive(:send_message).with(
    reply_markup: have_attributes(kind_of: Telegram::Bot::Types::InlineKeyboardMarkup)
  )
end

# Test visual analysis priority
it 'prioritizes photo analysis in conversation flow' do
  photo_message = create_photo_message
  dispatch_message(photo_message)
  expect(PhotoAnalysisService).to have_received(:call)
end
```

### Error Handling
```ruby
# Test network errors
it 'handles Telegram API timeouts gracefully' do
  allow(Telegram.bot.api).to receive(:send_message).and_raise(Telegram::Bot::Exceptions::ResponseError)
  # Expect proper error handling and logging
end
```

## 🔄 Testing Workflow Integration

### Running Tests
```bash
# Run only Telegram tests
bundle exec rspec spec/ --tag telegram

# Run all tests (RSpec + Minitest)
bundle exec rspec spec/ && rails test

# Run with coverage
bundle exec rspec spec/ --format documentation
```

### CI/CD Integration
```yaml
# .github/workflows/test.yml
- name: Run Telegram Bot Tests
  run: |
    bundle exec rspec spec/ --tag telegram --format RspecJunitFormatter --out rspec_results.xml
```

## 📊 Expected Outcomes

### Immediate Benefits
- **Better test coverage** for complex bot interactions
- **Easier debugging** of webhook issues
- **Improved confidence** in bot behavior changes
- **Better documentation** through living specifications

### Long-term Benefits
- **Easier onboarding** for new developers
- **Regression prevention** for bot functionality
- **Performance monitoring** through test metrics
- **Quality assurance** for user experience

## 🔄 Maintenance Guidelines

### Test Maintenance
- Keep tests updated with new bot features
- Regular review of mock configurations
- Update test data with new message types
- Monitor test execution times

### Integration Maintenance
- Keep RSpec and Rails versions compatible
- Update Telegram gem integration helpers
- Maintain separation between RSpec and Minitest
- Regular dependency updates

---

**Status:** ✅ Protocol ready for implementation
**Next Steps:** Await approval to begin Phase 1 implementation
**Estimated Total Time:** 40 minutes (initial setup only)
**Dependencies:** None (can be implemented independently)