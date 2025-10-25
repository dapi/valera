# Ruby LLM Gem - Comprehensive Documentation для Valera Bot

## 📋 Обзор

Ruby LLM - это Ruby gem для интеграции с Large Language Models (OpenAI, Anthropic, Gemini, DeepSeek, Mistral). Gem предоставляет удобный Ruby API для работы с различными LLM провайдерами и идеально подходит для создания AI-ассистентов.

**Основные возможности:**
- ✅ Единоразовый доступ к разным LLM провайдерам
- ✅ Активная запись интеграция с Rails (acts_as macros)
- ✅ Tool/Function calling для расширения функциональности
- ✅ Streaming ответы для real-time взаимодействия
- ✅ Embeddings и семантический поиск
- ✅ Генерация изображений (DALL-E 3)
- ✅ Продвинутая обработка ошибок и retry логика
- ✅ Кэширование и оптимизация производительности

**Для Valera Bot:** gem используется для создания AI-ассистента по автомобильному ремонту с русскоязычным интерфейсом.

## 🚀 Быстрый старт

### Базовая установка и конфигурация
```ruby
# Gemfile
gem 'ruby_llm', '~> 1.8'

# config/initializers/ruby_llm.rb
RubyLLM.configure do |config|
  # OpenAI
  config.openai_api_key = ENV['OPENAI_API_KEY']
  config.openai_organization = ENV['OPENAI_ORGANIZATION']

  # Anthropic (Claude)
  config.anthropic_api_key = ENV['ANTHROPIC_API_KEY']

  # Google Gemini
  config.gemini_api_key = ENV['GEMINI_API_KEY']

  # DeepSeek
  config.deepseek_api_key = ENV['DEEPSEEK_API_KEY']

  # Модель по умолчанию для Valera Bot
  config.model = 'gpt-4o-mini'  # Оптимально по цене/качеству

  # Общие параметры
  config.temperature = 0.7      # Креативность ответов
  config.max_tokens = 2000      # Максимальная длина ответа
  config.timeout = 30           # Таймаут запросов
end
```

### Простое использование
```ruby
# Базовый чат
chat = RubyLLM.chat
response = chat.say('Привет! Расскажи о ремонте Toyota Camry')
puts response.content

# Системный промпт для контекста автомобильного сервиса
system_prompt = <<~PROMPT
  Ты - эксперт по автомобильному ремонту с 20-летним опытом.
  Твоя специализация - диагностике и ремонт легковых автомобилей.
  Отвечай на русском языке профессионально, но доступно.
PROMPT

chat = RubyLLM.chat.new(
  model: 'gpt-4o-mini',
  messages: [
    { role: 'system', content: system_prompt }
  ]
)

response = chat.say('У меня стучит двигатель при разгоне. Что это может быть?')
```


## 🏗️ Архитектура и основные концепции

### 1. Провайдеры и модели

**Поддерживаемые провайдеры:**
- **OpenAI**: GPT-4, GPT-4o, GPT-4o-mini, GPT-3.5-turbo
- **Anthropic**: Claude-3.5-sonnet, Claude-3-opus, Claude-3-haiku
- **Google Gemini**: Gemini-1.5-pro, Gemini-1.5-flash
- **DeepSeek**: DeepSeek-V3, DeepSeek-Coder
- **Mistral AI**: Mistral-7B, Mixtral-8x7B

```ruby
# Получение информации о моделях
models = RubyLLM.models
# => [#<RubyLLM::Model:0x0000... @id="gpt-4", @provider=:openai, ...>, ...]

# Фильтрация моделей
openai_models = RubyLLM.models.select(provider: :openai)
vision_models = RubyLLM.models.select(capabilities: :vision)
cheap_models = RubyLLM.models.select(max_input_price: 0.001)

# Информация о конкретной модели
model = RubyLLM.models.find('gpt-4o-mini')
puts "Контекстное окно: #{model.context_window}"
puts "Максимальных токенов: #{model.max_output_tokens}"
puts "Цена за 1M токенов: $#{model.pricing[:input]}"
```

### 2. Чаты (Chats) - управление диалогами

```ruby
# Создание нового чата с параметрами
chat = RubyLLM.chat.new(
  model: 'gpt-4o-mini',
  temperature: 0.7,
  max_tokens: 1500
)

# Добавление системного сообщения (обязательно для Valera Bot)
chat.add_system_message(<<~PROMPT)
  Ты - Valera, AI-ассистент по автомобильному ремонту.
  Опыт: 20 лет работы в автосервисе.
  Стиль: профессиональный, но доступный.
  Язык: русский.
PROMPT

# Добавление сообщений пользователя
response1 = chat.say("Привет! У меня проблема с машиной.")
response2 = chat.say("При торможении слышен скрип с передней оси.")

# Получение полной истории чата
chat.messages.each do |msg|
  puts "#{msg.role}: #{msg.content}"
end

# Контекст в формате для API
context_messages = chat.context_messages
# => [
#   { role: 'system', content: '...' },
#   { role: 'user', content: 'Привет! У меня проблема с машиной.' },
#   { role: 'assistant', content: 'Здравствуйте! Расскажите подробнее...' },
#   { role: 'user', content: 'При торможении слышен скрип...' }
# ]
```

### 3. Сообщения (Messages) - детальная работа

