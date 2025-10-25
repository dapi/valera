# Technical Solution: TSOL-002 - Telegram User Chat Architecture

**Техническое решение:** TSOL-002-telegram-user-chat-architecture
**Статус:** Draft
**Приоритет:** High
**Версия:** 1.0
**Создан:** 27.10.2025
**Автор:** AI Agent
**Основан на:** ruby_llm архитектуре и protocol-db-chat-creation.md

## 🎯 Цель

Рефакторинг архитектуры для соответствия ruby_llm паттернам:
- Разделение пользователя Telegram и чата с AI
- Реализация правильных before_action фильтров
- Обеспечение сохранения истории диалогов

## 📋 Предварительные условия

### ✅ Требования к окружению
- [ ] Rails 8.1 приложение с ruby_llm gem
- [ ] Существующие модели Chat и Message
- [ ] База данных PostgreSQL
- [ ] Telegram бот с webhook'ами

## 🔧 План реализации

### Phase 1: Создание TelegramUser модели

#### 1.1 Миграция для создания TelegramUser
```ruby
# db/migrate/20251027000001_create_telegram_users.rb
class CreateTelegramUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :telegram_users do |t|
      t.bigint :telegram_id, null: false, index: { unique: true }
      t.string :username
      t.string :first_name
      t.string :last_name
      t.datetime :last_contacted_at
      t.timestamps
    end

    add_index :telegram_users, :last_contacted_at
  end
end
```

#### 1.2 Модель TelegramUser
```ruby
# app/models/telegram_user.rb
class TelegramUser < ApplicationRecord
  validates :telegram_id, presence: true, uniqueness: true

  has_many :chats, dependent: :destroy
  has_one :active_chat,
         -> { where(active: true) },
         class_name: 'Chat',
         dependent: :destroy

  # Находит или создает активный чат для пользователя
  def find_or_create_active_chat
    active_chat || chats.create!(active: true)
  end

  # Устанавливает чат как активный, деактивируя остальные
  def set_active_chat(chat)
    transaction do
      chats.update_all(active: false)
      chat.update!(active: true)
    end
  end

  # Обновляет время последнего контакта
  def touch_last_contacted
    update!(last_contacted_at: Time.current)
  end

  # Отображаемое имя
  def display_name
    first_name || username || "Пользователь #{telegram_id}"
  end
end
```

### Phase 2: Рефакторинг Chat модели

#### 2.1 Миграция для обновления Chat
```ruby
# db/migrate/20251027000002_update_chats_for_ruby_llm.rb
class UpdateChatsForRubyLlm < ActiveRecord::Migration[8.1]
  def change
    # Добавляем связь с пользователем
    add_reference :chats, :telegram_user, null: false, foreign_key: true
    add_column :chats, :active, :boolean, default: true
    add_column :chats, :title, :string

    # Добавляем индексы
    add_index :chats, :telegram_user_id
    add_index :chats, :active

    # Переносим данные из существующих чатов
    execute <<-SQL
      INSERT INTO telegram_users (telegram_id, username, first_name, last_contacted_at, created_at, updated_at)
      SELECT DISTINCT telegram_id, username, first_name, last_contacted_at, created_at, updated_at
      FROM chats
      WHERE telegram_id IS NOT NULL
    SQL

    execute <<-SQL
      UPDATE chats
      SET telegram_user_id = (SELECT id FROM telegram_users WHERE telegram_users.telegram_id = chats.telegram_id),
          title = 'Диалог от ' || COALESCE(first_name, 'Пользователь')
      WHERE telegram_id IS NOT NULL
    SQL

    # Удаляем старые поля
    remove_column :chats, :telegram_id
    remove_column :chats, :username
    remove_column :chats, :first_name
  end
end
```

#### 2.2 Обновленная модель Chat
```ruby
# app/models/chat.rb
class Chat < ApplicationRecord
  belongs_to :telegram_user
  has_many :messages, dependent: :destroy

  acts_as_chat  # ruby_llm интеграция

  scope :active, -> { where(active: true) }

  validates :title, presence: true

  # Делает чат активным для пользователя
  def activate!
    telegram_user.set_active_chat(self)
  end

  # Отображаемое название
  def display_title
    title
  end

  # Количество сообщений в чате
  def messages_count
    messages.count
  end

  # Последнее сообщение
  def last_message
    messages.order(:created_at).last
  end
end
```

