# Ruby LLM API Reference

## Core Classes and Methods

### RubyLLM.configure
Основной метод конфигурации gem:

```ruby
RubyLLM.configure do |config|
  config.use_new_acts_as = true
  config.request_timeout = 120
  config.max_retries = 1
  config.openai_api_key = ENV['OPENAI_API_KEY']
  config.anthropic_api_key = ENV['ANTHROPIC_API_KEY']
  config.gemini_api_key = ENV['GEMINI_API_KEY']
  config.deepseek_api_key = ENV['DEEPSEEK_API_KEY']
  config.perplexity_api_key = ENV['PERPLEXITY_API_KEY']
  config.openrouter_api_key = ENV['OPENROUTER_API_KEY']
  config.mistral_api_key = ENV['MISTRAL_API_KEY']
  config.vertexai_location = ENV['GOOGLE_CLOUD_LOCATION']
  config.vertexai_project_id = ENV['GOOGLE_CLOUD_PROJECT']
  config.default_model = 'gpt-4'
  config.default_embedding_model = 'text-embedding-3-large'
  config.default_image_model = 'dall-e-3'
end
```

### RubyLLM.chat
Создание нового чата:

```ruby
# Базовый чат
chat = RubyLLM.chat.new

# С указанием модели
chat = RubyLLM.chat.new(model: 'gpt-4')

# С системным промптом
chat = RubyLLM.chat.new(
  model: 'claude-sonnet-4',
  system: "Ты - полезный ассистент"
)

# С инструментами
chat = RubyLLM.chat.new(
  model: 'gpt-4',
  tools: [tool_definition]
)

# С параметрами
chat = RubyLLM.chat.new(
  model: 'gpt-4',
  temperature: 0.7,
  max_tokens: 1000,
  top_p: 0.9
)
```

### RubyLLM.chat.say
Отправка сообщения в чат:

```ruby
# Простое сообщение
response = chat.say("Привет, мир!")

# С опциями
response = chat.say(
  "Расскажи историю",
  stream: false,
  temperature: 0.8
)

# С изображениями
response = chat.say(
  "Опиши это изображение",
  images: ['path/to/image.jpg']
)

# Стриминг ответа
chat.say("Напиши историю", stream: true) do |chunk|
  print chunk.content
end
```

### RubyLLM.chat.messages
Получение истории сообщений:

```ruby
chat.messages.each do |message|
  puts "#{message.role}: #{message.content}"
end

# Фильтрация по роли
user_messages = chat.messages.select { |m| m.role == :user }
assistant_messages = chat.messages.select { |m| m.role == :assistant }
```

### RubyLLM.embed
Создание эмбеддингов:

```ruby
# Базовое использование
embedding = RubyLLM.embed("Пример текста")

# С указанием модели
embedding = RubyLLM.embed(
  "Пример текста",
  model: 'text-embedding-3-large'
)

# Пакетная обработка
embeddings = RubyLLM.embed([
  "Текст 1",
  "Текст 2",
  "Текст 3"
])
```

### RubyLLM.paint
Генерация изображений:

```ruby
# Базовая генерация
image = RubyLLM.paint("Красивый закат")

# С параметрами
image = RubyLLM.paint(
  "Закат над горами",
  model: 'dall-e-3',
  size: '1024x1024',
  quality: 'hd'
)

# С указанием стиля
image = RubyLLM.paint(
  "Кот в стиле Ван Гога",
  style: 'vivid'
)
```

## Model Management

### RubyLLM.models
Работа с моделями:

```ruby
# Получение всех моделей
models = RubyLLM.models

# Фильтрация по провайдеру
openai_models = RubyLLM.models.select(provider: :openai)
anthropic_models = RubyLLM.models.select(provider: :anthropic)

# Фильтрация по возможностям
vision_models = RubyLLM.models.select(capabilities: :vision)
text_models = RubyLLM.models.select(capabilities: :text)

# Фильтрация по семейству
gpt_models = RubyLLM.models.select(family: 'gpt')
claude_models = RubyLLM.models.select(family: 'claude')

# Поиск конкретной модели
model = RubyLLM.models.find('gpt-4')

# Получение информации о модели
model.id           # 'gpt-4'
model.name         # 'GPT-4'
model.provider     # :openai
model.family       # 'gpt'
model.context_window # 8192
model.max_output_tokens # 4096
model.modalities   # [:text, :vision]
model.capabilities # [:chat, :vision, :tools]
model.pricing      # { input: 0.03, output: 0.06 }
```

### RubyLLM.models.load_from_json!
Загрузка моделей из JSON файла:

```ruby
RubyLLM.models.load_from_json!
```

## Active Record Integration

### acts_as_chat
Макрос для ActiveRecord моделей:

```ruby
class Chat < ApplicationRecord
  acts_as_chat

  # Автоматически добавляет:
  # - association :messages
  # - association :tool_calls
  # - method model
  # - method system
  # - method temperature
  # - method say(content, options = {})
  # - method clear_messages!
end
```

### acts_as_message
Макрос для сообщений:

```ruby
class Message < ApplicationRecord
  acts_as_message

  # Автоматически добавляет:
  # - association chat
  # - attribute content
  # - attribute role
  # - attribute metadata
  # - method images
  # - method tool_calls
  # - method assistant?
  # - method user?
  # - method system?
end
```

### acts_as_tool_call
Макрос для вызовов инструментов:

```ruby
class ToolCall < ApplicationRecord
  acts_as_tool_call

  # Автоматически добавляет:
  # - association message
  # - attribute name
  # - attribute arguments
  # - attribute result
  # - attribute status
  # - method success?
  # - method failed?
  # - method pending?
end
```

## Tool/Function Calling

### Tool Definition
Определение инструментов:

```ruby
weather_tool = {
  name: 'get_weather',
  description: 'Получает текущую погоду для указанного города',
  parameters: {
    type: 'object',
    properties: {
      city: {
        type: 'string',
        description: 'Название города'
      },
      units: {
        type: 'string',
        enum: ['celsius', 'fahrenheit'],
        description: 'Единицы измерения температуры'
      }
    },
    required: ['city']
  }
}

database_tool = {
  name: 'search_customers',
  description: 'Поиск клиентов в базе данных',
  parameters: {
    type: 'object',
    properties: {
      query: {
        type: 'string',
        description: 'Поисковый запрос'
      },
      limit: {
        type: 'integer',
        description: 'Максимальное количество результатов',
        default: 10
      }
    },
    required: ['query']
  }
}
```

### Tool Usage
Использование инструментов в чате:

```ruby
chat = RubyLLM.chat.new(
  model: 'gpt-4',
  tools: [weather_tool, database_tool]
)

response = chat.say("Какая погода в Москве?")

if response.tool_calls.any?
  response.tool_calls.each do |tool_call|
    case tool_call.name
    when 'get_weather'
      city = JSON.parse(tool_call.arguments)['city']
      weather = get_weather_data(city)

      # Отправка результата инструменту
      chat.say(
        tool_result: {
          tool_call_id: tool_call.id,
          result: weather
        }
      )
    end
  end
end
```

## Streaming Responses

### Basic Streaming
```ruby
chat = RubyLLM.chat.new(model: 'gpt-4')

chat.say("Напиши историю о роботе", stream: true) do |chunk|
  print chunk.content
  $stdout.flush
end
```

### Streaming with Progress
```ruby
def stream_with_progress(chat, message)
  puts "Начинаю генерацию..."
  chars_written = 0

  chat.say(message, stream: true) do |chunk|
    print chunk.content
    chars_written += chunk.content.length

    # Прогресс бар
    if chars_written % 50 == 0
      puts "\n[#{'=' * (chars_written / 50)}]"
    end
  end

  puts "\nГенерация завершена!"
end
```

## Error Types

### RubyLLM::AuthenticationError
Ошибка аутентификации API:

```ruby
begin
  response = chat.say("Привет")
rescue RubyLLM::AuthenticationError => e
  puts "Неверный API ключ: #{e.message}"
  # Проверьте настройки API ключей
end
```

### RubyLLM::RateLimitError
Превышение лимита запросов:

```ruby
begin
  response = chat.say("Привет")
rescue RubyLLM::RateLimitError => e
  puts "Превышен лимит запросов"
  puts "Повторите через #{e.retry_after} секунд"
  sleep(e.retry_after)
  retry
end
```

### RubyLLM::InvalidRequestError
Некорректный запрос:

```ruby
begin
  response = chat.say("")  # Пустое сообщение
rescue RubyLLM::InvalidRequestError => e
  puts "Некорректный запрос: #{e.message}"
  # Проверьте входные параметры
end
```

### RubyLLM::APIError
Общая ошибка API:

```ruby
begin
  response = chat.say("Привет")
rescue RubyLLM::APIError => e
  puts "Ошибка API: #{e.message}"
  puts "Код ошибки: #{e.code}"
end
```

## Configuration Options

### Основные параметры конфигурации:

- `use_new_acts_as` - Boolean: Использовать новую версию acts_as макросов
- `request_timeout` - Integer: Таймаут запросов в секундах
- `max_retries` - Integer: Максимальное количество попыток повтора
- `default_model` - String: Модель по умолчанию
- `default_embedding_model` - String: Модель эмбеддингов по умолчанию
- `default_image_model` - String: Модель генерации изображений по умолчанию

### API ключи провайдеров:

- `openai_api_key` - String: API ключ OpenAI
- `anthropic_api_key` - String: API ключ Anthropic
- `gemini_api_key` - String: API ключ Google Gemini
- `deepseek_api_key` - String: API ключ DeepSeek
- `perplexity_api_key` - String: API ключ Perplexity
- `openrouter_api_key` - String: API ключ OpenRouter
- `mistral_api_key` - String: API ключ Mistral

### Настройки Vertex AI:

- `vertexai_location` - String: Локация Google Cloud
- `vertexai_project_id` - String: ID проекта Google Cloud

## Response Objects

### Chat Response
```ruby
response = chat.say("Привет!")

# Основные атрибуты
response.content      # String: Текст ответа
response.model        # String: Использованная модель
response.usage        # Hash: Информация об использовании токенов
response.finish_reason # String: Причина завершения
response.created_at   # Time: Время создания

# Информация о токенах
response.usage[:prompt_tokens]     # Integer
response.usage[:completion_tokens] # Integer
response.usage[:total_tokens]      # Integer
```

### Image Response
```ruby
image = RubyLLM.paint("Закат")

# Основные атрибуты
image.url          # String: URL изображения
image.revised_prompt # String: Измененный промпт (если есть)
image.model        # String: Использованная модель
image.created_at   # Time: Время создания
```

### Embedding Response
```ruby
embedding = RubyLLM.embed("Текст")

# Основные атрибуты
embedding.vector   # Array<Float]: Вектор эмбеддинга
embedding.model    # String: Использованная модель
embedding.usage    # Hash: Информация об использовании токенов
```

## Performance Monitoring

### Usage Tracking
```ruby
class LLMUsageTracker
  def self.track_usage
    RubyLLM.configure do |config|
      config.before_request = lambda do |request|
        Rails.logger.info "LLM Request: #{request.model}, tokens: #{request.estimated_tokens}"
      end

      config.after_request = lambda do |response|
        Rails.logger.info "LLM Response: #{response.usage[:total_tokens]} tokens used"
      end
    end
  end
end
```