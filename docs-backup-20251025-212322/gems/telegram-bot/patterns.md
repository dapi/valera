# Telegram Bot Architecture Patterns

## Основные архитектурные паттерны для Telegram ботов

### 1. Command Handler Pattern

Паттерн для обработки команд бота с использованием хэша методов:

```ruby
class CommandHandler
  COMMANDS = {
    '/start' => :handle_start,
    '/help' => :handle_help,
    '/settings' => :handle_settings,
    '/cancel' => :handle_cancel
  }.freeze

  def handle_command(message)
    command = message.text.split.first
    method_name = COMMANDS[command]

    if method_name
      send(method_name, message)
    else
      handle_unknown_command(message)
    end
  end

  private

  def handle_start(message)
    # Логика команды /start
  end

  # ... другие методы
end
```

### 2. State Machine Pattern

Паттерн для управления состоянием пользователя в диалоге:

```ruby
class UserStateMachine
  STATES = {
    idle: :idle,
    registration: :waiting_name,
    booking: :selecting_service,
    feedback: :collecting_feedback
  }.freeze

  def initialize
    @user_states = {}
  end

  def transition(user_id, new_state, data = {})
    @user_states[user_id] = {
      state: new_state,
      data: data,
      updated_at: Time.now
    }
  end

  def get_state(user_id)
    @user_states.dig(user_id, :state) || :idle
  end

  def get_data(user_id)
    @user_states.dig(user_id, :data) || {}
  end
end
```

### 3. Middleware Pattern

Паттерн для обработки входящих сообщений через цепочку middleware:

```ruby
class MessageMiddleware
  def initialize
    @middlewares = []
  end

  def use(middleware)
    @middlewares << middleware
  end

  def call(message, bot)
    @middlewares.reduce(message) do |msg, middleware|
      break if msg == :stop
      middleware.call(msg, bot)
    end
  end
end

# Пример middleware
class AuthMiddleware
  def call(message, bot)
    user_id = message.from.id
    return :stop unless authorized?(user_id)
    message
  end

  private

  def authorized?(user_id)
    # Проверка авторизации
  end
end
```

### 4. Service Layer Pattern

Разделение бизнес-логики на сервисы:

```ruby
# app/services/registration_service.rb
class RegistrationService
  def initialize(user_id, bot)
    @user_id = user_id
    @bot = bot
  end

  def start
    send_welcome_message
    transition_to_name_input
  end

  def process_name(name)
    return invalid_name unless valid_name?(name)

    save_name(name)
    request_age
  end

  private

  def send_welcome_message
    @bot.api.send_message(
      chat_id: get_chat_id,
      text: "Добро пожаловать! Давайте начнем регистрацию."
    )
  end

  def get_chat_id
    # Получение chat_id из состояния или базы данных
  end
end
```

### 5. Repository Pattern

Паттерн для работы с данными пользователей:

```ruby
class UserRepository
  def initialize(storage = Redis.new)
    @storage = storage
  end

  def find(user_id)
    data = @storage.get("user:#{user_id}")
    data ? JSON.parse(data, symbolize_names: true) : nil
  end

  def save(user_id, data)
    @storage.set("user:#{user_id}", data.to_json)
  end

  def find_all_active
    keys = @storage.keys("user:*")
    keys.map { |key| find(key.split(':').last) }.compact
  end
end
```

### 6. Observer Pattern

Паттерн для обработки событий бота:

```ruby
class BotEventDispatcher
  def initialize
    @listeners = Hash.new { |h, k| h[k] = [] }
  end

  def subscribe(event_type, listener)
    @listeners[event_type] << listener
  end

  def dispatch(event_type, data)
    @listeners[event_type].each { |listener| listener.call(data) }
  end
end

# Использование
dispatcher = BotEventDispatcher.new
dispatcher.subscribe(:message_received, method(:log_message))
dispatcher.subscribe(:user_registered, method(:send_welcome_email))
```

### 7. Factory Pattern

Паттерн для создания разных типов ответов:

```ruby
class ResponseFactory
  def self.create(type, chat_id, content)
    case type
    when :text
      TextResponse.new(chat_id, content)
    when :photo
      PhotoResponse.new(chat_id, content)
    when :keyboard
      KeyboardResponse.new(chat_id, content)
    else
      raise "Unknown response type: #{type}"
    end
  end
end

class TextResponse
  def initialize(chat_id, text)
    @chat_id = chat_id
    @text = text
  end

  def send(bot)
    bot.api.send_message(chat_id: @chat_id, text: @text)
  end
end
```