```ruby
# Создание сообщений вручную
system_msg = RubyLLM.message.new(
  role: :system,
  content: 'Ты - эксперт по автомобилям',
  metadata: { version: '1.0', source: 'valera_bot' }
)

user_msg = RubyLLM.message.new(
  role: :user,
  content: 'Помоги с диагностикой',
  metadata: { user_id: 123, telegram_id: '@user_telegram' }
)

# Мультимодальные сообщения (изображения + текст)
photo_msg = RubyLLM.message.new(
  role: :user,
  content: 'Посмотри на эту неисправность и скажи, что сломалось',
  images: ['/path/to/brake_problem.jpg'],
  metadata: { has_photo: true }
)

# Атрибуты сообщения
msg = RubyLLM.message.new(role: :user, content: 'Test')
puts msg.id          # Уникальный ID сообщения
puts msg.role        # :user, :assistant, :system, :tool
puts msg.content     # Текст сообщения
puts msg.metadata    # Дополнительные данные
puts msg.images      # Массив путей к изображениям
puts msg.created_at  # Время создания
```

### 4. Tool/Function Calls - расширение возможностей

```ruby
# Определение инструментов для автомобильной диагностики
diagnostic_tool = {
  name: 'diagnose_car_problem',
  description: 'Диагностирует проблему автомобиля по симптомам',
  input_schema: {
    type: 'object',
    properties: {
      car_make: {
        type: 'string',
        description: 'Марка автомобиля (Toyota, BMW, etc.)'
      },
      symptoms: {
        type: 'array',
        items: { type: 'string' },
        description: 'Список наблюдаемых симптомов'
      },
      driving_conditions: {
        type: 'string',
        enum: ['city', 'highway', 'mixed'],
        description: 'Условия эксплуатации'
      }
    },
    required: ['car_make', 'symptoms']
  }
}

cost_calculator_tool = {
  name: 'estimate_repair_cost',
  description: 'Расчет примерной стоимости ремонта',
  input_schema: {
    type: 'object',
    properties: {
      repair_type: {
        type: 'string',
        description: 'Тип ремонта (тормоза, подвеска, двигатель и т.д.)'
      },
      car_make: { type: 'string', description: 'Марка автомобиля' },
      urgency: {
        type: 'string',
        enum: ['low', 'medium', 'high'],
        description: 'Срочность ремонта'
      }
    },
    required: ['repair_type', 'car_make']
  }
}

# Использование инструментов в чате
chat = RubyLLM.chat.new(
  model: 'gpt-4o-mini',
  tools: [diagnostic_tool, cost_calculator_tool],
  system_message: 'Ты - автомобильный эксперт с доступом к инструментам диагностики'
)

response = chat.say("У Toyota Corolla при торможении скрипит колесо. Сколько будет стоить ремонт?")

# Проверка, вызвал ли LLM инструменты
if response.tool_calls.any?
  puts "LLM вызывает инструменты:"
  response.tool_calls.each do |tool_call|
    puts "- #{tool_call.name}: #{tool_call.arguments}"

    # Выполнение инструмента
    result = execute_tool(tool_call.name, tool_call.arguments)

    # Добавление результата в чат
    chat.add_tool_result(tool_call.id, result)
  end

  # Получение финального ответа
  final_response = chat.say("Проанализируй результаты и дай рекомендации")
  puts final_response.content
end
```

## 🎯 Rails интеграция для Valera Bot

### Acts_as_chat - управление чатами в БД

```ruby
# app/models/chat.rb
class Chat < ApplicationRecord
  include RubyLLM::Models::Chat

  acts_as_chat do
    # Ассоциации
    has_many :messages, -> { order(:created_at) }, dependent: :destroy
    has_many :tool_calls, through: :messages

    # Валидации
    validates :title, presence: true
    validates :telegram_chat_id, uniqueness: true

    # Скопы для удобной работы
    scope :active, -> { where('updated_at > ?', 1.day.ago) }
    scope :by_model, ->(model) { where(model: model) }

    # Callbacks
    after_create :set_default_title
    before_save :normalize_model_name

    private

    def set_default_title
      self.title ||= "Диалог от #{created_at.strftime('%d.%m.%Y %H:%M')}"
    end

    def normalize_model_name
      self.model = model&.downcase&.strip
    end
  end

  # Персональные методы для Valera Bot
  def context_for_user
    messages.last(20).map do |msg|
      {
        role: msg.role,
        content: msg.content,
        metadata: msg.metadata
      }
    end
  end

  def last_user_message
    messages.where(role: 'user').last
  end

  def conversation_summary
    "#{messages.count} сообщений от #{created_at.strftime('%d.%m.%Y')}"
  end

  def reset_context!
    messages.where.not(role: 'system').delete_all
    touch
  end
end
```

### Acts_as_message - работа с сообщениями

```ruby
# app/models/message.rb
class Message < ApplicationRecord
  include RubyLLM::Models::Message

  acts_as_message do
    belongs_to :chat
    has_many_attached :attachments
    has_many :tool_calls, dependent: :destroy

    # Валидации
    validates :content, presence: true, unless: -> { has_attachments? }
    validates :role, inclusion: { in: %w[user system assistant tool] }

    # Скопы
    scope :user_messages, -> { where(role: 'user') }
    scope :assistant_messages, -> { where(role: 'assistant') }
    scope :with_errors, -> { where("metadata->>'error' IS NOT NULL") }
    scope :today, -> { where('created_at >= ?', Date.current) }

    # Callbacks
    after_create :update_chat_timestamp
    after_create :calculate_tokens_if_needed

    private

    def update_chat_timestamp
      chat.touch(:last_message_at)
    end

    def calculate_tokens_if_needed
      return if role == 'system' || content.blank?

      # Асинхронный подсчет токенов
      CalculateTokensJob.perform_later(id)
    end
  end

  # Персональные методы для Valera Bot
  def has_attachments?
    attachments.attached?
  end

  def contains_photo?
    has_attachments? && attachments.any? { |att| att.content_type.start_with?('image/') }
  end

  def formatted_content_for_telegram
    # Форматирование для Telegram (Markdown, escaping и т.д.)
    TelegramFormatter.format(content)
  end

  def extract_car_info
    # Извлечение информации об автомобиле из текста
    CarInfoExtractor.extract(content)
  end

  def metadata_for_analysis
    metadata.merge({
      message_length: content.length,
      has_photo: contains_photo?,
      telegram_message_id: metadata['telegram_message_id'],
      created_at_russia: created_at.in_time_zone('Moscow')
    })
  end

  def has_attachments?
    attachments.attached?
  end
end
```

