# Feature Implementation Plan: FIP-002 - Multi-Tenancy для автосервисов

**Статус:** 📝 Draft
**Приоритет:** High
**Версия:** 1.0
**Создан:** 27.10.2025
**Автор:** Tech Lead
**Ожидаемое время реализации:** 5-7 дней

## 📋 Executive Summary

### Бизнес-проблема
Текущая архитектура поддерживает **только один автосервис** с единым bot_token, system prompt и прайс-листом. Это делает невозможным:
- Масштабирование на множество автосервисов
- SaaS-модель монетизации
- Индивидуальные настройки для каждого клиента
- Тестирование разных AI промптов для разных бизнесов

### Предлагаемое решение
Multi-tenancy архитектура на основе:
- **Принцип мультитенантности из ~/code/vilna** (RequestStore, Elevator pattern)
- **Telegram webhook routing из ~/code/samochat** (CustomTelegramBotMiddleware)
- **Минималистичная Account модель** (только необходимые поля)

### Бизнес-ценность
- **SaaS-готовность:** Поддержка неограниченного количества клиентов
- **Гибкость настроек:** Каждый автосервис настраивает своего бота
- **Масштабируемость:** Рост без технических ограничений
- **Монетизация:** Subscription-based модель

## 🏗️ Архитектура

### Ключевой принцип:
**TelegramUser - глобальный** (один пользователь может общаться с разными ботами)

```ruby
Account (автосервис/бот)
  ├── owner (TelegramUser) - владелец бота
  ├── bot_token (уникальный)
  ├── bot_id (извлекается из token)
  ├── llm_provider + llm_model
  ├── system_prompt (text в БД)
  ├── company_info (text в БД)
  ├── welcome_message (text в БД)
  ├── price_list (jsonb в БД)
  ├── admin_chat_id (bigint) - ID чата для уведомлений
  └── settings (jsonb)

  has_many :chats
  has_many :bookings, through: :chats

TelegramUser (глобальный, БЕЗ account_id!)
  has_many :chats  # может писать в разные боты
  has_many :owned_accounts, class_name: 'Account', foreign_key: :owner_id

Chat (диалог в конкретном боте)
  belongs_to :telegram_user  # глобальный юзер
  belongs_to :account        # НОВОЕ! в каком боте диалог
  has_many :messages
  has_many :bookings

  # Unique constraint: один Chat на (user, account)
  validates :telegram_user_id, uniqueness: { scope: :account_id }

Booking
  belongs_to :chat
  has_one :account, through: :chat
```

### Как это работает:

**Шаг 1: Webhook routing (из samochat)**
```
Telegram → POST /telegram/webhook/:bot_id
         → CustomTelegramBotMiddleware
         → Account.find_by_bot_id(bot_id)
         → RequestStore.store[:account] = account
         → Telegram::WebhookController
```

**Шаг 2: Request processing (принцип из vilna)**
```ruby
# В любом контроллере/сервисе
def current_account
  RequestStore.store[:account]
end

# Автоматический доступ к настройкам аккаунта
current_account.system_prompt
current_account.welcome_message
current_account.price_list
```

**Преимущества:**
- ✅ Пользователь может писать в бот А и бот Б
- ✅ У каждого бота свой Chat с этим пользователем
- ✅ История и контекст изолированы по ботам
- ✅ Bookings привязаны к конкретному Account через Chat

## 🔧 Технические требования

### Database Schema:

```ruby
# Генерируется через: rails generate model Account
create_table :accounts do |t|
  t.string :name, null: false

  # Telegram Bot
  t.string :bot_token, null: false
  t.string :bot_id, null: false
  t.string :bot_username

  # AI Configuration
  t.string :llm_provider, default: 'anthropic'
  t.string :llm_model, default: 'claude-3-5-sonnet-20241022'

  # Content (default values из ApplicationConfig)
  t.text :system_prompt, null: false
  t.text :company_info, null: false
  t.text :welcome_message, null: false
  t.jsonb :price_list, default: {}, null: false

  # Notifications
  t.bigint :admin_chat_id

  # Settings & Status
  t.jsonb :settings, default: {}, null: false
  t.string :status, default: 'active'

  # Owner (НЕТ owner_id при создании, раскатываем на пустую базу)
  t.bigint :owner_id

  t.timestamps
end

add_index :accounts, :bot_id, unique: true  # УНИКАЛЬНЫЙ индекс только на bot_id
add_index :accounts, :owner_id
add_foreign_key :accounts, :telegram_users, column: :owner_id
# НЕ создаем уникальный индекс на bot_token

# Генерируется через: rails generate migration AddAccountIdToChats
add_reference :chats, :account, foreign_key: true, null: false
add_index :chats, [:telegram_user_id, :account_id], unique: true
```

### Файлы из vilna (lib/) - копировать буквально:

**1. lib/multitenancy/elevator.rb** (адаптированный для bot_id):
```ruby
# frozen_string_literal: true

module Multitenancy
  class Elevator
    def initialize(app)
      @app = app
    end

    def call(env)
      # Очистка RequestStore (проверка безопасности)
      raise "Account already set in RequestStore" if RequestStore.store[:account]

      request = Rack::Request.new(env)
      bot_id = request.params[:bot_id]

      # Пропускаем запросы без bot_id
      return @app.call(env) if bot_id.nil?

      # Находим Account по bot_id и сохраняем в RequestStore
      RequestStore.store[:account] = Account.find_by(bot_id: bot_id)

      @app.call(env)
    ensure
      # Очистка после обработки запроса
      RequestStore.store[:account] = nil
    end
  end
end
```

**2. lib/account_constraint.rb** (из vilna без изменений):
```ruby
# frozen_string_literal: true

class AccountConstraint
  def self.matches?(request)
    RequestStore.store[:account].present?
  end
end
```

**3. lib/custom_telegram_bot_middleware.rb** (из samochat):
```ruby
# frozen_string_literal: true

class CustomTelegramBotMiddleware
  attr_reader :controller

  def initialize(controller)
    @controller = controller
  end

  def call(env)
    request = ActionDispatch::Request.new(env)
    update = request.request_parameters
    bot_id = request.params[:bot_id]

    account = Account.find_by(bot_id: bot_id)

    if account.present?
      # Сохраняем account в RequestStore для доступа в контроллерах
      RequestStore.store[:account] = account

      # Dispatch с custom bot клиентом
      controller.dispatch(account.custom_bot, update)
    else
      Rails.logger.warn "No account found with bot_id #{bot_id}"
    end

    [200, {}, ['']]
  ensure
    # Очистка RequestStore после обработки
    RequestStore.store[:account] = nil
  end
end
```

### Core Models:

**app/models/account.rb:**
```ruby
# frozen_string_literal: true

# Модель аккаунта автосервиса (мультитенантность)
#
# Представляет отдельный автосервис с собственным Telegram ботом,
# настройками AI, прайс-листом и системным промптом.
#
# @attr [String] name название автосервиса
# @attr [String] bot_token токен Telegram бота
# @attr [String] bot_id ID бота (извлекается из token)
# @attr [String] bot_username username бота в Telegram
# @attr [String] llm_provider провайдер AI (anthropic, openai, etc.)
# @attr [String] llm_model модель AI
# @attr [Text] system_prompt системный промпт для AI
# @attr [Text] company_info информация о компании
# @attr [Text] welcome_message приветственное сообщение
# @attr [JSONB] price_list прайс-лист услуг
# @attr [BigInt] admin_chat_id ID чата для уведомлений о заявках
# @attr [JSONB] settings дополнительные настройки
# @attr [String] status статус аккаунта (active/inactive)
# @attr [BigInt] owner_id ID владельца (TelegramUser)
#
# @example Создание нового аккаунта
#   account = Account.create!(
#     name: "Автосервис №1",
#     bot_token: "123456:ABC-DEF...",
#     system_prompt: "Ты - ассистент...",
#     company_info: "Адрес: ...",
#     welcome_message: "Добро пожаловать...",
#     price_list: { "Покраска": 10000 }
#   )
#
# @author Danil Pismenny
# @since 0.2.0
class Account < ApplicationRecord
  include ErrorLogger

  belongs_to :owner, class_name: 'TelegramUser', optional: true
  has_many :chats, dependent: :destroy
  has_many :bookings, through: :chats

  # Validations
  validates :name, presence: true
  validates :bot_token, presence: true,
            format: { with: /\A\d+:[a-zA-Z0-9_-]+\z/,
                     message: "имеет неверный формат" }
  # Уникальность только на bot_id (уникальный индекс в БД)
  validates :bot_id, presence: true, uniqueness: true
  validates :system_prompt, presence: true
  validates :company_info, presence: true
  validates :welcome_message, presence: true
  validates :llm_provider, presence: true
  validates :llm_model, presence: true

  # Callbacks
  before_validation :extract_bot_id, if: :bot_token_changed?
  after_commit :set_webhook, if: :saved_change_to_bot_token?, on: [:create, :update]
  after_commit :delete_webhook, if: :bot_token?, on: :destroy

  # Возвращает Telegram bot клиент для этого аккаунта
  #
  # @return [Telegram::Bot::Client] клиент для работы с Telegram API
  # @example
  #   account.custom_bot.send_message(chat_id: 123, text: "Hello")
  def custom_bot
    @custom_bot ||= Telegram::Bot::Client.new(bot_token, bot_username)
  end

  private

  # Извлекает bot_id из bot_token
  #
  # @return [void]
  # @api private
  def extract_bot_id
    self.bot_id = bot_token.to_s.split(':').first
  end

  # Регистрирует webhook в Telegram для этого бота
  #
  # @return [void]
  # @raise [Telegram::Bot::Error] при ошибке регистрации
  # @api private
  def set_webhook
    return unless bot_token.present?

    url = Rails.application.routes.url_helpers.telegram_webhook_url(bot_id)
    Rails.logger.info "[Account #{id}] Setting webhook for bot_id=#{bot_id} to #{url}"

    custom_bot.set_webhook(url: url, drop_pending_updates: false)
  rescue Telegram::Bot::Error => e
    log_error(e, {
      model: 'Account',
      method: 'set_webhook',
      account_id: id,
      bot_id: bot_id
    })
  end

  # Удаляет webhook из Telegram для этого бота
  #
  # @return [void]
  # @api private
  def delete_webhook
    return unless bot_token.present?

    Rails.logger.info "[Account #{id}] Deleting webhook for bot_id=#{bot_id}"
    custom_bot.delete_webhook(drop_pending_updates: false)
  rescue Telegram::Bot::Error => e
    log_error(e, {
      model: 'Account',
      method: 'delete_webhook',
      account_id: id,
      bot_id: bot_id
    })
  end
end
```

**Обновления в app/models/telegram_user.rb:**
```ruby
class TelegramUser < ApplicationRecord
  has_many :chats, dependent: :destroy
  has_many :owned_accounts, class_name: 'Account',
           foreign_key: :owner_id, dependent: :restrict_with_error
  # НЕТ belongs_to :account!

  # ... остальной код без изменений
end
```

**Обновления в app/models/chat.rb:**
```ruby
class Chat < ApplicationRecord
  include ErrorLogger

  belongs_to :telegram_user
  belongs_to :account          # НОВОЕ!
  has_many :bookings, dependent: :destroy

  acts_as_chat

  # Unique constraint: один Chat на (user, account)
  validates :telegram_user_id, uniqueness: { scope: :account_id }

  # Устанавливает модель AI из Account перед созданием
  before_create do
    self.model ||= Model.find_by!(
      provider: account.llm_provider,
      model_id: account.llm_model
    )
  end

  # Устанавливает системные инструкции из Account после создания
  after_create do
    with_instructions account.system_prompt
  end

  # Сбрасывает диалог к начальному состоянию
  def reset!
    messages.destroy_all
    with_instructions account.system_prompt
  end

  # ... остальной код
end
```

