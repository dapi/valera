# Technical Solution: TSOL-001 - Telegram Welcome Message Implementation

**Техническое решение:** TSOL-001-telegram-welcome-implementation
**Статус:** Draft
**Приоритет:** High
**Версия:** 1.0
**Создан:** 26.10.2025
**Автор:** AI Agent
**Основан на:** US-001, TS-001

## 🎯 Цель решения

Реализовать систему приветствия новых пользователей в Telegram боте "Валера" для автосервиса "Кузник" с использованием **гибридного архитектурного подхода**:
- **Welcome Message** → конфигурируемый шаблон (мгновенно)
- **Последующие сообщения** → LLM с System-First подходом

## 📋 Предварительные условия

### ✅ Требования к окружению
- [ ] Rails 8.1 приложение с ruby_llm gem
- [ ] Telegram бот token настроен в ApplicationConfig
- [ ] Существующие модели Chat и Message
- [ ] База данных PostgreSQL с индексами

### 📚 Изучение документации (Auto-Learning Protocol)
- [ ] **Telegram Bot Documentation** - изучить `docs/gems/telegram-bot/`
- [ ] **Ruby LLM Documentation** - изучить `docs/gems/ruby_llm/`
- [ ] **Product Constitution** - изучить `docs/product/constitution.md`
- [ ] **Memory Bank** - изучить `.claude/memory-bank.md`

## 🔧 План реализации

### Phase 1: Подготовка инфраструктуры

#### 1.1 Обновление конфигурации
```ruby
# config/configs/application_config.rb
attr_config(
  # ... существующие настройки
  welcome_message_path: './data/welcome-message.md',
  welcome_cooldown_minutes: 60,  # Защита от спама
)
```

#### 1.2 Миграции базы данных
```ruby
# db/migrate/XXXXXXXXXX_add_last_contacted_to_chats.rb
class AddLastContactedToChats < ActiveRecord::Migration[8.1]
  def change
    add_column :chats, :last_contacted_at, :datetime
    add_index :chats, :telegram_id, unique: true
  end
end
```

```ruby
# db/migrate/XXXXXXXXXX_add_message_type_to_messages.rb
class AddMessageTypeToMessages < ActiveRecord::Migration[8.1]
  def change
    add_column :messages, :message_type, :string, default: 'user'
    add_index :messages, [:chat_id, :created_at]
  end
end
```

### Phase 2: Реализация сервисов