### Acts_as_tool_call - отслеживание вызовов инструментов

```ruby
# app/models/tool_call.rb
class ToolCall < ApplicationRecord
  include RubyLLM::Models::ToolCall

  acts_as_tool_call do
    belongs_to :message

    # Валидации
    validates :name, presence: true
    validates :arguments, presence: true

    # Скопы
    scope :successful, -> { where(status: 'completed') }
    scope :failed, -> { where(status: 'failed') }
    scope :processing, -> { where(status: 'processing') }
    scope :by_tool, ->(tool_name) { where(name: tool_name) }

    # Callbacks
    before_create :set_processing_status
    after_update :notify_if_completed

    private

    def set_processing_status
      self.status ||= 'processing'
      self.started_at ||= Time.current
    end

    def notify_if_completed
      return unless saved_change_to_status(to: 'completed')

      self.completed_at = Time.current
      ToolCallCompletedNotificationJob.perform_later(id)
    end
  end

  # Персональные методы
  def duration
    return nil unless started_at && completed_at
    completed_at - started_at
  end

  def successful?
    status == 'completed'
  end

  def failed?
    status == 'failed'
  end

  def execute!
    update!(status: 'processing', started_at: Time.current)

    result = case name
             when 'diagnose_car_problem'
               CarDiagnosticService.diagnose(arguments)
             when 'estimate_repair_cost'
               CostEstimationService.estimate(arguments)
             when 'find_service_centers'
               ServiceCenterFinder.find(arguments)
             else
               { error: "Unknown tool: #{name}" }
             end

    update!(
      status: result[:error] ? 'failed' : 'completed',
      result: result,
      completed_at: Time.current
    )
  rescue => e
    update!(
      status: 'failed',
      result: { error: e.message, backtrace: e.backtrace.first(3) },
      completed_at: Time.current
    )
  end

  def parsed_arguments
    JSON.parse(arguments) rescue {}
  end
end
```

### Миграции базы данных

```ruby
# db/migrate/001_create_chats.rb
class CreateChats < ActiveRecord::Migration[7.0]
  def change
    create_table :chats do |t|
      t.string :title
      t.string :telegram_chat_id, index: { unique: true }
      t.string :telegram_user_id
      t.string :model, default: 'gpt-4o-mini'
      t.decimal :temperature, precision: 3, scale: 2, default: 0.7
      t.integer :max_tokens, default: 2000
      t.json :metadata, default: {}
      t.datetime :last_message_at

      t.timestamps
    end

    add_index :chats, :telegram_chat_id, unique: true
    add_index :chats, :last_message_at
    add_index :chats, :model
  end
end

# db/migrate/002_create_messages.rb
class CreateMessages < ActiveRecord::Migration[7.0]
  def change
    create_table :messages do |t|
      t.references :chat, null: false, foreign_key: true, index: true
      t.string :role, null: false, index: true
      t.text :content
      t.json :metadata, default: {}
      t.string :model
      t.integer :tokens_used
      t.decimal :response_time, precision: 8, scale: 3
      t.string :telegram_message_id
      t.datetime :processed_at

      t.timestamps
    end

    add_index :messages, [:chat_id, :created_at]
    add_index :messages, :role
    add_index :messages, :telegram_message_id
  end
end

# db/migrate/003_create_tool_calls.rb
class CreateToolCalls < ActiveRecord::Migration[7.0]
  def change
    create_table :tool_calls do |t|
      t.references :message, null: false, foreign_key: true, index: true
      t.string :name, null: false, index: true
      t.json :arguments, null: false
      t.json :result
      t.string :status, default: 'processing', index: true
      t.datetime :started_at
      t.datetime :completed_at
      t.text :error_message

      t.timestamps
    end

    add_index :tool_calls, [:message_id, :name]
    add_index :tool_calls, :status
    add_index :tool_calls, :name
  end
end

# db/migrate/004_add_embeddings_to_messages.rb
class AddEmbeddingsToMessages < ActiveRecord::Migration[7.0]
  def change
    add_column :messages, :embedding, :vector, limit: 1536 # For text-embedding-3-small
    add_index :messages, :embedding, using: :cosine
  end
end
```

### Модель для хранения информации о LLM моделях

```ruby
# app/models/llm_model.rb
class LLMModel < ApplicationRecord
  validates :model_id, presence: true, uniqueness: true
  validates :name, presence: true
  validates :provider, presence: true
  validates :context_window, numericality: { greater_than: 0 }
  validates :max_output_tokens, numericality: { greater_than: 0 }

  # Скопы для удобного выбора
  scope :openai, -> { where(provider: 'openai') }
  scope :anthropic, -> { where(provider: 'anthropic') }
  scope :vision_capable, -> { where("capabilities @> ?", ['vision'].to_json) }
  scope :cheap, -> { where('input_price < ?', 0.002) }
  scope :fast, -> { where('max_output_tokens > ?', 1000) }

  # Методы для работы с моделями
  def self.refresh_from_api!
    RubyLLM.models.each do |model|
      find_or_initialize_by(model_id: model.id).tap do |db_model|
        db_model.update!(
          name: model.name,
          provider: model.provider.to_s,
          family: model.family,
          context_window: model.context_window,
          max_output_tokens: model.max_output_tokens,
          modalities: model.modalities,
          capabilities: model.capabilities,
          input_price: model.pricing[:input],
          output_price: model.pricing[:output],
          metadata: model.metadata
        )
      end
    end
  end

  def supports_vision?
    capabilities.include?('vision')
  end

  def supports_tools?
    capabilities.include?('tools')
  end

  def cost_per_1k_tokens(input: true)
    price = input ? input_price : output_price
    (price * 1000).round(6)
  end

  def estimate_cost(input_tokens:, output_tokens:)
    (input_tokens * input_price + output_tokens * output_price).round(8)
  end

  def recommended_for_valera?
    # Оптимальные модели для Valera Bot
    %w[gpt-4o-mini gpt-4o claude-3-haiku].include?(model_id)
  end
end
```


