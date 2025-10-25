# Implementation Protocol: Telegram Service Booking

**Статус:** Ready for Development
**Приоритет:** High
**Версия:** 1.0
**Создан:** 25.10.2025
**Автор:** Technical Lead
**Срок:** 1 неделя (MVP)

## 📋 Обзор плана

### Цель
Реализовать AI-ассистента для записи на услуги автосервиса через Telegram с использованием ruby_llm. Пользователи могут естественным диалогом выбирать услуги, формировать корзину и оставлять заявки для менеджеров.

### Основанные документы
- **User Story:** [US-002-telegram-service-booking.md](../docs/requirements/user-stories/US-002-telegram-service-booking.md)
- **Feature Description:** [../docs/requirements/features/feature-telegram-service-booking.md](../docs/requirements/features/feature-telegram-service-booking.md)
- **Technical Specification:** [../docs/requirements/specifications/TS-002-telegram-booking-engine.md](../docs/requirements/specifications/TS-002-telegram-booking-engine.md)

## 🚀 План реализации (MVP - 1 неделя)

### Phase 1: Database & Models (День 1-2)

#### 1.1 Создание TelegramUser модели
**Файл:** `app/models/telegram_user.rb`
```ruby
class TelegramUser < ApplicationRecord
  self.primary_key = 'id'

  has_many :chats, dependent: :destroy
  has_many :bookings, dependent: :destroy

  validates :id, presence: true, uniqueness: true
  validates :username, uniqueness: { allow_nil: true }

  def self.find_or_create_from_webhook(data)
    where(id: data['id'])
      .first_or_create!(data.slice('first_name', 'last_name', 'username', 'photo_url'))
  end

  def update_last_contact!
    touch(:last_contact_at)
  end

  def display_name
    [first_name, last_name].compact.join(' ').presence || username.presence || "User ##{id}"
  end

  def find_or_create_chat!(chat_type: 'private')
    chats.find_or_create_by!(chat_type: chat_type)
  end
end
```

**Migration:** `db/migrate/20251025000001_create_telegram_users.rb`
```ruby
class CreateTelegramUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :telegram_users, id: false do |t|
      t.bigint :id, primary_key: true
      t.string :first_name
      t.string :last_name
      t.string :username
      t.string :photo_url
      t.string :language_code
      t.boolean :is_bot, default: false
      t.boolean :is_premium, default: false
      t.timestamp :last_contact_at
      t.timestamps
    end

    add_index :telegram_users, :username
    add_index :telegram_users, :last_contact_at
  end
end
```

#### 1.2 Расширение Chat модели
**Файл:** `app/models/chat.rb` (дополнить существующую)
```ruby
# Добавить к существующей модели
belongs_to :telegram_user

# Дополнительные поля (через migration)
# telegram_user_id (bigint)
# telegram_chat_id (bigint)
# chat_type (string)
```

**Migration:** `db/migrate/20251025000002_add_telegram_fields_to_chats.rb`
```ruby
class AddTelegramFieldsToChats < ActiveRecord::Migration[7.1]
  def change
    add_reference :chats, :telegram_user, null: false, foreign_key: true, index: true
    add_column :chats, :telegram_chat_id, :bigint
    add_column :chats, :chat_type, :string, default: 'private'
    add_index :chats, :telegram_chat_id
  end
end
```

