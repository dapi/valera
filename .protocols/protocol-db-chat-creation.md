# Protocol: Создание Chat модели для ruby_llm архитектуры

**Протокол:** protocol-db-chat-creation
**Статус:** Draft
**Приоритет:** High
**Версия:** 1.0
**Создан:** 27.10.2025
**Автор:** AI Agent

## 🎯 Цель

Создать правильную архитектуру ruby_llm с разделением:
- **User (пользователь Telegram)** - основная сущность
- **Chat (переписка)** - диалог с AI для ruby_llm
- **Message (сообщения)** - отдельные сообщения в переписке

## 🏗️ Архитектурное решение

### **Текущая проблема:**
```ruby
# ❌ НЕПРАВИЛЬНО - смешаны пользователь и чат
class Chat < ApplicationRecord
  telegram_id: integer  # Это пользователь, не чат!
  first_name: string   # Это пользователь, не чат!
end
```

### **Правильная архитектура:**
```ruby
# ✅ ПРАВИЛЬНО - разделение ответственности
class TelegramUser < ApplicationRecord
  # Информация о пользователе Telegram
  telegram_id: integer
  first_name: string
  username: string

  has_many :chats
  has_one :active_chat, -> { where(active: true) }, class_name: 'Chat'
end

class Chat < ApplicationRecord
  # Переписка с AI (ruby_llm)
  belongs_to :telegram_user

  acts_as_chat  # ruby_llm интеграция

  has_many :messages
  attribute :active, :boolean, default: true
end

class Message < ApplicationRecord
  # Сообщения в переписке
  belongs_to :chat

  acts_as_message  # ruby_llm интеграция
end
```

## 📋 План имплентации

### Phase 1: Создание моделей

#### 1.1 Создание модели TelegramUser
```ruby
# db/migrate/XXXXXXXXXX_create_telegram_users.rb
class CreateTelegramUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :telegram_users do |t|
      t.bigint :telegram_id, null: false, index: { unique: true }
      t.string :username
      t.string :first_name
      t.string :last_name
      t.timestamps
    end
  end
end

# app/models/telegram_user.rb
class TelegramUser < ApplicationRecord
  validates :telegram_id, presence: true, uniqueness: true

  has_many :chats, dependent: :destroy
  has_one :active_chat,
         -> { where(active: true) },
         class_name: 'Chat',
         dependent: :destroy

  # Находит или создает активный чат
  def find_or_create_active_chat
    active_chat || chats.create!
  end

  # Устанавливает чат как активный
  def set_active_chat(chat)
    chats.update_all(active: false)
    chat.update!(active: true)
  end
end
```

#### 1.2 Обновление модели Chat
```ruby
# db/migrate/XXXXXXXXXX_update_chats_for_ruby_llm.rb
class UpdateChatsForRubyLlm < ActiveRecord::Migration[8.1]
  def change
    # Добавляем связь с пользователем
    add_reference :chats, :telegram_user, null: false, foreign_key: true
    add_column :chats, :active, :boolean, default: true

    # Добавляем индексы
    add_index :chats, :telegram_user_id
    add_index :chats, :active

    # Временно добавляем telegram_id для миграции данных
    add_column :chats, :telegram_id, :bigint

    # Переносим данные
    execute <<-SQL
      INSERT INTO telegram_users (telegram_id, username, first_name, created_at, updated_at)
      SELECT DISTINCT telegram_id, username, first_name, created_at, updated_at
      FROM chats
      WHERE telegram_id IS NOT NULL
    SQL

    execute <<-SQL
      UPDATE chats
      SET telegram_user_id = (SELECT id FROM telegram_users WHERE telegram_users.telegram_id = chats.telegram_id)
      WHERE telegram_id IS NOT NULL
    SQL

    # Удаляем старые поля
    remove_column :chats, :telegram_id
    remove_column :chats, :username
    remove_column :chats, :first_name
  end
end

# app/models/chat.rb
class Chat < ApplicationRecord
  belongs_to :telegram_user
  has_many :messages, dependent: :destroy

  acts_as_chat  # ruby_llm интеграция

  scope :active, -> { where(active: true) }

  # Делаем чат активным для пользователя
  def activate!
    telegram_user.set_active_chat(self)
  end
end
```

#### 1.3 Обновление модели Message
```ruby
# db/migrate/XXXXXXXXXX_update_messages_for_ruby_llm.rb
class UpdateMessagesForRubyLlm < ActiveRecord::Migration[8.1]
  def change
    # Убедимся, что связь с chat работает
    add_reference :messages, :chat, null: false, foreign_key: true if !column_exists?(:messages, :chat_id)

    # Добавляем поля для ruby_llm
    add_column :messages, :role, :string, default: 'user' unless column_exists?(:messages, :role)
    add_column :messages, :metadata, :jsonb, default: {} unless column_exists?(:messages, :metadata)
    add_column :messages, :message_type, :string unless column_exists?(:messages, :message_type)

    add_index :messages, :role
    add_index :messages, :message_type
  end
end

# app/models/message.rb
class Message < ApplicationRecord
  belongs_to :chat

  acts_as_message  # ruby_llm интеграция

  # Дополнительные поля для нашего проекта
  attribute :message_type, :string, default: 'user'
end
```

### Phase 2: Обновление контроллера