### Routes (config/routes.rb):
```ruby
# Telegram webhook with bot_id routing
post 'telegram/webhook/:bot_id',
     to: CustomTelegramBotMiddleware.new(Telegram::WebhookController),
     as: :telegram_webhook
```

### Initializer для RequestStore (config/initializers/request_store.rb):
```ruby
# frozen_string_literal: true

# Ensure RequestStore is cleared between requests in development
if Rails.env.development?
  Rails.application.config.middleware.use RequestStore::Middleware
end
```

### Gemfile:
```ruby
# Multi-tenancy support
gem 'request_store', '~> 1.5'
```

## ⚡ Implementation Plan (5-7 дней)

### **Phase 1: Dependencies & Core Setup (День 1)**

**Утро (4 часа):**
- [ ] Добавить `gem 'request_store'` в Gemfile
- [ ] `bundle install`
- [ ] Создать `config/initializers/request_store.rb`
- [ ] Скопировать файлы из vilna:
  - [ ] `lib/multitenancy/elevator.rb` (адаптировать для bot_id)
  - [ ] `lib/account_constraint.rb`
- [ ] Скопировать из samochat:
  - [ ] `lib/custom_telegram_bot_middleware.rb` (добавить RequestStore)

**После обеда (4 часа):**
- [ ] Создать модель Account через `rails generate model` (автоматически создаст миграцию):
  ```bash
  rails generate model Account \
    name:string \
    bot_token:string \
    bot_id:string \
    bot_username:string \
    llm_provider:string \
    llm_model:string \
    system_prompt:text \
    company_info:text \
    welcome_message:text \
    price_list:jsonb \
    admin_chat_id:bigint \
    settings:jsonb \
    status:string \
    owner:references
  ```
  **Важно:** Команда создаст ОДНОВРЕМЕННО модель И миграцию (правило из CLAUDE.md:567)
- [ ] Обновить сгенерированную миграцию (добавить индексы, defaults, NOT NULL)
- [ ] `rails db:migrate`
- [ ] Добавить в модель Account валидации, методы и callbacks

### **Phase 2: Chat Integration (День 2)**

**Утро (4 часа):**
- [ ] Создать миграцию `rails generate migration AddAccountIdToChats`
- [ ] Добавить в миграцию:
  - [ ] `add_reference :chats, :account, foreign_key: true, null: false`
  - [ ] `add_index :chats, [:telegram_user_id, :account_id], unique: true`
- [ ] `rails db:migrate`
- [ ] Обновить Chat model:
  - [ ] `belongs_to :account`
  - [ ] Валидация uniqueness
  - [ ] Использовать `account.system_prompt` в callbacks

**После обеда (4 часа):**
- [ ] Обновить TelegramUser:
  - [ ] `has_many :owned_accounts`
  - [ ] Убедиться что НЕТ `belongs_to :account`
- [ ] Написать тесты:
  - [ ] Account model tests
  - [ ] Chat-Account association tests
  - [ ] Uniqueness constraint tests