## 🛠️ Продвинутые возможности для Valera Bot

### 1. Streaming ответы для real-time взаимодействия

```ruby
# app/services/valera_streaming_service.rb
class ValeraStreamingService
  def self.stream_consultation(chat, user_message, telegram_client)
    # Создаем сообщение для ответа
    assistant_message = chat.messages.create!(
      role: 'assistant',
      content: '',
      model: chat.model || 'gpt-4o-mini',
      metadata: { streaming: true, started_at: Time.current }
    )

    # Отправляем "печатает..." уведомление
    telegram_client.send_chat_action(chat_id: chat.telegram_chat_id, action: 'typing')

    # Streaming запрос к LLM
    RubyLLM.chat(
      model: chat.model || 'gpt-4o-mini',
      messages: chat.context_messages + [
        { role: 'user', content: user_message.content }
      ],
      stream: proc do |chunk|
        content_delta = extract_content(chunk)
        next if content_delta.blank?

        # Обновляем сообщение в базе данных
        assistant_message.content += content_delta
        assistant_message.save!

        # Отправляем chunk пользователю (если реализовано)
        if chunk_should_be_sent?(content_delta)
          telegram_client.send_message(
            chat_id: chat.telegram_chat_id,
            text: format_streaming_chunk(content_delta),
            parse_mode: 'Markdown'
          )
        end
      end
    )

    # Финализируем сообщение
    assistant_message.metadata[:completed_at] = Time.current
    assistant_message.save!

    assistant_message
  end

  private

  def self.extract_content(chunk)
    # Извлечение контента из ответа API
    chunk.dig('choices', 0, 'delta', 'content')
  end

  def self.chunk_should_be_sent?(content)
    # Отправляем только смысловые части
    content.match?(/[\.\!\?\,\;\:]\s*$/)
  end

  def self.format_streaming_chunk(chunk)
    chunk.strip
  end
end
```

### 2. Embeddings и семантический поиск

```ruby
# app/services/embedding_service.rb
class EmbeddingService
  def self.create_for_message(message)
    return if message.role == 'tool' || message.content.blank?

    embedding_vector = RubyLLM.client.create_embedding(
      model: 'text-embedding-3-small',
      input: message.content
    ).dig('data', 0, 'embedding')

    message.update!(embedding: embedding_vector)
  rescue => e
    Rails.logger.error "Failed to create embedding for message #{message.id}: #{e.message}"
  end

  def self.find_similar_car_problems(query, limit: 5)
    query_embedding = RubyLLM.client.create_embedding(
      model: 'text-embedding-3-small',
      input: query
    ).dig('data', 0, 'embedding')

    # Поиск похожих сообщений с проблемами
    Message.joins(:chat)
           .where(role: 'user')
           .where("content ILIKE ? OR content ILIKE ? OR content ILIKE ?",
                  '%проблем%', '%неисправн%', '%сломал%')
           .where.not(embedding: nil)
           .select("*, embedding <=> ? as distance", query_embedding)
           .order("distance ASC")
           .limit(limit)
  end

  def self.search_repair_cases(symptoms, car_make: nil)
    query = symptoms.join(' ')
    if car_make.present?
      query += " #{car_make}"
    end

    query_embedding = RubyLLM.client.create_embedding(
      model: 'text-embedding-3-small',
      input: query
    ).dig('data', 0, 'embedding')

    # Поиск релевантных кейсов ремонта
    Message.joins(:chat)
           .where(role: 'assistant')
           .where("content ILIKE ANY(ARRAY[?])",
                  ['%ремонт%', '%замена%', '%диагностик%'])
           .where.not(embedding: nil)
           .select("*, embedding <=> ? as distance", query_embedding)
           .order("distance ASC")
           .limit(10)
  end
end
```

### 3. Работа с изображениями (Vision API)

```ruby
# app/services/vision_analysis_service.rb
class VisionAnalysisService
  def self.analyze_car_photo(image_path, user_question)
    # Конвертируем изображение в base64
    image_data = File.read(image_path)
    base64_image = Base64.strict_encode64(image_data)

    # Определяем MIME тип
    mime_type = MIME::Types.type_for(image_path).first.content_type

    # Создаем сообщение с изображением
    response = RubyLLM.chat(
      model: 'gpt-4o', # Модель с поддержкой vision
      messages: [
        {
          role: 'system',
          content: 'Ты - эксперт по автомобильному ремонту с 20-летним опытом. Проанализируй фото и дай профессиональную консультацию на русском языке.'
        },
        {
          role: 'user',
          content: [
            {
              type: 'text',
              text: "#{user_question}\n\nОпиши детально, что ты видишь на фото, какие это неисправности и как их можно устранить."
            },
            {
              type: 'image_url',
              image_url: {
                url: "data:#{mime_type};base64,#{base64_image}"
              }
            }
          ]
        }
      ],
      max_tokens: 1000
    )

    response.content
  end

  def self.extract_damage_info(photo_path)
    prompt = <<~PROMPT
      Проанализируй это фото автомобиля и определи:

      1. Какие повреждения видны?
      2. Степень тяжести (незначительные/средние/тяжелые)
      3. Какие детали требуют замены?
      4. Примерная стоимость ремонта в рублях
      5. Срочно ли это нужно ремонтировать?

      Ответь в формате JSON:
      {
        "damages": ["список повреждений"],
        "severity": "low|medium|high",
        "parts_to_replace": ["детали для замены"],
        "estimated_cost_rub": число,
        "urgency": "low|medium|high",
        "recommendations": ["рекомендации по ремонту"]
      }
    PROMPT

    analysis = analyze_car_photo(photo_path, prompt)

    # Пытаемся распарсить JSON
    JSON.parse(analysis) rescue format_text_response(analysis)
  end

  private

  def self.format_text_response(text)
    # Форматируем текстовый ответ в JSON
    {
      "damages" => extract_list(text, "повреждения"),
      "severity" => extract_severity(text),
      "parts_to_replace" => extract_list(text, "замен"),
      "estimated_cost_rub" => extract_cost(text),
      "urgency" => extract_urgency(text),
      "recommendations" => extract_list(text, "рекомендация")
    }
  end
end
```