#### 2.1 Создание WelcomeService
```ruby
# app/services/welcome_service.rb
class WelcomeService
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :telegram_client

  def initialize(telegram_client = nil)
    @telegram_client = telegram_client || TelegramClient.new
  end

  def handle_message(webhook_data)
    user_info = extract_user_info(webhook_data)

    # Проверка на спам (cooldown)
    return if within_cooldown_period?(user_info[:telegram_id])

    if new_user?(user_info[:telegram_id])
      process_new_user(user_info, webhook_data)
    else
      route_to_existing_user_flow(user_info, webhook_data)
    end
  rescue StandardError => e
    log_error(e, user_info)
    handle_error_gracefully(e, user_info)
  end

  private

  def extract_user_info(webhook_data)
    message = webhook_data.dig('message')

    {
      telegram_id: message.dig('from', 'id'),
      chat_id: message.dig('chat', 'id'),
      first_name: message.dig('from', 'first_name'),
      username: message.dig('from', 'username'),
      message_text: message.dig('text'),
      timestamp: Time.current
    }
  end

  def new_user?(telegram_id)
    !Chat.exists?(telegram_id: telegram_id)
  end

  def within_cooldown_period?(telegram_id)
    last_contact = Chat.where(telegram_id: telegram_id)
                      .pluck(:last_contacted_at)
                      .first

    return false unless last_contact

    last_contact > ApplicationConfig.welcome_cooldown_minutes.minutes.ago
  end

  def process_new_user(user_info, webhook_data)
    create_chat_record(user_info)
    send_welcome_message(user_info)
    create_welcome_message_record(user_info)
    log_welcome_sent(user_info)
  end

  def route_to_existing_user_flow(user_info, webhook_data)
    update_last_contacted(user_info[:telegram_id])
    # Передача в LLM систему для обработки
    LlmMessageService.new.process_message(webhook_data)
  end

  def create_chat_record(user_info)
    Chat.create!(
      telegram_id: user_info[:telegram_id],
      username: user_info[:username],
      first_name: user_info[:first_name],
      last_contacted_at: user_info[:timestamp],
      created_at: user_info[:timestamp],
      updated_at: user_info[:timestamp]
    )
  end

  def send_welcome_message(user_info)
    template = load_template
    message = interpolate_template(template, user_info)

    @telegram_client.send_message(
      chat_id: user_info[:chat_id],
      text: message,
      parse_mode: nil  # Dialogue-Only - без форматирования
    )
  end

  def load_template
    template_path = ApplicationConfig.welcome_message_path

    unless File.exist?(template_path)
      Rails.logger.error "Welcome template not found: #{template_path}"
      return fallback_welcome_message
    end

    File.read(template_path).strip
  rescue StandardError => e
    Rails.logger.error "Error loading welcome template: #{e.message}"
    fallback_welcome_message
  end

  def interpolate_template(template, user_info)
    return template unless user_info[:first_name]&.strip&.present?

    # Безопасная интерполяция только имени
    safe_name = sanitize_name(user_info[:first_name])
    template.gsub("Здравствуйте!", "Здравствуйте, #{safe_name}!")
  end

  def sanitize_name(name)
    # Базовая санитизация имени
    name.strip[0..20].gsub(/[^а-яёА-ЯЁa-zA-Z\s-]/, '')
  end

  def fallback_welcome_message
    "🔧 Здравствуйте! Я Валера - AI-ассистент по кузовному ремонту. Расскажите, чем могу помочь?"
  end

  def create_welcome_message_record(user_info)
    chat = Chat.find_by(telegram_id: user_info[:telegram_id])
    return unless chat

    chat.messages.create!(
      content: load_template,
      role: 'assistant',
      message_type: 'welcome',
      created_at: user_info[:timestamp]
    )
  end

  def update_last_contacted(telegram_id)
    Chat.where(telegram_id: telegram_id)
        .update_all(last_contacted_at: Time.current)
  end

  def log_welcome_sent(user_info)
    Rails.logger.info "Welcome sent to user #{user_info[:telegram_id]} (#{user_info[:first_name]})"
  end

  def log_error(error, user_info)
    Rails.logger.error "WelcomeService error: #{error.message} for user #{user_info[:telegram_id]}"
    Rails.logger.error error.backtrace.join("\n") if Rails.env.development?
  end

  def handle_error_gracefully(error, user_info)
    # Graceful degradation - пытаемся отправить упрощенное сообщение
    begin
      @telegram_client.send_message(
        chat_id: user_info[:chat_id],
        text: "Здравствуйте! Я Валера, помощник по кузовному ремонту. Чем могу помочь?"
      )
    rescue StandardError => fallback_error
      Rails.logger.error "Failed to send fallback message: #{fallback_error.message}"
    end
  end
end
```