- [ ] Создать fixtures для тестирования (несколько Account'ов)

### **Phase 3: Webhook Routing (День 3)**

**Утро (4 часа):**
- [ ] Обновить `config/routes.rb`:
  ```ruby
  post 'telegram/webhook/:bot_id',
       to: CustomTelegramBotMiddleware.new(Telegram::WebhookController),
       as: :telegram_webhook
  ```
- [ ] Обновить `config/initializers/telegram.rb` (убрать глобальный bot_token)
- [ ] Обновить `Telegram::WebhookController`:
  - [ ] Получать Account из RequestStore
  - [ ] Находить/создавать Chat по `(telegram_user, account)`
  - [ ] Использовать `account.custom_bot`

**После обеда (4 часа):**
- [ ] Добавить concern `CurrentAccount` для доступа в контроллерах:
  ```ruby
  module CurrentAccount
    extend ActiveSupport::Concern

    def current_account
      RequestStore.store[:account]
    end
  end
  ```
- [ ] Тесты middleware и routing
- [ ] Интеграционные тесты webhook flow

### **Phase 4: Services Refactoring (День 4)**

**Утро (4 часа):**
- [ ] Создать `ApplicationService` с доступом к account
- [ ] Обновить `WelcomeService`:
  - [ ] Использовать `account.welcome_message` вместо `ApplicationConfig`
- [ ] Обновить `SystemPromptService`:
  - [ ] Использовать `account.system_prompt`
- [ ] Обновить `BookingCreatorTool`:
  - [ ] Использовать `account.price_list`
  - [ ] Отправлять уведомление в `account.admin_chat_id`

**После обеда (4 часа):**
- [ ] Найти все использования `ApplicationConfig` для bot-specific настроек
- [ ] Заменить на `account.*` или `chat.account.*`
- [ ] Убедиться что ApplicationConfig используется только для глобальных настроек:
  - [ ] API keys (openai_api_key, anthropic_api_key, etc.)
  - [ ] Redis URL
  - [ ] Rate limits (глобальные)
- [ ] Тесты обновленных сервисов

### **Phase 5: Seeds & Documentation (День 5)**

**Весь день (8 часов):**
- [ ] Создать `db/seeds.rb` с примерами Account:
  ```ruby
  # Default values из ApplicationConfig
  Account.create!(
    name: "Demo Car Service",
    bot_token: ENV['BOT_TOKEN'],
    llm_provider: ApplicationConfig.llm_provider,
    llm_model: ApplicationConfig.llm_model,
    system_prompt: File.read(ApplicationConfig.system_prompt_path),
    company_info: File.read(ApplicationConfig.company_info_path),
    welcome_message: File.read(ApplicationConfig.welcome_message_path),
    price_list: JSON.parse(File.read(ApplicationConfig.price_list_path)),
    admin_chat_id: ApplicationConfig.admin_chat_id
  )
  ```
- [ ] Написать документацию:
  - [ ] Как создать новый Account
  - [ ] Как настроить webhook
  - [ ] Как тестировать с несколькими ботами
  - [ ] Troubleshooting guide
- [ ] Обновить CLAUDE.md если нужно

### **Phase 6: Testing & Validation (День 6-7)**

**День 6 (8 часов):**
- [ ] End-to-end тестирование:
  - [ ] Создание Account через Rails console
  - [ ] Регистрация webhook (проверить логи Telegram)
  - [ ] Отправка сообщений в разные боты
  - [ ] Проверка изоляции данных между Account'ами
- [ ] Performance testing:
  - [ ] Создать 10+ Account'ов
  - [ ] Параллельные запросы к разным ботам
  - [ ] Проверка отсутствия race conditions
- [ ] Security audit:
  - [ ] Изоляция данных
  - [ ] Валидация bot_token
  - [ ] Проверка уникальности

**День 7 (8 часов):**
- [ ] Проверка всех существующих тестов (должны проходить)
- [ ] Code review самого себя
- [ ] Deployment checklist:
  - [ ] Migrations ready
  - [ ] Seeds ready
  - [ ] Environment variables documented
  - [ ] Rollback plan prepared
- [ ] Final documentation review

## 📊 Success Metrics & Acceptance Criteria

### **Technical Acceptance Criteria:**
- [ ] Один TelegramUser может писать в несколько ботов
- [ ] Каждый бот имеет изолированный Chat с пользователем
- [ ] Webhook routing работает для всех bot_id
- [ ] RequestStore корректно хранит текущий Account
- [ ] 0 performance degradation при добавлении Account'ов
- [ ] Все существующие тесты проходят
- [ ] Новые тесты покрывают мультитенантность (>90%)

### **Business Acceptance Criteria:**
- [ ] Можно создать Account за < 5 минут через Rails console
- [ ] Bot token validation работает в real-time
- [ ] Webhook автоматически регистрируется при создании Account
- [ ] Полная изоляция данных между Account'ами
- [ ] Каждый Account имеет свой system_prompt, welcome_message, price_list

### **Data Integrity Criteria:**
- [ ] Unique constraint на (telegram_user_id, account_id) в chats
- [ ] Unique constraint на bot_id в accounts (НЕТ на bot_token)
- [ ] Foreign keys защищены (on_delete: cascade/restrict)
- [ ] RequestStore очищается между запросами

### **Security Criteria:**
- [ ] Bot token encrypted at rest (ActiveRecord encryption)
- [ ] Нет утечки данных между Account'ами
- [ ] Admin chat ID валидируется
- [ ] Owner проверяется перед изменениями

## 🔗 Dependencies & Risks

### **Dependencies:**
- **RequestStore gem** - для хранения текущего Account
- **Telegram API** - для webhook registration
- **PostgreSQL** - для новых таблиц и FK
- **Существующий код** - минимальные breaking changes

### **Technical Risks:**
- **RequestStore thread safety** - может быть проблема в production
- **Webhook conflicts** - множественные webhook'и для разных ботов
- **Migration complexity** - добавление account_id к существующим chats
- **Breaking changes** - обновление Chat model может сломать код

### **Mitigation Strategies:**
- **RequestStore middleware** - правильная настройка в initializer
- **Extensive testing** - unit + integration + e2e
- **Incremental migration** - поэтапное внедрение
- **Monitoring** - логирование всех операций с Account
- **Rollback plan** - возможность откатить все изменения

## 🎯 Business Case & ROI

### **Investment:**
- **Development time:** 5-7 дней (1 разработчик)
- **Infrastructure cost:** $0 (используем текущую)
- **RequestStore gem:** Free, open source
- **Total:** ~7 рабочих дней

### **Expected Returns:**
- **SaaS-ready:** Возможность onboarding новых клиентов
- **Scalability:** Неограниченное количество автосервисов
- **Flexibility:** Каждый клиент настраивает своего бота
- **Revenue potential:** Subscription-based монетизация

### **ROI Timeline:**
- **Week 1:** Foundation (Database + Models)
- **Week 2:** Production ready (Routing + Services)
- **Month 1:** First clients onboarded
- **Month 3+:** Multiple paying customers

## 🔗 Связанные документы

### **Reference Projects:**
- **~/code/vilna** - Принцип мультитенантности (RequestStore, Elevator)
- **~/code/samochat** - Telegram webhook routing (CustomTelegramBotMiddleware)

### **Internal Documentation:**
- **[Product Constitution](../product/constitution.md)** - Базовые принципы
- **[CLAUDE.md](../../CLAUDE.md)** - Правило про `rails generate model`
- **[Architecture Decisions](../architecture/decisions.md)** - Архитектурные решения
- **[FLOW.md](../FLOW.md)** - Процесс работы

---

## ✅ Checklist перед началом

- [ ] Изучил vilna (принцип мультитенантности)
- [ ] Изучил samochat (Telegram webhook routing)
- [ ] Понял что TelegramUser - глобальный (БЕЗ account_id)
- [ ] Понял принцип RequestStore
- [ ] Готов использовать `rails generate model`
- [ ] Готов копировать lib файлы из vilna

---

**Версия:** 1.0
**Дата создания:** 27.10.2025
**Тип документа:** Feature Implementation Plan (FIP)
**Статус:** Draft

**Основные решения:**
- ✅ TelegramUser - глобальный (БЕЗ account_id)
- ✅ Chat `belongs_to :account` (НОВОЕ!)
- ✅ Account `belongs_to :owner, class_name: 'TelegramUser'` (optional)
- ✅ Принцип мультитенантности из vilna (RequestStore)
- ✅ Telegram routing из samochat (CustomTelegramBotMiddleware)
- ✅ Default values из ApplicationConfig
- ✅ Добавлен admin_chat_id в Account
- ✅ Phase 4 только документация (миграция данных не нужна)
- ✅ Fixtures с несколькими Account'ами для тестирования
