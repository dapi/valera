# Ruby LLM Gem Documentation

## Overview
`ruby_llm` - это Ruby gem для работы с различными языковыми моделями (LLM) через единый интерфейс. Поддерживает OpenAI, Anthropic, Google Gemini, и другие провайдеры.

## Installation
```ruby
gem 'ruby_llm', '~> 1.8'
```

## Basic Configuration

### Initializer Setup
```ruby
# config/initializers/ruby_llm.rb
require 'ruby_llm'

RubyLLM.configure do |config|
  config.use_new_acts_as = true
  config.request_timeout = 120
  config.max_retries = 1

  # API ключи для разных провайдеров
  config.openai_api_key = ENV.fetch('OPENAI_API_KEY')
  config.anthropic_api_key = ENV.fetch('ANTHROPIC_API_KEY')
  config.gemini_api_key = ENV.fetch('GEMINI_API_KEY')
  config.deepseek_api_key = ENV.fetch('DEEPSEEK_API_KEY')
  config.perplexity_api_key = ENV.fetch('PERPLEXITY_API_KEY')
  config.openrouter_api_key = ENV.fetch('OPENROUTER_API_KEY')
  config.mistral_api_key = ENV.fetch('MISTRAL_API_KEY')

  # Настройки для Vertex AI
  config.vertexai_location = ENV.fetch('GOOGLE_CLOUD_LOCATION')
  config.vertexai_project_id = ENV.fetch('GOOGLE_CLOUD_PROJECT')

  # Модели по умолчанию
  config.default_model = 'claude-sonnet-4'
  config.default_embedding_model = 'text-embedding-3-large'
  config.default_image_model = 'dall-e-3'
end
```

## Core Concepts

### 1. Models (Модели)
RubyLLM предоставляет доступ к различным языковым моделям через единый интерфейс:

```ruby
# Получение списка всех моделей
models = RubyLLM.models

# Фильтрация моделей по провайдеру
openai_models = RubyLLM.models.select(provider: :openai)
anthropic_models = RubyLLM.models.select(provider: :anthropic)

# Фильтрация по возможностям
vision_models = RubyLLM.models.select(capabilities: :vision)
text_models = RubyLLM.models.select(capabilities: :text)
```

### 2. Chats (Чаты)
Чаты представляют собой диалоги с моделью с сохранением контекста:

```ruby
# Создание нового чата
chat = RubyLLM.chat.new(model: 'gpt-4')

# Добавление сообщений
chat.say "Привет! Как дела?"
response = chat.say "Расскажи мне о Ruby"

# Получение истории сообщений
chat.messages.each do |message|
  puts "#{message.role}: #{message.content}"
end
```

### 3. Messages (Сообщения)
Сообщения являются основными строительными блоками чатов:

```ruby
# Создание сообщения
message = RubyLLM.message.new(
  role: :user,
  content: "Привет, мир!",
  metadata: { source: 'user_input' }
)

# Сообщения с поддержкой медиа
message_with_image = RubyLLM.message.new(
  role: :user,
  content: "Опиши это изображение",
  images: ['path/to/image.jpg']
)
```

### 4. Tool Calls (Вызовы инструментов)
RubyLLM поддерживает вызов функций/инструментов:

```ruby
# Определение инструмента
weather_tool = {
  name: 'get_weather',
  description: 'Получает текущую погоду для указанного города',
  parameters: {
    type: 'object',
    properties: {
      city: { type: 'string', description: 'Название города' },
      units: { type: 'string', enum: ['celsius', 'fahrenheit'] }
    },
    required: ['city']
  }
}

# Использование инструмента в чате
chat = RubyLLM.chat.new(
  model: 'gpt-4',
  tools: [weather_tool]
)

response = chat.say "Какая погода в Москве?"
```

## Rails Integration

### Active Record Integration
RubyLLM предоставляет seamless интеграцию с Rails через `acts_as` макросы:

```ruby
# app/models/chat.rb
class Chat < ApplicationRecord
  acts_as_chat

  # Дополнительные методы и валидации
  validates :title, presence: true

  def summarize
    messages.last&.content&.truncate(100)
  end
end

# app/models/message.rb
class Message < ApplicationRecord
  acts_as_message
  has_many_attached :attachments

  # Валидации
  validates :content, presence: true

  def formatted_content
    # Форматирование контента сообщения
  end
end

# app/models/tool_call.rb
class ToolCall < ApplicationRecord
  acts_as_tool_call

  def execute
    # Логика выполнения инструмента
  end
end
```

### Models Database Integration
```ruby
# Модель для хранения информации о моделях
class Model < ApplicationRecord
  # Поля: model_id, name, provider, family, context_window,
  # max_output_tokens, modalities, capabilities, pricing, metadata

  def self.save_to_database
    RubyLLM.models.each do |model|
      create!(
        model_id: model.id,
        name: model.name,
        provider: model.provider,
        family: model.family,
        context_window: model.context_window,
        max_output_tokens: model.max_output_tokens,
        modalities: model.modalities,
        capabilities: model.capabilities,
        pricing: model.pricing,
        metadata: model.metadata
      )
    end
  end
end
```

## Usage Examples

### Basic Chat Example
```ruby
# Простой чат
chat = RubyLLM.chat.new(model: 'gpt-3.5-turbo')

chat.say "Привет! Как тебя зовут?"
response = chat.say "Расскажи мне о себе"

puts response.content
```

### Chat with System Prompt
```ruby
chat = RubyLLM.chat.new(
  model: 'claude-sonnet-4',
  system: "Ты - полезный ассистент, который говорит на русском языке."
)

response = chat.say "Помоги мне написать email начальнику"
puts response.content
```

### Streaming Responses
```ruby
chat = RubyLLM.chat.new(model: 'gpt-4')

chat.say "Напиши краткую историю о роботе", stream: true do |chunk|
  print chunk.content
end
```

### Image Generation
```ruby
# Генерация изображений
image_response = RubyLLM.paint(
  "Красивый закат над горами в стиле импрессионизма",
  model: 'dall-e-3'
)

puts image_response.url
```

### Embeddings
```ruby
# Создание эмбеддингов
embedding = RubyLLM.embed(
  "Пример текста для векторизации",
  model: 'text-embedding-3-large'
)

puts embedding.vector # Array of floats
```

### Tool Usage Example
```ruby
# Определение инструментов
tools = [
  {
    name: 'search_database',
    description: 'Поиск в базе данных',
    parameters: {
      type: 'object',
      properties: {
        query: { type: 'string', description: 'Поисковый запрос' }
      },
      required: ['query']
    }
  }
]

# Чат с инструментами
chat = RubyLLM.chat.new(model: 'gpt-4', tools: tools)

response = chat.say "Найди информацию о клиентах из Москвы"

if response.tool_calls.any?
  response.tool_calls.each do |tool_call|
    # Обработка вызовов инструментов
    result = execute_tool(tool_call)
    chat.say tool_result: result
  end
end
```

## Configuration Management

### Environment-based Configuration
```ruby
# Использование с anyway_config для управления конфигурацией
class ApplicationConfig
  config_name :application

  attr_config :llm_model, default: 'gpt-3.5-turbo'
  attr_config :request_timeout, default: 120
  attr_config :max_retries, default: 1

  # Валидация обязательных параметров
  required :llm_model
end

# В инициализаторе
RubyLLM.configure do |config|
  config.default_model = ApplicationConfig.llm_model
  config.request_timeout = ApplicationConfig.request_timeout
  config.max_retries = ApplicationConfig.max_retries
end
```