### Phase 3: Обновление Message модели

#### 3.1 Миграция для обновления Message
```ruby
# db/migrate/20251027000003_update_messages_for_ruby_llm.rb
class UpdateMessagesForRubyLlm < ActiveRecord::Migration[8.1]
  def change
    # Убеждаемся, что связь с chat работает
    add_reference :messages, :chat, null: false, foreign_key: true unless foreign_key_exists?(:messages, :chat_id)

    # Добавляем поля для ruby_llm
    add_column :messages, :role, :string, default: 'user' unless column_exists?(:messages, :role)
    add_column :messages, :metadata, :jsonb, default: {} unless column_exists?(:messages, :metadata)
    add_column :messages, :message_type, :string unless column_exists?(:messages, :message_type)

    add_index :messages, :role
    add_index :messages, :message_type
  end
end
```

#### 3.2 Обновленная модель Message
```ruby
# app/models/message.rb
class Message < ApplicationRecord
  belongs_to :chat

  acts_as_message  # ruby_llm интеграция

  validates :content, presence: true
  validates :role, inclusion: { in: %w[user assistant system] }

  # Дополнительные поля для нашего проекта
  attribute :message_type, :string, default: 'user'

  # Проверка типа сообщения
  def user?
    role == 'user'
  end

  def assistant?
    role == 'assistant'
  end

  def system?
    role == 'system'
  end

  def welcome_message?
    message_type == 'welcome'
  end

  # Отображаемое время
  def formatted_time
    created_at.strftime('%H:%M')
  end
end
```

### Phase 4: Обновление TelegramController

#### 4.1 TelegramController с двумя before_action фильтрами
```ruby
# app/controllers/telegram_controller.rb
class TelegramController < Telegram::Bot::UpdatesController
  before_action :find_or_create_telegram_user
  before_action :find_or_create_db_chat

  # Обработка команды /start - приветствие новых пользователей
  def start!(*args)
    WelcomeService.new.send_welcome_message(@db_chat)
  end

  # Обработка обычных сообщений - временная реализация
  def message(message)
    # ВРЕМЕННАЯ РЕАЛИЗАЦИЯ для MVP
    # TODO: В US-002 будет реализован LlmMessageService для обработки сообщений
    respond_with :message, text: "Ваше сообщение получено! Бот находится в разработке. Используйте /start для приветствия."
  end

  # Callback queries (будущие inline кнопки)
  def callback_query(data)
    answer_callback_query('Спасибо за ваш запрос!')
  end

  private

  # Первый фильтр: находим/создаем пользователя Telegram
  def find_or_create_telegram_user
    telegram_id = from.id
    @telegram_user = TelegramUser.find_by(telegram_id: telegram_id)

    unless @telegram_user
      @telegram_user = TelegramUser.create!(
        telegram_id: telegram_id,
        username: from.username,
        first_name: from.first_name,
        last_name: from.last_name,
        last_contacted_at: Time.current
      )
    else
      # Обновляем время последнего контакта
      @telegram_user.touch_last_contacted
    end
  end

  # Второй фильтр: находим/создаем чат для диалога с AI
  def find_or_create_db_chat
    @db_chat = @telegram_user.find_or_create_active_chat
  end

  # Вспомогательные методы доступа
  def telegram_user
    @telegram_user
  end

  def db_chat
    @db_chat
  end
end
```

### Phase 5: Обновление сервисов

#### 5.1 Обновление WelcomeService
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
      metadata: { source: 'welcome_template', timestamp: Time.current }
    )

    # Отправляем через Telegram API
    send_telegram_message(db_chat.telegram_user.telegram_id, message)
    log_welcome_sent(db_chat)
  end

  private

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

  def interpolate_template(template, telegram_user)
    return template unless telegram_user.first_name&.strip&.present?

    name = telegram_user.first_name.strip[0..30]
    template.gsub("Здравствуйте!", "Здравствуйте, #{name}!")
  end

  def fallback_welcome_message
    "🔧 Здравствуйте! Я Валера - AI-ассистент по кузовному ремонту. Расскажите, чем могу помочь?"
  end

  def send_telegram_message(telegram_id, text)
    bot = Telegram.bot
    bot.api.send_message(
      chat_id: telegram_id,
      text: text,
      parse_mode: nil  # Dialogue-Only - без форматирования
    )
  rescue StandardError => e
    Rails.logger.error "Failed to send Telegram message: #{e.message}"
    handle_error_gracefully(e, telegram_id)
  end

  def handle_error_gracefully(error, telegram_id)
    begin
      bot = Telegram.bot
      bot.api.send_message(
        chat_id: telegram_id,
        text: "Здравствуйте! Я Валера, помощник по кузовному ремонту. Чем могу помочь?"
      )
    rescue StandardError => fallback_error
      Rails.logger.error "Failed to send fallback message: #{fallback_error.message}"
    end
  end

  def log_welcome_sent(db_chat)
    Rails.logger.info "Welcome sent to user #{db_chat.telegram_user.telegram_id} (#{db_chat.telegram_user.first_name}) in chat #{db_chat.id}"
  end