### 4. Продвинутая обработка ошибок

```ruby
# app/services/reliable_llm_service.rb
class ReliableLlmService
  MAX_RETRIES = 3
  BASE_DELAY = 1
  MAX_DELAY = 30

  def self.chat_with_fallbacks(chat, user_message)
    with_comprehensive_retry do
      response = attempt_primary_model(chat, user_message)
      return response if response.success?

      # Fallback на более дешевую модель
      response = attempt_fallback_model(chat, user_message)
      return response if response.success?

      # Последняя попытка с упрощенным контекстом
      attempt_with_simplified_context(chat, user_message)
    end
  rescue => e
    handle_final_error(e, chat, user_message)
  end

  private

  def self.with_comprehensive_retry
    attempts = 0

    begin
      attempts += 1
      result = yield

      # Сбрасываем счетчик при успехе
      attempts = 0
      result

    rescue => error
      if attempts < MAX_RETRIES
        # Exponential backoff с jitter
        delay = calculate_delay(attempts)
        Rails.logger.warn "LLM retry #{attempts}/#{MAX_RETRIES} after #{delay}s: #{error.message}"

        sleep(delay)
        retry
      else
        Rails.logger.error "All LLM retry attempts failed: #{error.message}"
        raise error
      end
    end
  end

  def self.calculate_delay(attempt)
    base_delay = BASE_DELAY * (2 ** (attempt - 1))
    jitter = rand(0.1..0.3) * base_delay
    [base_delay + jitter, MAX_DELAY].min
  end

  def self.attempt_primary_model(chat, user_message)
    try_with_model(chat, user_message, chat.model || 'gpt-4o-mini')
  end

  def self.attempt_fallback_model(chat, user_message)
    fallback_models = ['gpt-3.5-turbo', 'claude-3-haiku']
    fallback_models.each do |model|
      response = try_with_model(chat, user_message, model)
      return response if response.success?
    end
    nil
  end

  def self.attempt_with_simplified_context(chat, user_message)
    simplified_context = [
      chat.context_messages.first, # System message
      chat.context_messages.last(3) # Последние 3 сообщения
    ].flatten

    RubyLLM.chat(
      model: 'gpt-3.5-turbo',
      messages: simplified_context + [
        { role: 'user', content: user_message.content }
      ]
    )
  end

  def self.try_with_model(chat, user_message, model)
    RubyLLM.chat(
      model: model,
      messages: chat.context_messages + [
        { role: 'user', content: user_message.content }
      ]
    )
  rescue => e
    Rails.logger.warn "Failed to get response from #{model}: #{e.message}"
    OpenStruct.new(success?: false, error: e.message)
  end

  def self.handle_final_error(error, chat, user_message)
    Rails.logger.error "LLM service final error: #{error.message}"

    # Сохраняем ошибку в базе данных
    chat.messages.create!(
      role: 'assistant',
      content: 'Извините, произошла техническая ошибка. Пожалуйста, попробуйте еще раз через несколько минут.',
      metadata: {
        error: error.message,
        error_type: error.class.name,
        failed_at: Time.current
      }
    )

    # Отправляем уведомление администратору
    AdminNotifier.llm_error(error, chat, user_message)

    OpenStruct.new(
      success?: false,
      error: error.message,
      fallback_message: 'Произошла ошибка. Попробуйте позже.'
    )
  end
end
```

### 5. Tool/Function Calling для автомобильной диагностики