#### 1.3 Создание Booking модели
**Файл:** `app/models/booking.rb`
```ruby
class Booking < ApplicationRecord
  belongs_to :telegram_user
  belongs_to :chat, optional: true

  validates :telegram_user, presence: true
  validates :customer_name, presence: true
  validates :services, presence: true
  validates :status, inclusion: { in: %w[pending confirmed cancelled completed] }

  serialize :services, JSON

  enum status: {
    pending: 'pending',
    confirmed: 'confirmed',
    cancelled: 'cancelled',
    completed: 'completed'
  }

  scope :pending, -> { where(status: :pending) }
  scope :recent, -> { order(created_at: :desc) }

  after_create :send_to_manager_job

  def total_price
    services.sum { |service| service[:price].to_f || 0 }
  end

  def car_display_name
    if car_brand && car_model
      "#{car_brand} #{car_model}#{car_year ? " (#{car_year})" : ''}"
    else
      "Информация уточняется"
    end
  end

  def manager_formatted_summary
    <<~TEXT
      🚗 ЗАЯВКА ##{id}

      👤 Клиент: #{customer_name}
      📞 Telegram: #{telegram_user.display_name}

      🛒 Услуги:
      #{services.map { |s| "• #{s[:name]} - #{s[:price]}₽" }.join("\n")}

      💰 Итого: #{total_price}₽

      🚗 Автомобиль: #{car_display_name}
      ⏰ Желаемое время: #{preferred_time || 'Не указано'}

      📅 Создана: #{created_at.strftime('%d.%m.%Y %H:%M')}
    TEXT
  end

  private

  def send_to_manager_job
    BookingJob.perform_later(id)
  end
end
```

**Migration:** `db/migrate/20251025000003_create_bookings.rb`
```ruby
class CreateBookings < ActiveRecord::Migration[7.1]
  def change
    create_table :bookings do |t|
      t.references :telegram_user, null: false, foreign_key: true
      t.references :chat, foreign_key: true

      t.string :customer_name
      t.string :customer_phone
      t.string :customer_telegram_username

      t.string :car_brand
      t.string :car_model
      t.integer :car_year
      t.string :car_class

      t.json :services, default: []
      t.decimal :total_price, precision: 10, scale: 2

      t.text :preferred_time
      t.text :problem_description

      t.string :status, default: 'pending'
      t.timestamp :sent_to_manager_at
      t.timestamp :manager_confirmed_at
      t.timestamp :completed_at

      t.timestamps
    end

    add_index :bookings, :status
    add_index :bookings, :created_at
    add_index :bookings, :telegram_user_id
    add_index :bookings, [:status, :created_at]
  end
end
```

### Phase 2: Webhook Processing (День 2-3)

#### 2.1 Telegram Controller
**Файл:** `app/controllers/api/v1/telegram_controller.rb`
```ruby
class Api::V1::TelegramController < ApplicationController
  skip_before_action :verify_authenticity_token

  def webhook
    TelegramWebhookService.new(request.body.read).process!
    head :ok
  rescue => e
    Rails.logger.error "Telegram webhook error: #{e.message}"
    Bugsnag.notify(e)
    head :unprocessable_entity
  end
end
```

#### 2.2 Routes
**Файл:** `config/routes.rb` (дополнить)
```ruby
namespace :api do
  namespace :v1 do
    post '/telegram/webhook', to: 'telegram#webhook'
  end
end
```

