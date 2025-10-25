# Ruby LLM Gem Documentation

## Overview
`ruby_llm` - это Ruby gem для работы с различными языковыми моделями (LLM) через единый интерфейс. Поддерживает OpenAI, Anthropic, Google Gemini, и другие провайдеры.


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