#### 2.1 TelegramController с двумя фильтрами
```ruby
# app/controllers/telegram_controller.rb
class TelegramController < Telegram::Bot::UpdatesController
  before_action :find_or_create_telegram_user
  before_action :find_or_create_db_chat

  # Обработка команды /start
  def start!(*args)
    WelcomeService.new.send_welcome_message(@db_chat)
  end

  # Обработка обычных сообщений
  def message(message)
    # Временная реализация
    respond_with :message, text: "Ваше сообщение получено! Бот находится в разработке."
  end

  private

  # Первый фильтр: находим/создаем пользователя
  def find_or_create_telegram_user
    telegram_id = from.id
    @telegram_user = TelegramUser.find_by(telegram_id: telegram_id)

    unless @telegram_user
      @telegram_user = TelegramUser.create!(
        telegram_id: telegram_id,
        username: from.username,
        first_name: from.first_name
      )
    end
  end

  # Второй фильтр: находим/создаем чат
  def find_or_create_db_chat
    @db_chat = @telegram_user.find_or_create_active_chat
  end

  # Вспомогательные методы
  def telegram_user
    @telegram_user
  end

  def db_chat
    @db_chat
  end
end
```

### Phase 3: Обновление сервисов

#### 3.1 WelcomeService для работы с Chat
```ruby
# app/services/welcome_service.rb
class WelcomeService
  def send_welcome_message(db_chat)
    template = load_template
    message = interpolate_template(template, db_chat.telegram_user)

    # Создаем сообщение в ruby_llm формате
    db_chat.messages.create!(
      content: message,
      role: 'assistant',
      message_type: 'welcome',
      metadata: { source: 'welcome_template' }
    )

    # Отправляем через Telegram API
    send_telegram_message(db_chat.telegram_user.telegram_id, message)
  end

  private

  def send_telegram_message(telegram_id, text)
    bot = Telegram.bot
    bot.api.send_message(
      chat_id: telegram_id,
      text: text,
      parse_mode: nil
    )
  rescue StandardError => e
    Rails.logger.error "Failed to send Telegram message: #{e.message}"
  end

  # ... остальные методы (load_template, interpolate_template)
end
```

### Phase 4: Тестирование

#### 4.1 Модели тесты
```ruby
# test/models/telegram_user_test.rb
class TelegramUserTest < ActiveSupport::TestCase
  test "creates active chat when none exists" do
    user = TelegramUser.create!(telegram_id: 12345, first_name: "Test")

    chat = user.find_or_create_active_chat
    assert chat.persisted?
    assert_equal user, chat.telegram_user
    assert chat.active?
  end

  test "returns existing active chat" do
    user = TelegramUser.create!(telegram_id: 12345, first_name: "Test")
    existing_chat = user.chats.create!

    chat = user.find_or_create_active_chat
    assert_equal existing_chat, chat
  end
end

# test/models/chat_test.rb
class ChatTest < ActiveSupport::TestCase
  test "acts_as_chat integration" do
    chat = Chat.create!(telegram_user: telegram_users(:one))

    assert_respond_to chat, :say
    assert_respond_to chat, :respond
    assert_respond_to chat, :messages
  end
end
```

#### 4.2 Контроллер тесты
```ruby
# test/controllers/telegram_controller_test.rb
class TelegramControllerTest < ActionDispatch::IntegrationTest
  test "creates telegram user on first message" do
    post '/api/v1/telegram/webhook',
         params: webhook_payload,
         headers: { 'Content-Type' => 'application/json' }

    assert_response :success

    telegram_user = TelegramUser.find_by(telegram_id: 12345)
    assert telegram_user.present?
    assert_equal "John", telegram_user.first_name
  end

  test "creates active chat for user" do
    post '/api/v1/telegram/webhook',
         params: webhook_payload,
         headers: { 'Content-Type' => 'application/json' }

    telegram_user = TelegramUser.find_by(telegram_id: 12345)
    assert telegram_user.active_chat.present?
    assert telegram_user.active_chat.active?
  end

  private

  def webhook_payload
    {
      "update_id" => 123456789,
      "message" => {
        "message_id" => 1,
        "from" => {
          "id" => 12345,
          "first_name" => "John",
          "username" => "john_user"
        },
        "chat" => {
          "id" => 12345,
          "type" => "private"
        },
        "text" => "/start",
        "date" => Time.current.to_i
      }
    }.to_json
  end
end
```

## 🔄 Migration Strategy

### Phase 1: Подготовка
1. Создать бэкап текущей базы данных
2. Создать новые модели в разработке

### Phase 2: Миграция данных
1. Запустить миграции
2. Проверить целостность данных
3. Обновить существующий код

### Phase 3: Тестирование
1. Unit тесты для новых моделей
2. Integration тесты для контроллера
3. End-to-end тесты

### Phase 4: Deployment
1. Миграция на staging
2. Тестирование с реальными данными
3. Миграция на production

## 📋 Чек-лист готовности

- [ ] Модели TelegramUser, Chat, Message созданы
- [ ] Migration scripts написаны и протестированы
- [ ] TelegramController обновлен с двумя фильтрами
- [ ] WelcomeService обновлен для работы с Chat
- [ ] Unit тесты написаны и проходят
- [ ] Integration тесты проходят
- [ ] Данные успешно мигрированы
- [ ] ruby_llm интеграция работает корректно

---

**История изменений:**
- 27.10.2025 - v1.0: Создание протокола разделения User/Chat архитектуры
  - Определена правильная архитектура ruby_llm
  - Создан план миграции данных
  - Обновлен контроллер с двумя before_action фильтрами