#### 2.3 TelegramWebhookService
**Файл:** `app/services/telegram_webhook_service.rb`
```ruby
class TelegramWebhookService
  def initialize(webhook_body)
    @webhook_data = JSON.parse(webhook_body)
  end

  def process!
    user_data = extract_user_data
    return unless user_data

    # Создаем/находим пользователя
    telegram_user = TelegramUser.find_or_create_from_webhook(user_data)
    telegram_user.update_last_contact!

    # Создаем/находим чат
    chat_data = extract_chat_data
    return unless chat_data

    chat = telegram_user.chats.find_or_create_by!(
      telegram_chat_id: chat_data['id'],
      chat_type: chat_data['type']
    )

    # Обрабатываем сообщение
    process_message(chat)
  end

  private

  def extract_user_data
    @webhook_data.dig('message', 'from') || @webhook_data.dig('callback_query', 'from')
  end

  def extract_chat_data
    @webhook_data.dig('message', 'chat') || @webhook_data.dig('callback_query', 'message', 'chat')
  end

  def process_message(chat)
    message_text = @webhook_data.dig('message', 'text')
    return unless message_text

    # ruby_llm integration
    response = generate_ai_response(message_text, chat)

    # Проверяем на создание booking
    if booking_intent_detected?(message_text)
      create_booking_from_context(chat)
      response = "✅ Заявка создана! Менеджер свяжется с вами в ближайшее время."
    end

    # Отправляем ответ
    send_response(chat.telegram_chat_id, response)
  end

  def generate_ai_response(message_text, chat)
    # ruby_llm integration с прайс-листом в промпте
    chat.respond_to(message_text)
  end

  def booking_intent_detected?(message_text)
    keywords = %w[записаться запись забронировать бронь оформить заявку]
    keywords.any? { |keyword| message_text.downcase.include?(keyword) }
  end

  def create_booking_from_context(chat)
    # Логика извлечения данных из контекста чата
    services = extract_services_from_context(chat)
    car_info = extract_car_info_from_context(chat)

    return if services.empty?

    Booking.create!(
      telegram_user: chat.telegram_user,
      chat: chat,
      customer_name: chat.telegram_user.display_name,
      customer_telegram_username: chat.telegram_user.username,
      services: services,
      car_brand: car_info[:brand],
      car_model: car_info[:model],
      car_year: car_info[:year],
      status: 'pending'
    )
  end

  def extract_services_from_context(chat)
    # TODO: Извлечь услуги из диалога (ruby_llm context)
    []
  end

  def extract_car_info_from_context(chat)
    # TODO: Извлечь информацию об автомобиле из диалога
    {}
  end

  def send_response(chat_id, message)
    # TODO: Отправка сообщения в Telegram
    Rails.logger.info "Sending to #{chat_id}: #{message}"
  end
end
```

### Phase 3: AI Integration & Prompts (День 3-4)

#### 3.1 Chat Model Enhancement
**Файл:** `app/models/chat.rb` (дополнить)
```ruby
# Добавить к существующей модели с ruby_llm integration

def respond_to(message_text)
  # Системный промпт с прайс-листом
  system_prompt = build_system_prompt_with_pricelist

  # ruby_llm integration
  response = ruby_llm_client.chat(
    messages: [
      { role: "system", content: system_prompt },
      { role: "user", content: message_text }
    ]
  )

  response.dig("choices", 0, "message", "content") || "Извините, не удалось сформулировать ответ."
end

private

def build_system_prompt_with_pricelist
  pricelist_text = File.read(Rails.root.join('data', 'price.csv'))

  <<~PROMPT
    Ты - AI-ассистент автосервиса Валера. Твоя задача:

    1. Помогать клиентам выбирать услуги из прайс-листа ниже
    2. Консультировать по стоимости и процессу
    3. Собирать заявки на запись

    Правила:
    - Всегда будь вежлив и профессионален
    - Предлагай только услуги из прайс-листа
    - Уточняй класс автомобиля для точной цены (1, 2, 3 класс)
    - Собирай информацию для записи (машина, время)
    - Не придумывай услуги, которых нет в прайсе

    ПРАЙС-ЛИСТ АВТОСЕРВИСА:
    #{pricelist_text}

    ВАЖНО: Используй только услуги из этого прайс-листа.
    Для каждого класса автомобиля указывай соответствующую цену.
    Если в диалоге не ясен класс автомобиля - уточни его у клиента.
  PROMPT
end

def ruby_llm_client
  # ruby_llm client configuration
  @ruby_llm_client ||= RubyLLM::Client.new(
    provider: Rails.application.config.llm[:provider],
    model: Rails.application.config.llm[:model],
    api_key: Rails.application.config.llm[:api_key]
  )
end
```