```ruby
# app/services/valera_tools_service.rb
class ValeraToolsService
  # Инструмент для диагностики проблем
  def self.diagnose_car_problem(arguments)
    car_make = arguments['car_make']
    symptoms = arguments['symptoms']
    additional_info = arguments['additional_info']

    # База знаний симптомов и возможных причин
    diagnostic_db = load_diagnostic_database

    matches = []
    symptoms.each do |symptom|
      symptom_key = symptom.downcase.gsub(/\s+/, '_')
      if diagnostic_db[symptom_key]
        matches.concat(diagnostic_db[symptom_key])
      end
    end

    # Устраняем дубликаты и сортируем по релевантности
    unique_matches = matches.uniq.sort_by { |m| -m[:probability] }

    {
      success: true,
      diagnosis: unique_matches.first(3),
      confidence: calculate_confidence(unique_matches, symptoms),
      recommendations: generate_recommendations(unique_matches, car_make),
      estimated_costs: estimate_costs_by_symptoms(unique_matches, car_make)
    }
  end

  # Инструмент для расчета стоимости ремонта
  def self.estimate_repair_cost(arguments)
    repair_type = arguments['repair_type']
    car_make = arguments['car_make']
    car_model = arguments['car_model']
    urgency = arguments['urgency'] || 'medium'
    region = arguments['region'] || 'moscow'

    # База цен на ремонт
    price_db = load_price_database

    base_price = price_db.dig(repair_type.downcase, 'base_price') || 15000
    make_multiplier = price_db.dig('car_multipliers', car_make.downcase) || 1.0
    urgency_multiplier = { 'low' => 0.8, 'medium' => 1.0, 'high' => 1.3 }[urgency] || 1.0
    region_multiplier = { 'moscow' => 1.2, 'spb' => 1.1, 'other' => 1.0 }[region] || 1.0

    estimated_cost = (base_price * make_multiplier * urgency_multiplier * region_multiplier).round

    {
      success: true,
      repair_type: repair_type,
      car_make: car_make,
      car_model: car_model,
      urgency: urgency,
      region: region,
      estimated_cost: estimated_cost,
      currency: 'RUB',
      price_range: {
        min: (estimated_cost * 0.8).round,
        max: (estimated_cost * 1.3).round
      },
      time_required: estimate_repair_time(repair_type),
      confidence: 'high'
    }
  end

  # Инструмент для поиска автосервисов
  def self.find_service_centers(arguments)
    repair_type = arguments['repair_type']
    location = arguments['location'] || 'Москва'
    radius = arguments['radius'] || 10

    # Имитация поиска по базе автосервисов
    service_centers = [
      {
        name: 'Автосервис "Мастер-Авто"',
        address: "#{location}, ул. Промышленная, 15",
        phone: '+7 (495) 123-45-67',
        rating: 4.8,
        specialties: ['двигатель', 'тормоза', 'подвеска'],
        distance_km: rand(1.0..radius).round(1),
        estimated_wait_time: "#{rand(1..3)} дня",
        price_level: 'medium'
      },
      {
        name: 'Техцентр "Авто-Плюс"',
        address: "#{location}, пр. Ленина, 42",
        phone: '+7 (495) 987-65-43',
        rating: 4.6,
        specialties: ['трансмиссия', 'электрика', 'диагностика'],
        distance_km: rand(1.0..radius).round(1),
        estimated_wait_time: "#{rand(1..2)} дня",
        price_level: 'low'
      }
    ]

    # Фильтрация по специализации
    filtered_centers = service_centers.select do |center|
      center[:specialties].any? { |spec| spec.include?(repair_type) }
    end

    {
      success: true,
      repair_type: repair_type,
      location: location,
      service_centers: filtered_centers.sort_by { |c| c[:distance_km] },
      total_found: filtered_centers.length,
      search_radius: radius
    }
  end

  private

  def self.load_diagnostic_database
    {
      'стук_при_торможении' => [
        { problem: 'Износ тормозных колодок', probability: 0.7, urgency: 'high' },
        { problem: 'Деформация тормозных дисков', probability: 0.5, urgency: 'medium' },
        { problem: 'Износ ступичных подшипников', probability: 0.3, urgency: 'medium' }
      ],
      'двигатель_не_заводится' => [
        { problem: 'Разряженный аккумулятор', probability: 0.6, urgency: 'low' },
        { problem: 'Проблема со стартером', probability: 0.4, urgency: 'medium' },
        { problem: 'Засорился топливный фильтр', probability: 0.3, urgency: 'medium' }
      ],
      'повышенный_расход_масла' => [
        { problem: 'Износ маслосъемных колпачков', probability: 0.5, urgency: 'low' },
        { problem: 'Прокладка клапанной крышки', probability: 0.4, urgency: 'medium' },
        { problem: 'Износ поршневых колец', probability: 0.2, urgency: 'high' }
      ]
    }
  end

  def self.load_price_database
    {
      'тормоза' => {
        'base_price' => 8000,
        'parts_cost' => 5000,
        'labor_hours' => 2
      },
      'подвеска' => {
        'base_price' => 12000,
        'parts_cost' => 8000,
        'labor_hours' => 3
      },
      'двигатель' => {
        'base_price' => 25000,
        'parts_cost' => 18000,
        'labor_hours' => 6
      },
      'car_multipliers' => {
        'toyota' => 1.0,
        'bmw' => 1.5,
        'mercedes' => 1.6,
        'audi' => 1.4,
        'volkswagen' => 1.1,
        'kia' => 0.9,
        'hyundai' => 0.9
      }
    }
  end

  def self.calculate_confidence(matches, symptoms)
    return 'low' if matches.empty?
    return 'high' if matches.length >= symptoms.length
    'medium'
  end

  def self.generate_recommendations(matches, car_make)
    recommendations = []

    matches.each do |match|
      case match[:problem]
      when 'Износ тормозных колодок'
        recommendations << "Замените тормозные колодки комплектом на обеих колесах"
      when 'Разряженный аккумулятор'
        recommendations << "Зарядите аккумулятор или проверьте его работоспособность"
      when 'Износ маслосъемных колпачков'
        recommendations << "Рекомендуется замена маслосъемных колпачков"
      end
    end

    recommendations.uniq.first(3)
  end

  def self.estimate_costs_by_symptoms(matches, car_make)
    matches.first(3).map do |match|
      {
        problem: match[:problem],
        estimated_cost: estimate_single_repair_cost(match[:problem], car_make),
        urgency: match[:urgency]
      }
    end
  end

  def self.estimate_single_repair_cost(problem, car_make)
    base_costs = {
      'Износ тормозных колодок' => 8000,
      'Разряженный аккумулятор' => 5000,
      'Износ маслосъемных колпачков' => 15000,
      'Прокладка клапанной крышки' => 10000
    }

    make_multiplier = { 'bmw' => 1.5, 'mercedes' => 1.6, 'audi' => 1.4 }[car_make&.downcase] || 1.0

    (base_costs[problem] || 12000) * make_multiplier
  end

  def self.estimate_repair_time(repair_type)
    time_db = {
      'тормоза' => '2-3 часа',
      'подвеска' => '4-6 часов',
      'двигатель' => '1-3 дня',
      'трансмиссия' => '2-4 дня',
      'диагностика' => '1-2 часа'
    }

    time_db[repair_type.downcase] || '2-4 часа'
  end
end
```

