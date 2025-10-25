# Ruby LLM API Reference

## Core Classes and Methods


### RubyLLM.chat
Создание нового чата:

```ruby
# Основные варианты создания чата
chat = RubyLLM.chat.new(model: 'gpt-4', system: "Ассистент")
chat = RubyLLM.chat.new(model: 'gpt-4', tools: [tool_definition])
```

### RubyLLM.chat.say
Отправка сообщения в чат:

```ruby
# Ключевые опции
response = chat.say("Привет, мир!", stream: false, temperature: 0.8)
response = chat.say("Опиши изображение", images: ['path/to/image.jpg'])
```

### RubyLLM.chat.messages
Получение истории сообщений:

```ruby
chat.messages.each { |m| puts "#{m.role}: #{m.content}" }
user_messages = chat.messages.select { |m| m.role == :user }
```

### RubyLLM.embed
Создание эмбеддингов:

```ruby
embedding = RubyLLM.embed("Пример текста", model: 'text-embedding-3-large')
embeddings = RubyLLM.embed(["Текст 1", "Текст 2"])
```

### RubyLLM.paint
Генерация изображений:

```ruby
image = RubyLLM.paint("Закат над горами", model: 'dall-e-3', size: '1024x1024')
image = RubyLLM.paint("Кот в стиле Ван Гога", style: 'vivid')
```

## Model Management

### RubyLLM.models
Работа с моделями:

```ruby
# Основные операции с моделями
models = RubyLLM.models
openai_models = RubyLLM.models.select(provider: :openai)
vision_models = RubyLLM.models.select(capabilities: :vision)
model = RubyLLM.models.find('gpt-4')

# Атрибуты модели
model.id, model.name, model.provider, model.family
model.context_window, model.capabilities, model.pricing
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