#### 3.2 Service Extraction from Context
**Файл:** `app/services/booking_context_extractor.rb`
```ruby
class BookingContextExtractor
  def self.extract_services(chat)
    # Используем ruby_llm для извлечения услуг из контекста
    context_messages = chat.messages.order(:created_at).last(10)
    context_text = context_messages.map(&:content).join("\n")

    prompt = <<~PROMPT
      Извлеки из диалога услуги, которые выбрал клиент.

      Диалог:
      #{context_text}

      Формат ответа (только JSON):
      {
        "services": [
          {
            "name": "название услуги",
            "price": цена,
            "car_class": "класс автомобиля (1/2/3)"
          }
        ]
      }
    PROMPT

    response = ruby_llm_client.chat(
      messages: [{ role: "user", content: prompt }]
    )

    JSON.parse(response.dig("choices", 0, "message", "content"))["services"]
  rescue => e
    Rails.logger.error "Service extraction error: #{e.message}"
    []
  end

  def self.extract_car_info(chat)
    # Аналогично извлекаем информацию об автомобиле
    context_messages = chat.messages.order(:created_at).last(10)
    context_text = context_messages.map(&:content).join("\n")

    prompt = <<~PROMPT
      Извлеки информацию об автомобиле из диалога.

      Диалог:
      #{context_text}

      Формат ответа (только JSON):
      {
        "brand": "марка автомобиля",
        "model": "модель автомобиля",
        "year": год,
        "class": "класс автомобиля (1/2/3)"
      }
    PROMPT

    response = ruby_llm_client.chat(
      messages: [{ role: "user", content: prompt }]
    )

    JSON.parse(response.dig("choices", 0, "message", "content"))
  rescue => e
    Rails.logger.error "Car info extraction error: #{e.message}"
    {}
  end

  private

  def self.ruby_llm_client
    RubyLLM::Client.new(
      provider: Rails.application.config.llm[:provider],
      model: Rails.application.config.llm[:model],
      api_key: Rails.application.config.llm[:api_key]
    )
  end
end
```

### Phase 4: Background Jobs & Manager Integration (День 4-5)

#### 4.1 BookingJob
**Файл:** `app/jobs/booking_job.rb`
```ruby
class BookingJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :exponentially_longer, attempts: 5

  def perform(booking_id)
    booking = Booking.find(booking_id)

    # Формируем сообщение для менеджера
    message = booking.manager_formatted_summary

    # Отправляем в менеджерский чат
    send_to_manager_chat(message)

    # Обновляем статус
    booking.update!(sent_to_manager_at: Time.current)

  rescue => e
    Rails.logger.error "BookingJob error for booking #{booking_id}: #{e.message}"
    Bugsnag.notify(e, { booking_id: booking_id })
    raise
  end

  private

  def send_to_manager_chat(message)
    # TODO: Реализовать отправку в Telegram менеджерский чат
    manager_chat_id = Rails.application.config.telegram[:manager_chat_id]

    TelegramBotClient.send_message(manager_chat_id, message)
  end
end
```

#### 4.2 TelegramBotClient
**Файл:** `app/services/telegram_bot_client.rb`
```ruby
require 'net/http'
require 'json'

class TelegramBotClient
  BASE_URL = 'https://api.telegram.org'

  def self.send_message(chat_id, text)
    uri = URI("#{BASE_URL}/bot#{telegram_token}/sendMessage")

    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request.body = {
      chat_id: chat_id,
      text: text,
      parse_mode: 'Markdown'
    }.to_json

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    unless response.code == '200'
      Rails.logger.error "Telegram API error: #{response.code} - #{response.body}"
    end

    response
  end

  private

  def self.telegram_token
    Rails.application.config.telegram[:token]
  end
end
```

### Phase 5: Configuration & Deployment (День 5)

#### 5.1 Configuration
**Файл:** `config/application.rb` (дополнить)
```ruby
config.telegram = {
  token: ENV['TELEGRAM_BOT_TOKEN'],
  manager_chat_id: ENV['MANAGER_TELEGRAM_CHAT_ID']
}
```

#### 5.2 Environment Variables
**Файл:** `.env` (пример)
```bash
# Telegram Bot Configuration
TELEGRAM_BOT_TOKEN=your_bot_token_here
MANAGER_TELEGRAM_CHAT_ID=@your_manager_chat

# Ruby LLM Configuration (уже существуют)
LLM_PROVIDER=openai
LLM_MODEL=gpt-4
LLM_API_KEY=your_api_key

# Monitoring
BUGSNAG_API_KEY=your_bugsnag_key
```