### Model Selection Strategy
```ruby
class ModelSelector
  def self.for_task(task_type)
    case task_type
    when :code_generation
      'claude-sonnet-4'  # Лучше для кода
    when :creative_writing
      'gpt-4'           # Хорош для творчества
    when :quick_responses
      'gpt-3.5-turbo'   # Быстрый и дешевый
    when :multimodal
      'gpt-4-vision'    # Поддерживает изображения
    else
      ApplicationConfig.llm_model
    end
  end
end
```

## Error Handling

### Common Error Types
```ruby
begin
  response = RubyLLM.chat.new.say "Привет!"
rescue RubyLLM::AuthenticationError => e
  puts "Ошибка аутентификации: #{e.message}"
rescue RubyLLM::RateLimitError => e
  puts "Превышен лимит запросов: #{e.message}"
  sleep(e.retry_after)
  retry
rescue RubyLLM::InvalidRequestError => e
  puts "Некорректный запрос: #{e.message}"
rescue RubyLLM::APIError => e
  puts "Ошибка API: #{e.message}"
rescue => e
  puts "Неизвестная ошибка: #{e.message}"
end
```

### Retry Logic
```ruby
class SafeLLMClient
  MAX_RETRIES = 3
  RETRY_DELAY = 1

  def self.chat_with_retry(message, model: nil)
    retries = 0

    begin
      chat = RubyLLM.chat.new(model: model)
      chat.say(message)
    rescue RubyLLM::RateLimitError, RubyLLM::APIError => e
      if retries < MAX_RETRIES
        retries += 1
        sleep(RETRY_DELAY * retries)
        retry
      else
        raise e
      end
    end
  end
end
```

## Performance Optimization

### Caching Responses
```ruby
class CachedLLM
  def self.initialize
    @cache = Rails.cache
  end

  def self.chat(message, model: nil)
    cache_key = "llm_response_#{Digest::MD5.hexdigest(message + model.to_s)}"

    @cache.fetch(cache_key, expires_in: 1.hour) do
      chat = RubyLLM.chat.new(model: model)
      response = chat.say(message)
      response.content
    end
  end
end
```

### Batch Processing
```ruby
# Обработка нескольких запросов пачкой
def process_batch(messages)
  results = []

  messages.each_slice(5) do |batch|  # Ограничиваем размер пачки
    batch.each do |message|
      results << RubyLLM.chat.new.say(message)
      sleep(0.1)  # Небольшая задержка между запросами
    end
  end

  results
end
```

## Testing

### RSpec Testing
```ruby
RSpec.describe ChatService do
  let(:chat) { instance_double(RubyLLM::Chat) }

  before do
    allow(RubyLLM::Chat).to receive(:new).and_return(chat)
    allow(chat).to receive(:say).and_return(double(content: "Test response"))
  end

  it "handles chat messages" do
    service = ChatService.new
    response = service.process_message("Hello")

    expect(response).to eq("Test response")
    expect(chat).to have_received(:say).with("Hello")
  end
end

# Интеграционные тесты
RSpec.describe "LLM Integration" do
  it "generates responses" do
    chat = RubyLLM.chat.new(model: 'gpt-3.5-turbo')
    response = chat.say("Say 'Hello World'")

    expect(response.content).to include("Hello")
  end
end
```

## Security Considerations

1. **API Keys**: Храните API ключи в переменных окружения
2. **Input Validation**: Всегда валидируйте входящие данные
3. **Rate Limiting**: Implement rate limiting для предотвращения злоупотреблений
4. **Content Filtering**: Фильтруйте небезопасный контент
5. **Data Privacy**: Учитывайте приватность данных при работе с LLM

## Best Practices

1. **Choose Right Model**: Выбирайте модели под конкретные задачи
2. **System Prompts**: Используйте четкие system prompts для определения поведения
3. **Context Management**: Управляйте размером контекста для оптимизации
4. **Error Handling**: Implement robust error handling
5. **Monitoring**: Отслеживайте использование и стоимость API
6. **Testing**: Тестируйте интеграции thoroughly
7. **Cost Management**: Мониторьте и оптимизируйте расходы на API