# Valera API Reference

## 🤖 Telegram Webhook API v1

### Overview
Valera exposes a single webhook endpoint for Telegram Bot API integration. The webhook receives updates from Telegram and processes them through the AI system.

### Base URL
```
POST /telegram/webhook
```

### Authentication
- **Method**: Telegram Bot IP whitelisting
- **Security**: Webhook URL must be set in Telegram Bot API settings
- **SSL**: Required for production deployment

---

## 📥 Webhook Endpoint

### POST /telegram/webhook
Processes incoming updates from Telegram Bot API.

#### Request Headers
```
Content-Type: application/json
User-Agent: TelegramBotSDK/*
```

#### Request Body
```json
{
  "update_id": 123456789,
  "message": {
    "message_id": 1,
    "from": {
      "id": 123456789,
      "is_bot": false,
      "first_name": "John",
      "username": "john_doe",
      "language_code": "ru"
    },
    "chat": {
      "id": 123456789,
      "first_name": "John",
      "username": "john_doe",
      "type": "private"
    },
    "date": 1672531200,
    "text": "Hello, I want to book a service"
  }
}
```

#### Response
```json
{
  "method": "sendMessage",
  "chat_id": 123456789,
  "text": "Hello! I can help you book a service. What type of service do you need?",
  "parse_mode": "Markdown"
}
```

#### Response Codes
- **200**: Success - Message processed and response sent
- **400**: Bad Request - Invalid message format
- **500**: Internal Server Error - Processing failure

---

## 🎯 Supported Message Types

### Text Messages
```json
{
  "message": {
    "text": "Хочу записаться на ТО"
  }
}
```

### Commands
```json
{
  "message": {
    "text": "/start",
    "entities": [{"type": "bot_command", "offset": 0, "length": 6}]
  }
}
```

#### Supported Commands
- `/start` - Initialize bot and send welcome message
- `/reset` - Clear conversation history and start over

### Callback Queries
```json
{
  "callback_query": {
    "id": "123456789",
    "from": {...},
    "message": {...},
    "data": "button_click_data"
  }
}
```

---

## 🔄 Processing Flow

### Message Processing Pipeline
```
1. Telegram Update → Webhook Controller
2. User Identification → TelegramUser.find_or_create_by_telegram_data!
3. Chat Context → Chat.find_or_create_by!(telegram_user: user)
4. Analytics Setup → RequestStore context
5. Tool Configuration → BookingTool registration
6. AI Processing → ruby_llm chat.say(text)
7. Tool Execution → booking_creator tool calls
8. Response Generation → AI response with markdown
9. Telegram Reply → Formatted message sent to user
10. Analytics Tracking → Background job processing
```

### Error Handling
```json
{
  "method": "sendMessage",
  "chat_id": 123456789,
  "text": "Извините, произошла ошибка. Попробуйте еще раз.",
  "parse_mode": "Markdown"
}
```

---

## 🧠 AI Tool Integration

### Booking Tool
The AI system has access to a booking creation tool that can:

**Parameters**:
```json
{
  "name": "booking_creator",
  "description": "Create a new automotive service booking",
  "parameters": {
    "service_type": "string",
    "customer_name": "string",
    "phone": "string",
    "preferred_date": "string",
    "notes": "string"
  }
}
```

**Tool Call Example**:
```json
{
  "tool_calls": {
    "call_001": {
      "name": "booking_creator",
      "arguments": "{\"service_type\":\"ТО\",\"customer_name\":\"Иван\",\"phone\":\"+79991234567\"}"
    }
  }
}
```

---

## 📊 Analytics Events

### Tracked Events
- `DIALOG_STARTED` - First message of the day from user
- `MESSAGE_PROCESSED` - Each message processing completion
- `BOOKING_CREATED` - Successful booking creation
- `TOOL_CALL_EXECUTED` - AI tool execution
- `ERROR_OCCURRED` - System errors and exceptions

### Event Structure
```json
{
  "event_type": "DIALOG_STARTED",
  "chat_id": 123456789,
  "telegram_user_id": 456,
  "properties": {
    "message_type": "booking_intent",
    "platform": "telegram",
    "user_id": 456
  },
  "occurred_at": "2025-01-15T10:30:00Z"
}
```

---

## 🔧 Configuration API