end
```

### Phase 6: Тестирование

#### 6.1 Unit тесты для TelegramUser
```ruby
# test/models/telegram_user_test.rb
class TelegramUserTest < ActiveSupport::TestCase
  def setup
    @user = TelegramUser.new(
      telegram_id: 12345,
      first_name: "John",
      username: "john_user"
    )
  end

  test "creates active chat when none exists" do
    @user.save!

    chat = @user.find_or_create_active_chat
    assert chat.persisted?
    assert_equal @user, chat.telegram_user
    assert chat.active?
    assert_equal "Диалог от John", chat.title
  end

  test "returns existing active chat" do
    @user.save!
    existing_chat = @user.chats.create!

    chat = @user.find_or_create_active_chat
    assert_equal existing_chat, chat
  end

  test "sets active chat correctly" do
    @user.save!
    chat1 = @user.chats.create!
    chat2 = @user.chats.create!

    chat2.activate!

    assert_not chat1.reload.active?
    assert chat2.reload.active?
  end

  test "display_name returns first name when available" do
    @user.save!
    assert_equal "John", @user.display_name
  end

  test "display_name falls back to username" do
    @user.first_name = nil
    @user.username = "john_user"
    @user.save!
    assert_equal "john_user", @user.display_name
  end

  test "display_name falls back to default" do
    @user.first_name = nil
    @user.username = nil
    @user.save!
    assert_equal "Пользователь 12345", @user.display_name
  end
end
```

#### 6.2 Unit тесты для Chat
```ruby
# test/models/chat_test.rb
class ChatTest < ActiveSupport::TestCase
  def setup
    @telegram_user = TelegramUser.create!(
      telegram_id: 12345,
      first_name: "John"
    )
    @chat = @telegram_user.chats.create!
  end

  test "responds to ruby_llm methods" do
    assert_respond_to @chat, :say
    assert_respond_to @chat, :respond
    assert_respond_to @chat, :messages
  end

  test "activates itself" do
    @chat.activate!
    assert @chat.reload.active?
    assert_equal @chat, @telegram_user.active_chat
  end

  test "counts messages correctly" do
    assert_equal 0, @chat.messages_count

    @chat.messages.create!(content: "Hello", role: 'user')
    assert_equal 1, @chat.messages_count
  end

  test "returns last message" do
    message1 = @chat.messages.create!(content: "Hello", role: 'user')
    message2 = @chat.messages.create!(content: "Hi there", role: 'assistant')

    assert_equal message2, @chat.last_message
  end
end
```

#### 6.3 Unit тесты для Message
```ruby
# test/models/message_test.rb
class MessageTest < ActiveSupport::TestCase
  def setup
    @telegram_user = TelegramUser.create!(telegram_id: 12345, first_name: "John")
    @chat = @telegram_user.chats.create!
    @message = @chat.messages.build(content: "Hello", role: 'user')
  end

  test "is valid with required attributes" do
    assert @message.valid?
  end

  test "responds to ruby_llm methods" do
    @message.save!
    assert_respond_to @message, :user?
    assert_respond_to @message, :assistant?
    assert_respond_to @message, :system?
  end

  test "identifies role correctly" do
    @message.role = 'user'
    assert @message.user?
    assert_not @message.assistant?

    @message.role = 'assistant'
    assert @message.assistant?
    assert_not @message.user?
  end

  test "identifies welcome messages" do
    @message.role = 'assistant'
    @message.message_type = 'welcome'
    assert @message.welcome_message?
  end

  test "formats time correctly" do
    @message.created_at = Time.new(2025, 1, 1, 15, 30)
    assert_equal "15:30", @message.formatted_time
  end