### 8. Strategy Pattern

Паттерн для разных стратегий обработки:

```ruby
class MessageProcessor
  def initialize(strategy)
    @strategy = strategy
  end

  def process(message, bot)
    @strategy.execute(message, bot)
  end
end

class TextMessageStrategy
  def execute(message, bot)
    # Обработка текстовых сообщений
  end
end

class PhotoMessageStrategy
  def execute(message, bot)
    # Обработка фотографий
  end
end
```

### 9. Template Method Pattern

Паттерн для базового шаблона обработки сообщений:

```ruby
class BaseMessageHandler
  def handle(message, bot)
    validate_message(message)
    process_message(message, bot)
    log_interaction(message)
  rescue => e
    handle_error(e, message, bot)
  end

  protected

  def validate_message(message)
    # Базовая валидация
  end

  def process_message(message, bot)
    # Абстрактный метод для переопределения
    raise NotImplementedError
  end

  def log_interaction(message)
    # Логирование взаимодействия
  end

  def handle_error(error, message, bot)
    # Обработка ошибок
  end
end
```

### 10. Singleton Pattern

Паттерн для глобального доступа к боту:

```ruby
class BotInstance
  include Singleton

  def initialize
    @bot = nil
  end

  def configure(token)
    @bot = Telegram::Bot::Client.new(token)
  end

  def bot
    raise "Bot not configured" unless @bot
    @bot
  end

  def send_message(chat_id, text, options = {})
    bot.api.send_message(chat_id: chat_id, text: text, **options)
  end
end
```

## Комбинированные паттерны

### MVC-подобная структура для Telegram бота

```ruby
# Models
class User
  attr_accessor :id, :name, :state, :data

  def initialize(id)
    @id = id
    @state = :idle
    @data = {}
  end
end

# Controllers
class RegistrationController
  def initialize(bot, user)
    @bot = bot
    @user = user
  end

  def start
    @bot.api.send_message(
      chat_id: @user.id,
      text: "Давайте начнем регистрацию. Введите ваше имя:"
    )
    @user.state = :waiting_name
  end

  def process_name(message)
    # Обработка имени
  end
end

# Views (Response builders)
class ResponseBuilder
  def self.welcome_message(user)
    {
      text: "Добро пожаловать, #{user.name}!",
      reply_markup: main_keyboard
    }
  end

  private

  def self.main_keyboard
    Telegram::Bot::Types::ReplyKeyboardMarkup.new(
      keyboard: [['Профиль', 'Настройки']],
      resize_keyboard: true
    )
  end
end
```

### Pipeline Pattern для обработки сообщений

```ruby
class MessagePipeline
  def initialize
    @steps = []
  end

  def add_step(step)
    @steps << step
  end

  def process(message, bot)
    context = { message: message, bot: bot, stop: false }

    @steps.each do |step|
      break if context[:stop]
      step.call(context)
    end

    context
  end
end

# Использование
pipeline = MessagePipeline.new
pipeline.add_step(method(:validate_user))
pipeline.add_step(method(:handle_command))
pipeline.add_step(method(:save_state))
pipeline.add_step(method(:log_activity))
```

## Best Practices

### 1. Безопасность
- Всегда валидируйте входящие данные
- Храните токены в ENV переменных
- Используйте rate limiting
- Проверяйте права доступа пользователей

### 2. Масштабирование
- Используйте очереди для фоновых задач
- Разделяйте логику на сервисы
- Применяйте кэширование для частых запросов
- Используйте вебхуки для высокой нагрузки

### 3. Тестирование
- Изолируйте логику от Telegram API
- Используйте моки для API вызовов
- Пишите юнит-тесты для бизнес-логики
- Тестируйте состояния пользователя

### 4. Мониторинг
- Логируйте все ошибки
- Отслеживайте метрики использования
- Мониторьте состояние бота
- Настройте алерты для критических ошибок

### 5. UX/UI
- Предоставляйте четкие инструкции
- Используйте инлайн кнопки для сложных действий
- Показывайте индикаторы загрузки
- Обрабатывайте таймауты ожидания