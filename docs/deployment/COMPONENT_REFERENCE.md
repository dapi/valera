# Valera Component Reference

## 🏗️ System Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Telegram Bot  │───▶│ Webhook Ctrl    │───▶│  Chat System    │
│   (External)    │    │ (Controller)    │    │   (Model)       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                        │
                                                        ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Analytics      │◀───│  Booking Tool   │◀───│   ruby_llm      │
│  Tracking       │    │  (AI Tool)      │    │  (AI Framework) │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 📋 Core Components

### Controllers Layer

#### **Telegram::WebhookController**
**Location**: `app/controllers/telegram/webhook_controller.rb`
**Purpose**: Handles all incoming Telegram webhook events

**Key Methods**:
- `message(message)` - Processes text messages
- `start!(*args)` - Handles /start command
- `reset!(*args)` - Handles /reset command
- `callback_query(data)` - Processes inline keyboard callbacks

**Dependencies**:
- `TelegramUser` - User management
- `Chat` - Dialog persistence
- `BookingTool` - AI tool integration
- `AnalyticsService` - Event tracking

**Flow**:
```
Telegram Message → Webhook → Analytics Context → AI Processing → Response
```

---

### Models Layer

#### **Chat**
**Location**: `app/models/chat.rb`
**Purpose**: Core dialog management with AI integration

**Key Features**:
- `acts_as_chat` - ruby_llm integration
- Automatic model assignment
- System prompt management
- Tool call handling

**Relationships**:
```ruby
belongs_to :telegram_user
has_many :messages, dependent: :destroy
has_many :tool_calls, through: :messages
has_many :bookings, dependent: :destroy
```

**Critical Methods**:
- `reset!` - Clears dialog context
- `say(text)` - Sends message to AI
- `with_instructions(prompt)` - Sets system prompt

#### **TelegramUser**
**Location**: `app/models/telegram_user.rb`
**Purpose**: Telegram user data management

**Key Features**:
- User identification via telegram_id
- User data synchronization
- Chat association

#### **Message**
**Location**: `app/models/message.rb`
**Purpose**: Individual message storage

**Attributes**:
- `role` (:user, :assistant, :system)
- `content` - Message text
- `model` - AI model used
- Token usage tracking

#### **Booking**
**Location**: `app/models/booking.rb`
**Purpose**: Automotive service booking records

**Features**:
- Service type tracking
- Customer details
- Status management
- Chat association

#### **AnalyticsEvent**
**Location**: `app/models/analytics_event.rb`
**Purpose**: System event tracking

**Features**:
- Event type categorization
- Chat-based filtering
- Timestamp tracking
- Property storage

---

### Services Layer

#### **SystemPromptService**
**Location**: `app/services/system_prompt_service.rb`
**Purpose**: AI system prompt management

**Key Features**:
- Prompt template loading
- Dynamic content injection
- Version management

#### **AnalyticsService**
**Location**: `app/services/analytics_service.rb`
**Purpose**: Event tracking and analytics

**Key Features**:
- Event registration
- Property tracking
- Background processing

**Sub-services**:
- `Analytics::ResponseTimeTracker` - Performance measurement
- `Analytics::ServiceSuggestionTracker` - Service usage analytics
- `Analytics::FallbackService` - Error tracking
- `Analytics::AlertService` - System alerts

#### **WelcomeService**
**Location**: `app/services/welcome_service.rb`
**Purpose**: User onboarding and greetings

**Features**:
- Personalized welcome messages
- User introduction handling

---

### Tools Layer

#### **BookingTool**
**Location**: `app/tools/booking_tool.rb`
**Purpose**: AI tool for creating service bookings

**Features**:
- AI-driven booking creation
- Parameter validation
- Context management

#### **BookingCreatorTool**
**Location**: `app/tools/booking_creator_tool.rb`
**Purpose**: Internal booking creation logic

**Features**:
- Booking record creation
- Data validation
- Integration with chat system

---

### Jobs Layer

#### **AnalyticsJob**
**Location**: `app/jobs/analytics_job.rb`
**Purpose**: Asynchronous analytics event processing