## 🚀 Оптимизация производительности для Valera Bot

### 1. Умное кэширование ответов

```ruby
# app/services/valera_cache_service.rb
class ValeraCacheService
  CACHE_VERSION = 'v1'
  DEFAULT_TTL = 2.hours

  def self.get_cached_response(chat, user_message)
    cache_key = generate_cache_key(chat, user_message)

    Rails.cache.fetch(cache_key, expires_in: calculate_ttl(user_message)) do
      response = generate_response(chat, user_message)

      {
        content: response.content,
        model: response.model,
        tokens_used: response.usage&.total_tokens,
        cached_at: Time.current,
        cache_version: CACHE_VERSION
      }
    end
  end

  def self.invalidate_cache(chat_id)
    pattern = "valera_llm:chat_#{chat_id}:*"
    Rails.cache.delete_matched(pattern)
  end

  def self.cache_hit_rate
    total_requests = Rails.cache.read('valera_llm:stats:total_requests') || 0
    cache_hits = Rails.cache.read('valera_llm:stats:cache_hits') || 0

    return 0 if total_requests.zero?
    (cache_hits.to_f / total_requests * 100).round(2)
  end

  private

  def self.generate_cache_key(chat, user_message)
    context_hash = Digest::MD5.hexdigest(
      chat.context_messages.last(5)
          .map { |m| "#{m[:role]}:#{m[:content]}" }
          .join('|')
    )

    message_hash = Digest::MD5.hexdigest(normalize_message(user_message.content))
    model_hash = Digest::MD5.hexdigest(chat.model || 'gpt-4o-mini')

    "valera_llm:chat_#{chat.id}:#{model_hash}:#{context_hash}:#{message_hash}:#{CACHE_VERSION}"
  end

  def self.normalize_message(content)
    content.downcase.gsub(/[^\w\s]/, '').gsub(/\s+/, ' ').strip
  end

  def self.calculate_ttl(user_message)
    if user_message.content.downcase.include?('цена') ||
       user_message.content.downcase.include?('стоимость')
      24.hours
    elsif user_message.content.downcase.include?('срочно')
      30.minutes
    else
      DEFAULT_TTL
    end
  end
end
```

### 2. Оптимизация токенов и контекста

```ruby
# app/services/token_optimizer_service.rb
class TokenOptimizerService
  MAX_CONTEXT_TOKENS = 7000
  SYSTEM_TOKENS = 200

  def self.optimize_context(chat, user_message)
    original_context = chat.context_messages

    if estimate_tokens(original_context + [{ role: 'user', content: user_message.content }]) <= MAX_CONTEXT_TOKENS
      return original_context
    end

    optimized_context = build_optimized_context(original_context, user_message)
    Rails.logger.info "Context optimized: #{original_context.length} -> #{optimized_context.length} messages"
    optimized_context
  end

  def self.estimate_tokens(messages)
    total_chars = messages.sum { |msg| msg[:content].to_s.length }
    (total_chars / 4.0).ceil + SYSTEM_TOKENS
  end

  def self.build_optimized_context(original_context, user_message)
    system_message = original_context.find { |m| m[:role] == 'system' }
    optimized = [system_message].compact

    recent_messages = original_context.reject { |m| m[:role] == 'system' }.last(6)
    optimized.concat(recent_messages)

    while estimate_tokens(optimized + [{ role: 'user', content: user_message.content }]) > MAX_CONTEXT_TOKENS
      break if optimized.length <= 2
      removed = optimized.shift if optimized.first[:role] != 'system'
      break unless removed
    end

    optimized
  end
end
```

## 📊 Тестирование ruby_llm для Valera Bot

### 1. Unit тесты для сервисов

```ruby
# test/services/valera_tools_service_test.rb
class ValeraToolsServiceTest < ActiveSupport::TestCase
  test "should diagnose car problem correctly" do
    arguments = {
      'car_make' => 'Toyota',
      'symptoms' => ['стук при торможении', 'вирация руля'],
      'additional_info' => 'на скорости 60 км/ч'
    }

    result = ValeraToolsService.diagnose_car_problem(arguments)

    assert result[:success]
    assert result[:diagnosis].any?
    assert_includes result[:diagnosis].map { |d| d[:problem] }, 'Износ тормозных колодок'
    assert_equal 'medium', result[:confidence]
  end

  test "should estimate repair cost with multipliers" do
    arguments = {
      'repair_type' => 'тормоза',
      'car_make' => 'BMW',
      'urgency' => 'high',
      'region' => 'moscow'
    }

    result = ValeraToolsService.estimate_repair_cost(arguments)

    assert result[:success]
    assert result[:estimated_cost] > 8000
    assert_equal 'RUB', result[:currency]
  end
end
```

### 2. Mock и Stub тестирование

```ruby
# test/support/llm_test_helpers.rb
module LlmTestHelpers
  def mock_llm_response(content, tool_calls: [])
    response = OpenStruct.new(
      content: content,
      model: 'gpt-4o-mini',
      usage: OpenStruct.new(total_tokens: 150),
      tool_calls: tool_calls
    )

    RubyLLM::Chat.any_instance.stubs(:say).returns(response)
    response
  end

  def create_test_chat(**options)
    Chat.create!(
      title: options[:title] || 'Test Chat',
      telegram_chat_id: options[:telegram_chat_id] || '123456',
      model: options[:model] || 'gpt-4o-mini',
      temperature: options[:temperature] || 0.7,
      **options
    )
  end

  def create_user_message(chat, content)
    chat.messages.create!(
      role: 'user',
      content: content,
      metadata: { source: 'test' }
    )
  end
end

# test/test_helper.rb
class ActiveSupport::TestCase
  include LlmTestHelpers

  setup do
    RubyLLM::Chat.any_instance.stubs(:say).raises(
      StandardError.new("Real API calls disabled in tests")
    )
  end
end
```