## 🧪 Тестирование (День 5-6)

### Unit Tests
```bash
# Модели
rails test test/models/telegram_user_test.rb
rails test test/models/booking_test.rb

# Сервисы
rails test test/services/telegram_webhook_service_test.rb
rails test test/services/booking_context_extractor_test.rb
```

### Integration Tests
```bash
# Webhook processing
rails test test/integration/telegram_webhook_test.rb

# Booking flow
rails test test/integration/booking_flow_test.rb
```

### Manual Testing
1. **Test webhook endpoint** с локального сервера через ngrok
2. **Test AI responses** с разными типами запросов
3. **Test booking creation** через диалог
4. **Test manager notifications** в реальном чате

## 📊 Проверка готовности (Checklist)

### Database
- [ ] Все migrations выполнены
- [ ] Модели созданы и работают
- [ ] Связи между моделями корректны

### Webhook Processing
- [ ] Endpoint `/api/v1/telegram/webhook` отвечает 200
- [ ] TelegramUser создается из webhook данных
- [ ] Chat создается и связывается с TelegramUser

### AI Integration
- [ ] ruby_llm конфигурация работает
- [ ] Системный промпт включает прайс-лист
- [ ] AI отвечает релевантными услугами

### Booking Flow
- [ ] Booking создается из контекста диалога
- [ ] BookingJob отправляет уведомление менеджеру
- [ ] Статусы booking обновляются корректно

### Error Handling
- [ ] Webhook ошибки логируются
- [ ] Job retry механизм работает
- [ ] Bugsnag интеграция настроена

## 🚀 Deployment

### Production Deployment Steps
```bash
# 1. Запуск migrations
rails db:migrate

# 2. Проверка конфигурации
rails runner "puts Rails.application.config.telegram.inspect"

# 3. Тестирование webhook endpoint
curl -X POST https://your-domain.com/api/v1/telegram/webhook \
  -H "Content-Type: application/json" \
  -d '{"message": {"text": "test", "from": {"id": 123, "first_name": "Test"}, "chat": {"id": 123}}}'

# 4. Мониторинг логов
heroku logs --tail | grep telegram
```

### Rollback Plan
```bash
# Отключение webhook (если проблемы)
# Скрытие функции через фичер-флаг
BOOKING_ENABLED=false

# Rollback migrations
rails db:rollback VERSION=20251025000003
```

## 📈 Метрики успеха

### Technical Metrics
- **Webhook response time** < 200ms
- **AI response time** < 5 секунд
- **Booking creation success rate** > 95%
- **Manager notification delivery** > 98%

### Business Metrics (через 3 месяца)
- **20% онлайн-записей** от общего числа
- **AI consultation accuracy** > 80%
- **Customer satisfaction** > 4.5/5

## ⚠️ Риски и митигация

| Риск | Вероятность | План |
|------|-------------|------|
| AI не понимает прайс-лист | Средняя | Улучшить промпты, добавить примеры |
| Контекст переполняется | Средняя | Ограничение до 10 сообщений |
| Менеджер не получает заявки | Низкая | Retry механизм, алерты |
| Telegram API limit | Средняя | Rate limiting, мониторинг |

## 🔄 Post-MVP Improvements (Phase 2)

1. **UI/UX улучшения** - кнопки, форматирование
2. **Расширенное извлечение контекста** - более умный парсинг
3. **Аналитика и дашборды** - метрики использования
4. **A/B тестирование промптов** - оптимизация AI
5. **Интеграция с календарем** - реальное время записи

---

**Готов к разработке:** ✅
**Необходимое время:** 1 неделя (MVP)
**Team:** Technical Lead + AI Agents
**Следующий шаг:** Начать Phase 1 - Database & Models