end
```

#### 6.4 Integration тесты для TelegramController
```ruby
# test/integration/telegram_controller_test.rb
class TelegramControllerTest < ActionDispatch::IntegrationTest
  def setup
    @initial_user_count = TelegramUser.count
    @initial_chat_count = Chat.count
  end

  test "creates telegram user and chat on first message" do
    post '/api/v1/telegram/webhook',
         params: webhook_payload,
         headers: { 'Content-Type' => 'application/json' }

    assert_response :success

    # Проверяем создание пользователя
    telegram_user = TelegramUser.find_by(telegram_id: 12345)
    assert telegram_user.present?
    assert_equal "John", telegram_user.first_name
    assert_equal "john_user", telegram_user.username
    assert_equal @initial_user_count + 1, TelegramUser.count

    # Проверяем создание чата
    assert telegram_user.active_chat.present?
    assert_equal @initial_chat_count + 1, Chat.count
    assert_equal "Диалог от John", telegram_user.active_chat.title
    assert telegram_user.active_chat.active?
  end

  test "reuses existing user and chat" do
    # Создаем пользователя и чат заранее
    existing_user = TelegramUser.create!(
      telegram_id: 12345,
      first_name: "John"
    )
    existing_chat = existing_user.chats.create!

    post '/api/v1/telegram/webhook',
         params: webhook_payload,
         headers: { 'Content-Type' => 'application/json' }

    assert_response :success

    # Проверяем, что не созданы новые записи
    assert_equal @initial_user_count + 1, TelegramUser.count
    assert_equal @initial_chat_count + 1, Chat.count

    # Проверяем, что используется существующий чат
    telegram_user = TelegramUser.find_by(telegram_id: 12345)
    assert_equal existing_chat, telegram_user.active_chat
  end

  test "updates last_contacted_at for existing user" do
    old_time = 1.hour.ago
    existing_user = TelegramUser.create!(
      telegram_id: 12345,
      first_name: "John",
      last_contacted_at: old_time
    )

    post '/api/v1/telegram/webhook',
         params: webhook_payload,
         headers: { 'Content-Type' => 'application/json' }

    assert_response :success

    existing_user.reload
    assert existing_user.last_contacted_at > old_time
  end

  test "handles start command correctly" do
    post '/api/v1/telegram/webhook',
         params: webhook_payload,
         headers: { 'Content-Type' => 'application/json' }

    assert_response :success

    # Проверяем, что создано welcome сообщение
    telegram_user = TelegramUser.find_by(telegram_id: 12345)
    chat = telegram_user.active_chat
    welcome_message = chat.messages.find_by(message_type: 'welcome')

    assert welcome_message.present?
    assert_equal 'assistant', welcome_message.role
    assert welcome_message.content.include?("Валера")
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

## 📋 Чек-лист готовности

### ✅ Phase readiness checks
- [ ] Все миграции созданы и протестированы
- [ ] TelegramUser, Chat, Message модели созданы с ruby_llm интеграцией
- [ ] TelegramController обновлен с двумя before_action фильтрами
- [ ] WelcomeService обновлен для работы с Chat
- [ ] Unit тесты для всех новых моделей проходят
- [ ] Integration тесты для контроллера проходят
- [ ] Данные успешно мигрированы из старых моделей
- [ ] ruby_llm acts_as_chat работает корректно

### ✅ Data migration verification
- [ ] Все существующие пользователи перенесены в TelegramUser
- [ ] Все существующие чаты обновлены с правильными связями
- [ ] История сообщений сохранена
- [ ] Целостность данных проверена

### ✅ Functionality verification
- [ ] Новый пользователь создает TelegramUser и Chat
- [ ] Существующий пользователь использует существующие записи
- [ ] Welcome message создается в Chat.messages
- [ ] last_contacted_at обновляется при каждом взаимодействии
- [ ] Активные чаты определяются корректно

---

**История изменений:**
- 27.10.2025 v1.0: Создание технического решения для User/Chat архитектуры
  - Разделение пользователя и чата согласно ruby_llm паттернам
  - Реализация двухуровневых before_action фильтров
  - Обновление всех сервисов для работы с новой архитектурой
  - Комплексное тестирование миграции и функциональности