#### 2.2 Использование Telegram::WebhookController
```ruby
# app/controllers/telegram/webhook_controller.rb
class Telegram::WebhookController < Telegram::Bot::UpdatesController
  skip_before_action :verify_authenticity_token

  def webhook
    webhook_data = JSON.parse(request.body.read)

    # Валидация webhook от Telegram
    return render_invalid_webhook unless valid_webhook?(webhook_data)

    # Логирование входящего запроса
    Rails.logger.info "Telegram webhook received: #{webhook_data['update_id']}"

    # Обработка сообщения
    WelcomeService.new.handle_message(webhook_data)

    render json: { status: 'ok' }
  rescue JSON::ParserError => e
    Rails.logger.error "Invalid JSON in webhook: #{e.message}"
    render json: { error: 'Invalid JSON' }, status: :bad_request
  rescue StandardError => e
    Rails.logger.error "Webhook processing error: #{e.message}"
    render json: { error: 'Internal server error' }, status: :internal_server_error
  end

  private

  def valid_webhook?(webhook_data)
    webhook_data.is_a?(Hash) &&
    webhook_data['update_id'].present? &&
    webhook_data['message'].present?
  end

  def render_invalid_webhook
    Rails.logger.warn "Invalid webhook format received"
    render json: { error: 'Invalid webhook format' }, status: :bad_request
  end
end
```

#### 2.3 Обновление роутинга
```ruby
# config/routes.rb
Rails.application.routes.draw do
  # ... существующие роуты

  namespace :api do
    namespace :v1 do
      post 'telegram/webhook', to: 'telegram#webhook'
    end
  end
end
```

### Phase 3: Тестирование

#### 3.1 Unit тесты
```ruby
# test/services/welcome_service_test.rb
class WelcomeServiceTest < ActiveSupport::TestCase
  def setup
    @service = WelcomeService.new
    @mock_telegram_client = Minitest::Mock.new
    @service.instance_variable_set(:@telegram_client, @mock_telegram_client)
  end

  test "handles new user correctly" do
    webhook_data = {
      'message' => {
        'from' => { 'id' => 12345, 'first_name' => 'Александр' },
        'chat' => { 'id' => 12345 },
        'text' => 'Привет'
      }
    }

    # Ожидаем отправку welcome message
    @mock_telegram_client.expect(:send_message, true, [
      hash_including(
        chat_id: 12345,
        text: matches(/Здравствуйте, Александр!/)
      )
    ])

    @service.handle_message(webhook_data)

    assert Chat.exists?(telegram_id: 12345)
    assert_equal 1, Chat.find_by(telegram_id: 12345).messages.count
    @mock_telegram_client.verify
  end

  test "routes existing user to LLM flow" do
    # Создаем существующего пользователя
    chat = Chat.create!(telegram_id: 67890, first_name: 'Мария')

    webhook_data = {
      'message' => {
        'from' => { 'id' => 67890, 'first_name' => 'Мария' },
        'chat' => { 'id' => 67890 },
        'text' => 'Сколько стоит ремонт'
      }
    }

    # Мокаем LLM сервис
    llm_service_mock = Minitest::Mock.new
    LlmMessageService.stub(:new, llm_service_mock) do
      llm_service_mock.expect(:process_message, true, [webhook_data])

      @service.handle_message(webhook_data)

      llm_service_mock.verify
    end
  end

  test "respects cooldown period" do
    # Создаем пользователя с недавним контактом
    chat = Chat.create!(
      telegram_id: 11111,
      first_name: 'Елена',
      last_contacted_at: 10.minutes.ago
    )

    webhook_data = {
      'message' => {
        'from' => { 'id' => 11111 },
        'chat' => { 'id' => 11111 },
        'text' => 'Привет снова'
      }
    }

    # Не должно быть отправлено сообщение
    @mock_telegram_client.expect(:send_message, true, [Hash]).times(0)

    @service.handle_message(webhook_data)

    @mock_telegram_client.verify
  end
end
```