**Features**:
- Background event tracking
- Error handling
- Performance optimization

#### **BookingNotificationJob**
**Location**: `app/jobs/booking_notification_job.rb`
**Purpose**: Booking-related notifications

**Features**:
- Asynchronous notifications
- Status updates

---

### Concerns Layer

#### **ErrorLogger**
**Location**: `app/concerns/error_logger.rb`
**Purpose**: Centralized error logging

**Features**:
- Structured error logging
- Context preservation
- Bugsnag integration

#### **RescueErrors**
**Location**: `app/concerns/rescue_errors.rb`
**Purpose**: Controller-level error handling

**Features**:
- Graceful error responses
- User-friendly error messages

---

## 🔄 Data Flow Patterns

### Message Processing Flow
```
1. Telegram Message → WebhookController#message
2. Analytics Context Setup → RequestStore
3. Chat Retrieval/Creation → Chat model
4. Tool Configuration → BookingTool registration
5. AI Processing → ruby_llm with tools
6. Tool Execution → BookingCreatorTool
7. Response Generation → AI response
8. Telegram Response → Formatted message
9. Analytics Tracking → AnalyticsJob
```

### Booking Creation Flow
```
1. AI Tool Call → BookingTool
2. Parameter Validation → Tool logic
3. Booking Creation → BookingCreatorTool
4. Database Storage → Booking model
5. Chat Association → Booking record
6. Analytics Event → Service suggestion tracking
7. Notification → BookingNotificationJob (optional)
```

### Error Handling Flow
```
1. Error Detection → Any layer
2. Error Logging → ErrorLogger concern
3. Context Capture → Request data, user info
4. User Response → RescueErrors concern
5. Analytics Tracking → Error event
6. Bugsnag Notification → External monitoring
```

---

## 🔧 Configuration Management

### ApplicationConfig
**Location**: `config/configs/application_config.rb`
**Purpose**: Centralized configuration management

**Key Settings**:
- LLM provider and model
- API keys and endpoints
- Business information
- Feature flags

### Environment Configuration
- **Development**: Debug features, test data
- **Test**: Isolated environment, VCR integration
- **Production**: Optimized settings, monitoring

---

## 📊 Integration Points

### External Services
- **Telegram Bot API**: Message delivery and user interaction
- **DeepSeek API**: AI model processing (via ruby_llm)
- **Bugsnag**: Error monitoring and alerting
- **PostgreSQL**: Primary data storage
- **Redis**: Caching and job queue

### Internal Systems
- **Active Storage**: File handling and attachments
- **Solid Queue**: Background job processing
- **Solid Cache**: Performance optimization
- **Solid Cable**: Real-time features

---

## 🧪 Testing Structure

### Test Categories
- **Unit Tests**: Individual model and service testing
- **Integration Tests**: Complete workflow validation
- **System Tests**: End-to-end user scenarios
- **Performance Tests**: Analytics system validation

### Test Patterns
- **VCR Integration**: External API mocking
- **Factory Patterns**: Test data generation
- **Transaction Isolation**: Database state management
- **Context Setup**: Consistent test environments

---

## 🔍 Key Dependencies

### Rails Ecosystem
- `rails` 8.1.0 - Core framework
- `pg` - PostgreSQL adapter
- `puma` - Web server
- `solid_queue` - Job processing
- `solid_cache` - Caching layer

### AI & Bot Integration
- `ruby_llm` - AI framework integration
- `telegram-bot` - Telegram bot framework
- `kramdown` - Markdown processing
- `sanitize` - Content sanitization

### Development Tools
- `anyway_config` - Configuration management
- `bugsnag` - Error tracking
- `brakeman` - Security scanning
- `rubocop-rails-omakase` - Code styling

### Testing Framework
- `vcr` - HTTP interaction recording
- `webmock` - HTTP request stubbing
- `mocha` - Mocking and stubbing
- `capybara` - System testing

---

*Last Updated: 2025-10-27*
*Documentation Version: 3.0*