## 🎯 Практические примеры использования в Valera Bot

### 1. Консультант по диагностике

```ruby
# app/services/valera_consultant_service.rb
class ValeraConsultantService
  SYSTEM_PROMPT = <<~PROMPT
    Ты - Валера, AI-ассистент по автомобильному ремонту с 20-летним опытом.

    Твои принципы:
    1. Всегда спрашивай уточняющие вопросы, если не хватает информации
    2. Предупрежди о безопасности в первую очередь
    3. Давай конкретные, практические советы
    4. Учитывай российские реалии (качество дорог, климат, доступность запчастей)
    5. Если проблема опасная - сразу скажи об этом

    Стиль общения:
    - Профессиональный, но доступный язык
    - Структурированные ответы (пункты, списки)
    - Конструктивный подход
  PROMPT

  def self.consult(chat, user_input)
    ensure_system_prompt(chat)

    if emergency_situation?(user_input)
      handle_emergency(chat, user_input)
      return
    end

    if has_photo?(user_input)
      handle_photo_request(chat, user_input)
      return
    end

    handle_standard_consultation(chat, user_input)
  end

  private

  def self.emergency_situation?(input)
    emergency_keywords = %w[
      дым дымится пожар горит
      не_тормозит отказали_тормоза
      масло_течет лужа_под_машиной
      двигатель_заглох остановился
      авария дтп
    ]

    emergency_keywords.any? { |keyword| input.downcase.include?(keyword) }
  end

  def self.handle_emergency(chat, user_input)
    emergency_response = <<~RESPONSE
      🚨 **ОПАСНАЯ СИТУАЦИЯ!** Немедленно примите меры безопасности:

      **1. Остановитесь:**
      - Съезжайте на обочину или в безопасное место
      - Включите аварийную сигнализацию
      - Заглушите двигатель

      **2. Проверьте безопасность:**
      - Если есть дым или запах гари - выйдите из машины
      - Установите знак аварийной остановки
      - Отойдите на безопасное расстояние

      **3. Вызовите помощь:**
      - Если есть угроза жизни: 112 или 103
      - Эвакуатор: поищите местный номер в интернете
      - Не пытайтесь ехать дальше!

      Опишите подробнее, что произошло, я помогу оценить серьезность.
    RESPONSE

    chat.messages.create!(role: 'assistant', content: emergency_response)
  end

  def self.handle_standard_consultation(chat, user_input)
    tools = [
      diagnostic_tool_definition,
      cost_calculator_tool_definition,
      service_finder_tool_definition
    ]

    response = RubyLLM.chat(
      model: chat.model || 'gpt-4o-mini',
      messages: chat.context_messages + [
        { role: 'user', content: user_input.content }
      ],
      tools: tools,
      temperature: 0.3
    )

    assistant_message = chat.messages.create!(
      role: 'assistant',
      content: response.content,
      model: response.model
    )

    if response.respond_to?(:tool_calls) && response.tool_calls.any?
      process_tool_calls(response.tool_calls, chat, assistant_message)
    end
  end

  def self.diagnostic_tool_definition
    {
      name: 'diagnose_car_problem',
      description: 'Диагностирует проблемы автомобиля по симптомам',
      input_schema: {
        type: 'object',
        properties: {
          car_make: { type: 'string', description: 'Марка автомобиля' },
          symptoms: {
            type: 'array',
            items: { type: 'string' },
            description: 'Список симптомов'
          }
        },
        required: ['car_make', 'symptoms']
      }
    }
  end

  def self.cost_calculator_tool_definition
    {
      name: 'estimate_repair_cost',
      description: 'Рассчитывает стоимость ремонта',
      input_schema: {
        type: 'object',
        properties: {
          repair_type: { type: 'string', description: 'Тип ремонта' },
          car_make: { type: 'string', description: 'Марка автомобиля' },
          urgency: { type: 'string', enum: ['low', 'medium', 'high'] }
        },
        required: ['repair_type', 'car_make']
      }
    }
  end

  def self.service_finder_tool_definition
    {
      name: 'find_service_centers',
      description: 'Ищет автосервисы поблизости',
      input_schema: {
        type: 'object',
        properties: {
          repair_type: { type: 'string', description: 'Тип ремонта' },
          location: { type: 'string', description: 'Город или адрес' }
        },
        required: ['repair_type']
      }
    }
  end
end
```

---

## 📋 Заключение

Эта **comprehensive документация** по ruby_llm gem для **Valera Bot** включает:

✅ **Полное описание API** gem и его возможностей
✅ **Rails интеграцию** с acts_as макросами
✅ **Продвинутые функции**: streaming, embeddings, vision, tools
✅ **Архитектурные паттерны** для надежной работы
✅ **Кэширование и оптимизацию** производительности
✅ **Обработку ошибок** и retry логику
✅ **Полные примеры** для автомобильного сервиса
✅ **Тестирование** unit, integration и mocking
✅ **Реальные use cases** для Valera Bot

**Документация готова к использованию** для разработки Telegram бота с AI-ассистентом по автомобильному ремонту! 🚗🔧

---

## 📚 Дополнительные ресурсы

- **Официальная документация**: [ruby_llm GitHub](https://github.com/oldmoe/ruby_llm)
- **API Reference**: см. ruby_llm API documentation
- **Примеры**: [examples/](./examples/) директория
- **Архитектурные паттерны**: [patterns.md](./patterns.md)
- **Telegram Bot интеграция**: [../telegram-bot/](../telegram-bot/)

**Для Valera Bot team:** Эта документация - ваш основной ресурс для работы с ruby_llm gem. Обращайтесь к ней при любой разработке функциональности AI-ассистента.