### Environment Variables
```bash
# Telegram Bot Configuration
TELEGRAM_BOT_TOKEN=your_bot_token_here

# LLM Configuration
LLM_PROVIDER=deepseek
LLM_MODEL=deepseek-chat
DEEPSEEK_API_KEY=your_deepseek_api_key

# Database Configuration
DATABASE_URL=postgresql://user:pass@localhost/valera_development

# Analytics Configuration
ANALYTICS_ENABLED=true

# Monitoring Configuration
BUGSNAG_API_KEY=your_bugsnag_api_key
```

### ApplicationConfig
```ruby
# config/configs/application_config.rb
class ApplicationConfig < Anyway::Config
  attr_config :llm_provider, :llm_model, :company_name, :company_address

  # Company Information for AI responses
  attr_config :company_name, default: "Автосервис Валера"
  attr_config :company_address, default: "г. Москва, ул. Примерная, 123"
  attr_config :company_phone, default: "+7 (495) 123-45-67"
end
```

---

## 🛡️ Security Considerations

### Input Validation
- All user inputs are sanitized using Rails built-in protection
- Markdown content is cleaned using `MarkdownCleaner`
- SQL injection protection via ActiveRecord parameterized queries

### Rate Limiting
- Implemented via request tracking
- Analytics-based abuse detection
- Configurable rate limits per user

### Data Privacy
- User data encrypted at rest
- Message history stored securely
- Compliance with data protection regulations

---

## 🧪 Testing API

### VCR Cassettes
Test requests are recorded using VCR gem:
```ruby
# test/cassettes/BookingFlowTest/test_booking_creation.yml
http_interactions:
- request:
    method: post
    uri: https://api.deepseek.com/v1/chat/completions
    body:
      encoding: UTF-8
      string: '{"model":"deepseek-chat","messages":[...]}'
  response:
    status:
      code: 200
      message: OK
```

### Test Environment Setup
```ruby
# test/telegram_support.rb
def telegram_webhook_payload(message_text)
  {
    "message" => {
      "text" => message_text,
      "chat" => {"id" => 12345},
      "from" => {"id" => 12345, "first_name" => "Test"}
    }
  }
end
```

---

## 📈 Performance Metrics

### Response Time Tracking
```ruby
Analytics::ResponseTimeTracker.measure(
  chat_id,
  'telegram_message_processing',
  'deepseek-chat'
) do
  # AI processing logic
end
```

### Monitored Metrics
- Average response time per message
- Tool execution success rate
- Error rates by type
- User engagement patterns

---

## 🔍 Debug Information

### Logging Levels
- **DEBUG**: Tool calls, AI responses
- **INFO**: Message processing, user actions
- **WARN**: Retry attempts, fallbacks
- **ERROR**: Exception details, failure contexts

### Debug Headers
```ruby
# Request context for debugging
RequestStore.store[:analytics_request_id] = SecureRandom.uuid
RequestStore.store[:analytics_start_time] = Time.current
```

---

## 📚 SDK Integration Examples

### Ruby on Rails Integration
```ruby
class TelegramWebhookController < ApplicationController
  include Telegram::Bot::UpdatesController

  def message(message)
    chat = Chat.find_or_create_by!(telegram_user: telegram_user)
    response = chat.say(message['text'])

    respond_with :message,
      text: MarkdownCleaner.clean(response.content),
      parse_mode: 'Markdown'
  end
end
```

### Direct API Usage
```bash
curl -X POST https://your-domain.com/telegram/webhook \
  -H "Content-Type: application/json" \
  -d '{
    "message": {
      "text": "Test message",
      "chat": {"id": 12345}
    }
  }'
```

---

## 🆘 Troubleshooting

### Common Issues
1. **Webhook not receiving updates**
   - Verify webhook URL is set in BotFather
   - Check SSL certificate validity
   - Confirm server accessibility

2. **AI responses not generating**
   - Verify DeepSeek API key configuration
   - Check LLM model availability
   - Review error logs

3. **Tool calls failing**
   - Validate tool parameter format
   - Check booking creation logic
   - Review analytics tracking

### Error Response Format
```json
{
  "error": {
    "type": "ProcessingError",
    "message": "Failed to process message",
    "details": "LLM service unavailable"
  }
}
```

---

*Last Updated: 2025-10-27*
*API Version: 1.0*
*Documentation Version: 3.0*