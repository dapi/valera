# Technical Specification Document: TSD-011 - Явная передача диалога от бота к менеджеру

**Статус:** Draft
**Сложность:** Complex
**Приоритет:** Medium
**Создан:** 28.12.2025
**Обновлен:** 28.12.2025
**User Story:** [US-010-tenant-chat-takeover.md](../user-stories/US-010-tenant-chat-takeover.md)
**GitHub Issue:** [#103](https://github.com/dapi/valera/issues/103)

## Технические требования

### Functional Requirements

- [ ] **[FR-001]:** Chat может находиться в двух режимах: `ai_mode` (по умолчанию) и `manager_mode`
- [ ] **[FR-002]:** При `manager_mode` AI-бот НЕ отвечает автоматически на входящие сообщения
- [ ] **[FR-003]:** Менеджер может отправлять сообщения клиенту через Telegram API от имени бота
- [ ] **[FR-004]:** При takeover клиенту автоматически отправляется уведомление о переключении
- [ ] **[FR-005]:** При release клиенту автоматически отправляется уведомление о возврате к боту
- [ ] **[FR-006]:** Авто-возврат к `ai_mode` через 30 минут неактивности менеджера
- [ ] **[FR-007]:** Все действия takeover/release логируются в audit log
- [ ] **[FR-008]:** Сообщения менеджера отображаются в истории чата с пометкой `[Менеджер]`

### Non-Functional Requirements

- [ ] **Performance:**
  - Takeover operation: < 500ms (p95)
  - Message send: < 2s (p95)
  - UI state update: < 300ms
- [ ] **Security:**
  - Только авторизованные пользователи tenant'а могут делать takeover
  - Rate limiting: max 60 сообщений/час на чат
  - Audit log всех операций
- [ ] **Scalability:**
  - Поддержка до 100 одновременных takeover на tenant
  - Background job для таймаутов масштабируется горизонтально
- [ ] **Availability:**
  - Graceful degradation: если takeover недоступен, чат работает в ai_mode
  - Retry logic для отправки сообщений в Telegram

## Архитектура и компоненты

### System Architecture

```yaml
pattern: "Layered Architecture"
approach: "Synchronous API + Async Background Jobs"
style: "Service-oriented with ActiveRecord models"
```

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Tenant Dashboard                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │ ChatsIndex  │  │ ChatShow    │  │ TakeoverControls       │  │
│  │ (list)      │──│ (messages)  │──│ [Takeover] [Release]   │  │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘  │
└────────────────────────────┬────────────────────────────────────┘
                             │ Turbo Streams
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Rails Controllers                             │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ Tenants::ChatsController                                │    │
│  │   #index, #show, #takeover, #release, #send_message     │    │
│  └─────────────────────────────────────────────────────────┘    │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Service Layer                                 │
│  ┌──────────────────┐  ┌──────────────────┐  ┌────────────────┐ │
│  │ ChatTakeoverSvc  │  │ ManagerMessageSvc│  │ AuditLogService│ │
│  │ .takeover!       │  │ .send!           │  │ .log_takeover  │ │
│  │ .release!        │  │ .notify_client!  │  │ .log_release   │ │
│  └──────────────────┘  └──────────────────┘  └────────────────┘ │
└────────────────────────────┬────────────────────────────────────┘
                             │
          ┌──────────────────┼──────────────────┐
          ▼                  ▼                  ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│     Chat        │  │   Message       │  │  Background     │
│ mode: enum      │  │ sender_type     │  │  Jobs           │
│ taken_by: User  │  │ :ai/:manager    │  │ TakeoverTimeout │
│ taken_at: time  │  │                 │  │ Job             │
└─────────────────┘  └─────────────────┘  └─────────────────┘
          │                  │
          ▼                  ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Telegram API                                  │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ Tenant#bot_client.send_message(chat_id, text)           │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

### Sequence Diagram: Takeover Flow

```
Менеджер          Dashboard         ChatsController      ChatTakeoverService      Telegram API
    │                 │                    │                      │                     │
    │──[Взять диалог]─▶│                   │                      │                     │
    │                 │──POST /takeover───▶│                      │                     │
    │                 │                    │───takeover!(chat)───▶│                     │
    │                 │                    │                      │──send_message──────▶│
    │                 │                    │                      │  "Вас переключили"  │
    │                 │                    │                      │◀─────ok─────────────│
    │                 │                    │                      │                     │
    │                 │                    │                      │──schedule_timeout──▶│
    │                 │                    │◀──────chat───────────│   (30 min)          │
    │                 │◀──Turbo Stream─────│                      │                     │
    │◀──UI Updated────│                    │                      │                     │
```

### Components

```yaml
components:
  - name: "ChatTakeoverService"
    type: "Service"
    responsibility: "Управление takeover/release, отправка уведомлений"
    dependencies: ["Chat", "User", "Telegram API", "SolidQueue"]
    interfaces:
      - "takeover!(chat, user) -> chat"
      - "release!(chat, timeout: false) -> chat"
      - "extend_timeout!(chat) -> void"
    scaling: "Stateless, горизонтальное масштабирование"

  - name: "ManagerMessageService"
    type: "Service"
    responsibility: "Отправка сообщений менеджера клиенту"
    dependencies: ["Chat", "Message", "Telegram API"]
    interfaces:
      - "send!(chat, user, text) -> message"
    scaling: "Stateless"

  - name: "ChatTakeoverTimeoutJob"
    type: "Background Job"
    responsibility: "Автоматический release после таймаута"
    dependencies: ["Chat", "ChatTakeoverService"]
    interfaces:
      - "perform(chat_id)"
    scaling: "SolidQueue workers"

  - name: "Tenants::ChatsController"
    type: "Controller"
    responsibility: "API для takeover/release/send_message"
    dependencies: ["ChatTakeoverService", "ManagerMessageService"]
    interfaces:
      - "POST /chats/:id/takeover"
      - "POST /chats/:id/release"
      - "POST /chats/:id/send_message"
    scaling: "Puma workers"
```

### Data Architecture

```yaml
data_models:
  - name: "Chat (extended)"
    purpose: "Добавить поля для режима takeover"
    new_fields:
      - "mode: integer, enum [:ai_mode, :manager_mode], default: :ai_mode"
      - "taken_by_id: bigint, references: users, nullable: true"
      - "taken_at: datetime, nullable: true"
    relationships: "belongs_to :taken_by, class_name: 'User', optional: true"
    indexing: ["tenant_id + mode", "taken_by_id"]
    validations:
      - "taken_by и taken_at обязательны при manager_mode"
      - "taken_by должен иметь доступ к tenant"

  - name: "Message (extended)"
    purpose: "Различать отправителя: AI или менеджер"
    new_fields:
      - "sender_type: integer, enum [:ai, :manager, :client, :system], default: :ai"
      - "sender_id: bigint, references: users, nullable: true"
    relationships: "belongs_to :sender, class_name: 'User', optional: true"
    indexing: ["chat_id + sender_type"]
    validations:
      - "sender_id обязателен при sender_type: :manager"

  - name: "ChatTakeoverLog (new)"
    purpose: "Audit log для операций takeover/release"
    key_fields:
      - "chat_id: bigint, not null"
      - "user_id: bigint, not null"
      - "action: string, enum ['takeover', 'release', 'timeout', 'send_message']"
      - "metadata: jsonb"
      - "created_at: datetime"
    relationships: "belongs_to :chat, belongs_to :user"
    indexing: ["chat_id + created_at", "user_id + created_at"]

data_flow:
  takeover:
    - trigger: "POST /chats/:id/takeover"
    - validation: "user has access to tenant"
    - update: "chat.update!(mode: :manager_mode, taken_by: user, taken_at: Time.current)"
    - notify: "Telegram API: send notification to client"
    - schedule: "ChatTakeoverTimeoutJob.set(wait: 30.minutes).perform_later(chat.id)"
    - log: "ChatTakeoverLog.create!(action: 'takeover')"
    - broadcast: "Turbo::StreamsChannel.broadcast_replace_to(...)"

  release:
    - trigger: "POST /chats/:id/release OR timeout job"
    - update: "chat.update!(mode: :ai_mode, taken_by: nil, taken_at: nil)"
    - notify: "Telegram API: send return notification to client"
    - log: "ChatTakeoverLog.create!(action: timeout ? 'timeout' : 'release')"
    - broadcast: "Turbo::StreamsChannel.broadcast_replace_to(...)"
```

## Интеграция с существующим кодом

### Изменения в WebhookController

```ruby
# app/controllers/telegram/webhook_controller.rb
def message(message)
  return unless text_message?(message)

  # ... existing checks ...

  # NEW: Check if chat is in manager_mode
  if llm_chat.manager_mode?
    # Don't auto-respond, just save message
    save_client_message(message['text'])
    broadcast_new_message_to_dashboard(llm_chat)
    return
  end

  # ... existing AI processing ...
end

private

def save_client_message(text)
  llm_chat.messages.create!(
    role: :user,
    content: text,
    sender_type: :client
  )
end

def broadcast_new_message_to_dashboard(chat)
  Turbo::StreamsChannel.broadcast_append_to(
    "tenant_#{chat.tenant_id}_chat_#{chat.id}",
    target: "chat_messages",
    partial: "tenants/chats/message",
    locals: { message: chat.messages.last }
  )
end
```

### Изменения в Chat модели

```ruby
# app/models/chat.rb
class Chat < ApplicationRecord
  # ... existing code ...

  # NEW: Takeover support
  enum :mode, { ai_mode: 0, manager_mode: 1 }, default: :ai_mode

  belongs_to :taken_by, class_name: 'User', optional: true

  validates :taken_by, presence: true, if: :manager_mode?
  validates :taken_at, presence: true, if: :manager_mode?

  scope :in_manager_mode, -> { where(mode: :manager_mode) }
  scope :taken_by_user, ->(user) { where(taken_by: user) }

  def takeover_time_remaining
    return nil unless manager_mode? && taken_at

    timeout_at = taken_at + ChatTakeoverService::TIMEOUT_DURATION
    [timeout_at - Time.current, 0].max
  end

  def takeover_expired?
    manager_mode? && taken_at && taken_at < ChatTakeoverService::TIMEOUT_DURATION.ago
  end
end
```

## План реализации

### Phase 1: Database & Models (4 часа)

- [ ] **Migration: Add takeover fields to chats**
  ```ruby
  # db/migrate/YYYYMMDDHHMMSS_add_takeover_to_chats.rb
  class AddTakeoverToChats < ActiveRecord::Migration[8.0]
    def change
      add_column :chats, :mode, :integer, default: 0, null: false
      add_column :chats, :taken_by_id, :bigint
      add_column :chats, :taken_at, :datetime

      add_index :chats, [:tenant_id, :mode]
      add_index :chats, :taken_by_id
      add_foreign_key :chats, :users, column: :taken_by_id
    end
  end
  ```

- [ ] **Migration: Add sender_type to messages**
  ```ruby
  # db/migrate/YYYYMMDDHHMMSS_add_sender_type_to_messages.rb
  class AddSenderTypeToMessages < ActiveRecord::Migration[8.0]
    def change
      add_column :messages, :sender_type, :integer, default: 0, null: false
      add_column :messages, :sender_id, :bigint

      add_index :messages, [:chat_id, :sender_type]
      add_foreign_key :messages, :users, column: :sender_id
    end
  end
  ```

- [ ] **Migration: Create chat_takeover_logs**
  ```ruby
  # db/migrate/YYYYMMDDHHMMSS_create_chat_takeover_logs.rb
  class CreateChatTakeoverLogs < ActiveRecord::Migration[8.0]
    def change
      create_table :chat_takeover_logs do |t|
        t.references :chat, null: false, foreign_key: true
        t.references :user, null: false, foreign_key: true
        t.string :action, null: false
        t.jsonb :metadata, default: {}
        t.timestamps
      end

      add_index :chat_takeover_logs, [:chat_id, :created_at]
      add_index :chat_takeover_logs, [:user_id, :created_at]
    end
  end
  ```

- [ ] **Update Chat model** with enum, associations, validations
- [ ] **Update Message model** with sender_type enum
- [ ] **Create ChatTakeoverLog model**

### Phase 2: Services (6 часов)

- [ ] **ChatTakeoverService**
  ```ruby
  # app/services/chat_takeover_service.rb
  class ChatTakeoverService
    include ErrorLogger

    TIMEOUT_DURATION = 30.minutes
    NOTIFICATION_MESSAGES = {
      takeover: "Вас переключили на менеджера. Сейчас с вами общается %{name}",
      release: "Спасибо за обращение! Если будут вопросы — AI-ассистент всегда на связи",
      timeout: "Менеджер сейчас недоступен. AI-ассистент снова на связи!"
    }.freeze

    def initialize(chat)
      @chat = chat
    end

    def takeover!(user)
      raise AlreadyTakenError if chat.manager_mode?
      raise UnauthorizedError unless user.has_access_to?(chat.tenant)

      ActiveRecord::Base.transaction do
        chat.update!(
          mode: :manager_mode,
          taken_by: user,
          taken_at: Time.current
        )

        notify_client(:takeover, name: user.display_name)
        schedule_timeout
        log_action(:takeover, user)
      end

      broadcast_state_change
      chat
    end

    def release!(timeout: false)
      raise NotTakenError unless chat.manager_mode?

      user = chat.taken_by

      ActiveRecord::Base.transaction do
        chat.update!(
          mode: :ai_mode,
          taken_by: nil,
          taken_at: nil
        )

        notify_client(timeout ? :timeout : :release)
        log_action(timeout ? :timeout : :release, user)
      end

      broadcast_state_change
      chat
    end

    private

    attr_reader :chat

    def notify_client(type, **params)
      message = NOTIFICATION_MESSAGES[type] % params

      chat.tenant.bot_client.send_message(
        chat_id: chat.telegram_user.telegram_id,
        text: message
      )

      # Save as system message
      chat.messages.create!(
        role: :assistant,
        content: message,
        sender_type: :system
      )
    end

    def schedule_timeout
      ChatTakeoverTimeoutJob
        .set(wait: TIMEOUT_DURATION)
        .perform_later(chat.id, chat.taken_at.to_i)
    end

    def log_action(action, user)
      ChatTakeoverLog.create!(
        chat: chat,
        user: user,
        action: action.to_s,
        metadata: {
          tenant_id: chat.tenant_id,
          client_id: chat.client_id
        }
      )
    end

    def broadcast_state_change
      Turbo::StreamsChannel.broadcast_replace_to(
        "tenant_#{chat.tenant_id}_chats",
        target: "chat_#{chat.id}_status",
        partial: "tenants/chats/status",
        locals: { chat: chat }
      )
    end

    class AlreadyTakenError < StandardError; end
    class NotTakenError < StandardError; end
    class UnauthorizedError < StandardError; end
  end
  ```

- [ ] **ManagerMessageService**
  ```ruby
  # app/services/manager_message_service.rb
  class ManagerMessageService
    include ErrorLogger

    MAX_MESSAGES_PER_HOUR = 60

    def initialize(chat)
      @chat = chat
    end

    def send!(user, text)
      raise NotInManagerModeError unless chat.manager_mode?
      raise NotTakenByUserError unless chat.taken_by == user
      raise RateLimitExceededError if rate_limited?(user)

      # Send to Telegram
      chat.tenant.bot_client.send_message(
        chat_id: chat.telegram_user.telegram_id,
        text: text
      )

      # Save message
      message = chat.messages.create!(
        role: :assistant,
        content: text,
        sender_type: :manager,
        sender: user
      )

      # Refresh timeout
      refresh_takeover_timeout

      # Log action
      log_message(user, text)

      # Broadcast to dashboard
      broadcast_new_message(message)

      message
    end

    private

    attr_reader :chat

    def rate_limited?(user)
      ChatTakeoverLog
        .where(chat: chat, user: user, action: 'send_message')
        .where('created_at > ?', 1.hour.ago)
        .count >= MAX_MESSAGES_PER_HOUR
    end

    def refresh_takeover_timeout
      chat.update!(taken_at: Time.current)

      ChatTakeoverTimeoutJob
        .set(wait: ChatTakeoverService::TIMEOUT_DURATION)
        .perform_later(chat.id, chat.taken_at.to_i)
    end

    def log_message(user, text)
      ChatTakeoverLog.create!(
        chat: chat,
        user: user,
        action: 'send_message',
        metadata: { text_length: text.length }
      )
    end

    def broadcast_new_message(message)
      Turbo::StreamsChannel.broadcast_append_to(
        "tenant_#{chat.tenant_id}_chat_#{chat.id}",
        target: "chat_messages",
        partial: "tenants/chats/message",
        locals: { message: message }
      )
    end

    class NotInManagerModeError < StandardError; end
    class NotTakenByUserError < StandardError; end
    class RateLimitExceededError < StandardError; end
  end
  ```

- [ ] **ChatTakeoverTimeoutJob**
  ```ruby
  # app/jobs/chat_takeover_timeout_job.rb
  class ChatTakeoverTimeoutJob < ApplicationJob
    queue_as :default

    def perform(chat_id, taken_at_timestamp)
      chat = Chat.find_by(id: chat_id)
      return unless chat
      return unless chat.manager_mode?

      # Verify this is the same takeover session
      # (not a new one started after the job was scheduled)
      return unless chat.taken_at&.to_i == taken_at_timestamp

      ChatTakeoverService.new(chat).release!(timeout: true)
    end
  end
  ```

### Phase 3: Controller & Routes (4 часа)

- [ ] **Update routes**
  ```ruby
  # config/routes.rb
  namespace :tenants, path: '' do
    resources :chats, only: [:index, :show] do
      member do
        post :takeover
        post :release
        post :send_message
      end
    end
  end
  ```

- [ ] **Update ChatsController**
  ```ruby
  # app/controllers/tenants/chats_controller.rb
  module Tenants
    class ChatsController < ApplicationController
      # ... existing code ...

      # POST /chats/:id/takeover
      def takeover
        @chat = find_chat
        ChatTakeoverService.new(@chat).takeover!(current_user)

        respond_to do |format|
          format.turbo_stream
          format.html { redirect_to chat_path(@chat), notice: 'Диалог перехвачен' }
        end
      rescue ChatTakeoverService::AlreadyTakenError
        respond_with_error('Диалог уже перехвачен другим менеджером')
      rescue ChatTakeoverService::UnauthorizedError
        respond_with_error('Нет доступа к этому чату')
      end

      # POST /chats/:id/release
      def release
        @chat = find_chat
        ChatTakeoverService.new(@chat).release!

        respond_to do |format|
          format.turbo_stream
          format.html { redirect_to chat_path(@chat), notice: 'Диалог возвращён боту' }
        end
      rescue ChatTakeoverService::NotTakenError
        respond_with_error('Диалог не был перехвачен')
      end

      # POST /chats/:id/send_message
      def send_message
        @chat = find_chat
        @message = ManagerMessageService.new(@chat).send!(current_user, params[:text])

        respond_to do |format|
          format.turbo_stream
          format.html { redirect_to chat_path(@chat) }
        end
      rescue ManagerMessageService::NotInManagerModeError
        respond_with_error('Сначала перехватите диалог')
      rescue ManagerMessageService::RateLimitExceededError
        respond_with_error('Превышен лимит сообщений (60/час)')
      end

      private

      def find_chat
        current_tenant.chats
          .includes(client: :telegram_user, messages: :tool_calls)
          .find(params[:id])
      end

      def respond_with_error(message)
        respond_to do |format|
          format.turbo_stream { render turbo_stream: turbo_stream.replace('flash', partial: 'shared/flash', locals: { message: message, type: :error }) }
          format.html { redirect_to chat_path(@chat), alert: message }
        end
      end
    end
  end
  ```

### Phase 4: Views & UI (6 часов)

- [ ] **Update chat show view** with takeover controls
- [ ] **Create Turbo Stream templates**
  - `takeover.turbo_stream.erb`
  - `release.turbo_stream.erb`
  - `send_message.turbo_stream.erb`
- [ ] **Add message input form** (visible only in manager_mode)
- [ ] **Add status indicator** (AI mode / Manager mode with timer)
- [ ] **Style manager messages** differently from AI messages
- [ ] **Add countdown timer** for takeover timeout (Stimulus controller)

### Phase 5: Integration & Testing (6 часов)

- [ ] **Unit tests**
  - `test/models/chat_test.rb` - takeover fields, validations
  - `test/services/chat_takeover_service_test.rb`
  - `test/services/manager_message_service_test.rb`
  - `test/jobs/chat_takeover_timeout_job_test.rb`

- [ ] **Integration tests**
  - `test/controllers/tenants/chats_controller_test.rb`
  - Full takeover flow
  - Timeout scenario
  - Concurrent takeover prevention

- [ ] **System tests**
  - UI interaction with Turbo Streams
  - Real-time message updates

### Phase 6: Polish & Analytics (4 часа)

- [ ] **Analytics events**
  ```ruby
  AnalyticsService::Events::CHAT_TAKEOVER_STARTED
  AnalyticsService::Events::CHAT_TAKEOVER_ENDED
  AnalyticsService::Events::CHAT_TAKEOVER_TIMEOUT
  AnalyticsService::Events::MANAGER_MESSAGE_SENT
  ```

- [ ] **Dashboard metrics**
  - Takeover rate per tenant
  - Average takeover duration
  - Messages per takeover session

- [ ] **Error handling** and logging
- [ ] **Documentation** updates

## Риски и зависимости

### Технические риски

```yaml
high_risks:
  - risk: "Telegram API rate limits при отправке уведомлений"
    probability: "Low"
    impact: "High"
    mitigation: "Retry with exponential backoff, queue messages"
    owner: "Developer"

  - risk: "Race condition при одновременном takeover"
    probability: "Medium"
    impact: "High"
    mitigation: "Database-level locking, optimistic concurrency"
    owner: "Developer"

medium_risks:
  - risk: "Timeout job выполняется после нового takeover"
    probability: "Medium"
    impact: "Medium"
    mitigation: "Verify taken_at timestamp in job"
    owner: "Developer"

  - risk: "Turbo Streams не обновляются в реальном времени"
    probability: "Low"
    impact: "Medium"
    mitigation: "Fallback to polling, ActionCable health checks"
    owner: "Developer"

low_risks:
  - risk: "Менеджер отправляет inappropriate content"
    probability: "Low"
    impact: "Low"
    mitigation: "Audit log, content moderation (future)"
    owner: "Product Owner"
```

### Зависимости

```yaml
internal_dependencies:
  - component: "Tenants::ChatsController"
    status: "Available (read-only)"
    risks: "Needs extension for write operations"
    mitigation: "Backward compatible changes"

  - component: "Chat model"
    status: "Available"
    risks: "Schema change"
    mitigation: "Non-breaking migration"

  - component: "Telegram::WebhookController"
    status: "Available"
    risks: "Needs modification for manager_mode check"
    mitigation: "Minimal, isolated change"

external_dependencies:
  - service: "Telegram Bot API"
    status: "Available"
    risks: "Rate limits, downtime"
    mitigation: "Retry logic, graceful degradation"

  - service: "SolidQueue"
    status: "Available"
    risks: "Job processing delays"
    mitigation: "Monitor queue depth, scale workers"

infrastructure_dependencies:
  - resource: "PostgreSQL"
    status: "Available"
    risks: "Lock contention on chat rows"
    mitigation: "Short transactions, proper indexing"

  - resource: "Redis (ActionCable)"
    status: "Available"
    risks: "Connection issues affect Turbo Streams"
    mitigation: "Fallback UI state refresh"
```

### Технологический стек

```yaml
backend:
  framework: "Ruby on Rails 8.0"
  language: "Ruby 3.4+"

database:
  primary: "PostgreSQL 15+"
  cache: "Redis 7+ (ActionCable)"

background_jobs:
  queue: "SolidQueue"

frontend:
  framework: "Hotwire (Turbo + Stimulus)"
  styling: "Tailwind CSS"

external_services:
  - name: "Telegram Bot API"
    purpose: "Send messages to clients"

testing:
  framework: "Minitest"
  tools: "FactoryBot, WebMock"
```

## План тестирования

### Unit Testing

```yaml
models:
  Chat:
    - "mode enum works correctly"
    - "takeover_time_remaining calculation"
    - "takeover_expired? returns correct value"
    - "validations for manager_mode"

  Message:
    - "sender_type enum works correctly"
    - "sender association"

  ChatTakeoverLog:
    - "required fields validation"
    - "action enum"

services:
  ChatTakeoverService:
    - "takeover! sets correct fields"
    - "takeover! sends notification"
    - "takeover! schedules timeout job"
    - "takeover! raises AlreadyTakenError"
    - "release! clears fields"
    - "release! sends notification"
    - "release! with timeout flag"

  ManagerMessageService:
    - "send! creates message"
    - "send! sends to Telegram"
    - "send! refreshes timeout"
    - "send! respects rate limit"
    - "send! raises errors for invalid state"

jobs:
  ChatTakeoverTimeoutJob:
    - "releases chat after timeout"
    - "skips if chat not in manager_mode"
    - "skips if taken_at changed (new session)"
```

### Integration Testing

```yaml
controllers:
  "Tenants::ChatsController":
    - "POST /takeover requires authentication"
    - "POST /takeover changes chat mode"
    - "POST /takeover returns error if already taken"
    - "POST /release returns chat to ai_mode"
    - "POST /send_message creates message"
    - "POST /send_message respects rate limit"

webhook:
  "Telegram::WebhookController":
    - "doesn't auto-respond in manager_mode"
    - "saves client message in manager_mode"
    - "broadcasts new message to dashboard"
```

### E2E Testing

```yaml
scenarios:
  - name: "Full takeover flow"
    steps:
      - "Manager views chat list"
      - "Manager clicks takeover button"
      - "Client receives notification"
      - "Manager sends message"
      - "Client receives message"
      - "Client responds"
      - "Manager sees response in dashboard"
      - "Manager releases chat"
      - "Client receives return notification"

  - name: "Timeout scenario"
    steps:
      - "Manager takes over chat"
      - "30 minutes pass with no activity"
      - "Job releases chat automatically"
      - "Client receives timeout notification"
```

## Метрики успеха

### Technical Metrics

- [ ] **Takeover latency:** < 500ms (p95)
- [ ] **Message send latency:** < 2s (p95)
- [ ] **Timeout job accuracy:** 100% execute within 1 minute of scheduled time
- [ ] **Error rate:** < 0.1%
- [ ] **Test coverage:** > 85%

### Business Metrics (из User Story)

- [ ] **Takeover rate:** < 5% of all chats
- [ ] **Resolution rate:** > 90% of takeovers result in conversion
- [ ] **Avg takeover duration:** < 15 minutes
- [ ] **Timeout rate:** < 10% of takeovers

### Performance Metrics

- [ ] **Database query time:** < 50ms for takeover operation
- [ ] **Memory usage:** No significant increase per takeover
- [ ] **Queue depth:** < 100 pending timeout jobs

## Связанные документы

- **User Story:** [US-010-tenant-chat-takeover.md](../user-stories/US-010-tenant-chat-takeover.md)
- **GitHub Issue:** [#103](https://github.com/dapi/valera/issues/103)
- **Prerequisite:** [#102 - Раздел Чаты](https://github.com/dapi/valera/issues/102) (CLOSED)
- **Product Constitution:** [constitution.md](../../product/constitution.md)
- **Existing Code:**
  - `app/controllers/tenants/chats_controller.rb`
  - `app/controllers/telegram/webhook_controller.rb`
  - `app/models/chat.rb`
  - `app/models/message.rb`

## Completion Checklist

### Functional Requirements:

- [ ] Chat mode switching works
- [ ] Takeover/release flow complete
- [ ] Message sending works
- [ ] Timeout auto-release works
- [ ] Notifications sent to client
- [ ] Audit logging complete

### Technical Requirements:

- [ ] Performance targets achieved
- [ ] Rate limiting implemented
- [ ] Error handling complete
- [ ] Concurrent access handled

### Quality Assurance:

- [ ] Unit tests passing (85%+ coverage)
- [ ] Integration tests passing
- [ ] Manual testing complete
- [ ] Code review completed
- [ ] Security review passed

### Documentation:

- [ ] API documentation updated
- [ ] README updated with new feature
- [ ] Inline code documentation

### Deployment Readiness:

- [ ] Migrations tested on staging
- [ ] Feature flag if needed
- [ ] Rollback plan documented
- [ ] Monitoring alerts configured

---

**Change log:**
| Дата | Версия | Изменение | Автор |
|------|--------|-----------|-------|
| 28.12.2025 | 1.0 | Initial version | Claude Code |

---

**Approval:**
- [ ] Tech Lead: _________________________ Date: _______
- [ ] Senior Developer: __________________ Date: _______

**Implementation Notes:**
- **Estimated effort:** 30 часов (5-7 рабочих дней)
- **Suggested sprint:** После стабилизации MVP
- **Feature flag:** `chat_takeover_enabled` (per tenant)