#### 3.2 Integration тесты
```ruby
# test/integration/telegram_webhook_test.rb
class TelegramWebhookTest < ActionDispatch::IntegrationTest
  test "complete new user flow" do
    webhook_data = {
      'update_id' => 123456789,
      'message' => {
        'message_id' => 1,
        'from' => {
          'id' => 987654321,
          'first_name' => 'Иван',
          'username' => 'ivan_user'
        },
        'chat' => {
          'id' => 987654321,
          'type' => 'private'
        },
        'text' => 'Привет',
        'date' => Time.current.to_i
      }
    }

    # Мокаем Telegram клиент
    TelegramClient.stub_any_instance(:send_message, true) do
      post '/api/v1/telegram/webhook',
           params: webhook_data.to_json,
           headers: { 'Content-Type' => 'application/json' }

      assert_response :success

      # Проверяем создание записей в БД
      assert Chat.exists?(telegram_id: 987654321)
      chat = Chat.find_by(telegram_id: 987654321)
      assert_equal 'Иван', chat.first_name
      assert_equal 'ivan_user', chat.username
      assert_equal 1, chat.messages.count
      assert_equal 'welcome', chat.messages.first.message_type
    end
  end
end
```


## 📋 Чек-лист готовности

### ✅ Готовность к реализации
- [ ] Все миграции выполнены и откатываемы
- [ ] Unit тесты проходят (покрытие > 90%)
- [ ] Integration тесты проходят
- [ ] Welcome message template существует и валиден
- [ ] Telegram bot token настроен
- [ ] Webhook URL доступен извне
- [ ] Performance тесты пройдены (< 200ms)

### ✅ Проверка функциональности
- [ ] Новые пользователи получают welcome message
- [ ] Существующие пользователи маршрутизируются в LLM
- [ ] Логирование работает
- [ ] Нет ошибок в логах

## 🔗 Связанные документы

- **User Story:** [US-001-telegram-auto-greeting.md](../user-stories/US-001-telegram-auto-greeting.md)
- **Technical Specification:** [TS-001-telegram-welcome-message.md](../specifications/TS-001-telegram-welcome-message.md)
- **Product Constitution:** [../../product/constitution.md](../../product/constitution.md)
- **Memory Bank:** [../../.claude/memory-bank.md](../../.claude/memory-bank.md)
- **Telegram Gem Docs:** [../../../docs/gems/telegram-bot/](../../../docs/gems/telegram-bot/)
- **Ruby LLM Docs:** [../../../docs/gems/ruby_llm/](../../../docs/gems/ruby_llm/)

## 🚨 Критические риски и митигация

### Риск: Template файл отсутствует
**Митигация:** Graceful degradation с fallback сообщением
```ruby
def fallback_welcome_message
  "🔧 Здравствуйте! Я Валера - AI-ассистент по кузовному ремонту. Расскажите, чем могу помочь?"
end
```

### Риск: Telegram API недоступен
**Митигация:** Retry механизм + Solid Queue
```ruby
def send_with_retry(chat_id, text, attempts = 3)
  @telegram_client.send_message(chat_id: chat_id, text: text)
rescue StandardError => e
  if attempts > 1
    sleep(1)
    send_with_retry(chat_id, text, attempts - 1)
  else
    Rails.logger.error "Failed to send message after 3 attempts: #{e.message}"
    raise
  end
end
```

### Риск: Высокая нагрузка
**Митигация:** Кэширование + Rate limiting
```ruby
# В контроллере
rate_limit = RateLimiter.new(request.remote_ip)
render json: { error: 'Too many requests' }, status: :too_many_requests unless rate_limit.allow?
```

## 📊 Метрики успеха

- **Welcome message delivery rate:** > 99%
- **Response time:** < 200ms (P95)
- **Error rate:** < 1%
- **New user conversion:** > 30% переходят к диалогу
- **User satisfaction:** < 5% сообщений "что ты умеешь?"

---

**История изменений:**
- 26.10.2025 23:00 - v1.0: Создание технического решения
  - Детализирован Hybrid Architecture подход
  - Добавлены полные примеры кода
  - Включен мониторинг и алерты
  - Определены риски и митигация
- 26.10.2025 23:30 - v1.1: Перенос из .protocols в technical-solutions
  - Обновлена структура документации
  - Исправлены ссылки на связанные документы