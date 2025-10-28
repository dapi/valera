# Ruby LLM Architecture Patterns

## Основные архитектурные паттерны для Ruby LLM

### 1. Service Layer Pattern

Паттерн для инкапсуляции бизнес-логики работы с LLM:

```ruby
# app/services/llm_service.rb
class LLMService
  class << self
    def chat(message, options = {})
      model = select_model(options[:task_type])
      system = build_system_prompt(options[:context])

      chat = RubyLLM.chat.new(
        model: model,
        system: system,
        temperature: options[:temperature] || 0.7
      )

      response = chat.say(message)
      log_usage(response.usage)
      response
    end

    def embed(texts)
      RubyLLM.embed(Array(texts), model: 'text-embedding-3-large')
    end

    private

    def select_model(task_type)
      case task_type
      when :code_generation
        'gpt-4'
      when :creative_writing
        'claude-sonnet-4'
      when :quick_response
        'gpt-3.5-turbo'
      else
        ApplicationConfig.llm_model
      end
    end

    def build_system_prompt(context)
      base_prompt = "Ты - полезный ассистент."
      base_prompt += context_specific_instructions(context) if context
      base_prompt
    end

    def log_usage(usage)
      Rails.logger.info "LLM Usage: #{usage[:total_tokens]} tokens"
    end
  end
end
```

### 2. Strategy Pattern for Model Selection

Паттерн для выбора оптимальной модели под конкретную задачу:

```ruby
# app/strategies/model_selection_strategy.rb
class ModelSelectionStrategy
  MODELS = {
    openai: {
      'gpt-4' => { cost: 0.03, quality: :high, speed: :medium, capabilities: [:text, :vision, :tools] },
      'gpt-3.5-turbo' => { cost: 0.002, quality: :medium, speed: :fast, capabilities: [:text, :tools] }
    },
    anthropic: {
      'claude-sonnet-4' => { cost: 0.015, quality: :high, speed: :medium, capabilities: [:text, :vision, :tools] },
      'claude-haiku-3.5' => { cost: 0.001, quality: :medium, speed: :fast, capabilities: [:text, :tools] }
    },
    google: {
      'gemini-pro' => { cost: 0.0005, quality: :medium, speed: :fast, capabilities: [:text, :vision] }
    }
  }.freeze

  def self.select_model(requirements = {})
    candidates = find_candidates(requirements)
    ranked = rank_models(candidates, requirements)
    ranked.first[:model]
  end

  private

  def self.find_candidates(requirements)
    candidates = []

    MODELS.each do |provider, models|
      models.each do |model, specs|
        if meets_requirements?(specs, requirements)
          candidates << { model: model, provider: provider, **specs }
        end
      end
    end

    candidates
  end

  def self.meets_requirements?(specs, requirements)
    # Проверка необходимых capabilities
    if requirements[:capabilities]
      return false unless (requirements[:capabilities] - specs[:capabilities]).empty?
    end

    # Проверка максимальной стоимости
    if requirements[:max_cost]
      return false if specs[:cost] > requirements[:max_cost]
    end

    # Проверка минимального качества
    if requirements[:min_quality]
      quality_levels = { low: 1, medium: 2, high: 3 }
      return false if quality_levels[specs[:quality]] < quality_levels[requirements[:min_quality]]
    end

    true
  end

  def self.rank_models(candidates, requirements)
    candidates.sort_by do |candidate|
      score = 0

      # Предпочтение более качественным моделям
      quality_scores = { low: 1, medium: 2, high: 3 }
      score += quality_scores[candidate[:quality]] * 10

      # Предпочтение более быстрым моделям
      speed_scores = { slow: 1, medium: 2, fast: 3 }
      score += speed_scores[candidate[:speed]] * 5

      # Предпочтение более дешевым моделям
      score -= candidate[:cost] * 100

      -score  # negative for ascending sort (higher score first)
    end
  end
end
```

### 3. Factory Pattern for Response Builders

Паттерн для создания различных типов ответов:

```ruby
# app/factories/response_factory.rb
class ResponseFactory
  def self.create(type, data, options = {})
    case type
    when :text
      TextResponse.new(data, options)
    when :structured
      StructuredResponse.new(data, options)
    when :streaming
      StreamingResponse.new(data, options)
    when :tool_response
      ToolResponse.new(data, options)
    else
      raise "Unknown response type: #{type}"
    end
  end
end

class TextResponse
  def initialize(content, options = {})
    @content = content
    @options = options
  end

  def format
    {
      type: :text,
      content: @content,
      metadata: @options[:metadata] || {}
    }
  end

  def deliver(chat_id)
    # Логика доставки текстового ответа
  end
end

class StructuredResponse
  def initialize(data, options = {})
    @data = data
    @options = options
  end

  def format
    {
      type: :structured,
      data: @data,
      schema: @options[:schema],
      metadata: @options[:metadata] || {}
    }
  end
end
```

### 4. Observer Pattern for LLM Events

Паттерн для отслеживания событий LLM:

```ruby
# app/observers/llm_event_observer.rb
class LLMEventObserver
  def self.initialize
    @listeners = []
  end

  def self.subscribe(event_type, listener)
    @listeners << { event: event_type, listener: listener }
  end

  def self.notify(event_type, data)
    @listeners.select { |l| l[:event] == event_type }
              .each { |l| l[:listener].call(data) }
  end

  # Подписчики
  subscribe(:request_started, method(:log_request_start))
  subscribe(:request_completed, method(:log_request_completion))
  subscribe(:request_failed, method(:log_request_failure))
  subscribe(:tokens_used, method(:track_token_usage))
  subscribe(:cost_incurred, method(:track_costs))

  private

  def self.log_request_start(data)
    Rails.logger.info "LLM Request Started: #{data[:model]} for user #{data[:user_id]}"
  end

  def self.log_request_completion(data)
    Rails.logger.info "LLM Request Completed: #{data[:duration]}ms, #{data[:tokens]} tokens"
  end

  def self.log_request_failure(data)
    Rails.logger.error "LLM Request Failed: #{data[:error]}"
    ErrorNotifier.notify(data[:error], context: data)
  end

  def self.track_token_usage(data)
    TokenUsageTracker.record(data[:user_id], data[:tokens], data[:model])
  end

  def self.track_costs(data)
    CostTracker.record(data[:user_id], data[:cost], data[:model])
  end
end
```

### 5. Circuit Breaker Pattern

Паттерн для защиты от каскадных сбоев:

```ruby
# app/services/circuit_breaker.rb
class CircuitBreaker
  def initialize(service, failure_threshold: 5, timeout: 60)
    @service = service
    @failure_threshold = failure_threshold
    @timeout = timeout
    @failure_count = 0
    @last_failure_time = nil
    @state = :closed  # :closed, :open, :half_open
  end

  def call(*args)
    case @state
    when :open
      if Time.now - @last_failure_time > @timeout
        @state = :half_open
      else
        raise ServiceUnavailableError, "Circuit breaker is open"
      end
    end

    begin
      result = @service.call(*args)
      reset if @state == :half_open
      result
    rescue => e
      record_failure
      raise e
    end
  end

  private

  def record_failure
    @failure_count += 1
    @last_failure_time = Time.now

    if @failure_count >= @failure_threshold
      @state = :open
    end
  end

  def reset
    @failure_count = 0
    @state = :closed
  end
end

# Использование
llm_circuit_breaker = CircuitBreaker.new(
  ->(message) { RubyLLM.chat.new.say(message) },
  failure_threshold: 5,
  timeout: 60
)

def safe_llm_call(message)
  llm_circuit_breaker.call(message)
rescue ServiceUnavailableError
  # Fallback логика
  fallback_response
end
```

### 6. Template Method Pattern for LLM Workflows

Паттерн для стандартизации рабочих процессов:

```ruby
# app/workflows/base_llm_workflow.rb
class BaseLLMWorkflow
  def execute(input)
    validate_input(input)
    preprocessed_input = preprocess(input)
    response = call_llm(preprocessed_input)
    postprocessed_response = postprocess(response)
    validate_output(postprocessed_response)
    postprocessed_response
  rescue => e
    handle_error(e)
  end

  protected

  def validate_input(input)
    # Базовая валидация
    raise InvalidInputError, "Input cannot be nil" if input.nil?
  end

  def preprocess(input)
    # Базовая предобработка
    input.is_a?(String) ? input.strip : input
  end

  def call_llm(input)
    # Должен быть переопределен в дочерних классах
    raise NotImplementedError, "Subclasses must implement call_llm"
  end

  def postprocess(response)
    # Базовая постобработка
    response
  end

  def validate_output(output)
    # Базовая валидация вывода
    raise InvalidOutputError, "Output cannot be nil" if output.nil?
  end

  def handle_error(error)
    # Базовая обработка ошибок
    Rails.logger.error "LLM Workflow Error: #{error.message}"
    raise error
  end
end

# Конкретная реализация
class ChatWorkflow < BaseLLMWorkflow
  def initialize(model: nil, system: nil, temperature: 0.7)
    @model = model || ApplicationConfig.llm_model
    @system = system
    @temperature = temperature
  end

  protected

  def call_llm(input)
    chat = RubyLLM.chat.new(
      model: @model,
      system: @system,
      temperature: @temperature
    )
    chat.say(input)
  end

  def postprocess(response)
    {
      content: response.content,
      model: response.model,
      usage: response.usage,
      metadata: response.metadata
    }
  end
end
```

### 7. Decorator Pattern for LLM Responses

Паттерн для добавления функциональности к ответам:

```ruby
# app/decorators/llm_response_decorator.rb
class LLMResponseDecorator
  def initialize(response)
    @response = response
  end

  def content
    @response.content
  end

  def content_with_formatting
    format_content(@response.content)
  end

  def content_with_safety_checks
    safe_content = check_safety(@response.content)
    safe_content || "[Content filtered for safety]"
  end

  def usage_summary
    usage = @response.usage
    return "No usage data" unless usage

    "Tokens used: #{usage[:total_tokens]} (#{usage[:prompt_tokens]} prompt + #{usage[:completion_tokens]} completion)"
  end

  def cost_estimate
    return "Cost estimate unavailable" unless @response.usage

    model_pricing = ModelPricingService.get_pricing(@response.model)
    prompt_cost = (@response.usage[:prompt_tokens] / 1000.0) * model_pricing[:input]
    completion_cost = (@response.usage[:completion_tokens] / 1000.0) * model_pricing[:output]

    total_cost = prompt_cost + completion_cost
    "Estimated cost: $#{total_cost.round(6)}"
  end

  private

  def format_content(content)
    # Форматирование markdown, кода и т.д.
    formatted = content

    # Подсветка синтаксиса для кода
    formatted.gsub!(/```(\w+)?\n(.*?)\n```/m) do |match|
      language = $1 || 'text'
      code = $2
      "<pre><code class=\"language-#{language}\">#{CGI.escapeHTML(code)}</code></pre>"
    end

    # Обработка ссылок
    formatted.gsub!(/\[([^\]]+)\]\(([^)]+)\)/, '<a href="\\2">\\1</a>')

    formatted
  end

  def check_safety(content)
    # Проверка контента на безопасность
    safety_patterns = [
      /\b(password|secret|token|key)\s*[:=]\s*\S+/i,
      /\b\d{4}[-\s]?\d{4}[-\s]?\d{4}[-\s]?\d{4}\b/  # Credit card pattern
    ]

    safe_content = content.dup
    safety_patterns.each do |pattern|
      safe_content.gsub!(pattern, '[REDACTED]')
    end

    safe_content
  end
end
```

### 8. Command Pattern for LLM Operations

Паттерн для инкапсуляции операций с LLM:

```ruby
# app/commands/llm_command.rb
class BaseLLMCommand
  def initialize(params = {})
    @params = params
  end

  def execute
    validate_params
    result = perform
    log_execution
    result
  rescue => e
    handle_error(e)
    raise e
  end

  protected

  def validate_params
    # Базовая валидация
  end

  def perform
    # Должен быть переопределен
    raise NotImplementedError
  end

  def log_execution
    Rails.logger.info "#{self.class.name} executed with params: #{@params}"
  end

  def handle_error(error)
    Rails.logger.error "#{self.class.name} failed: #{error.message}"
  end
end

class ChatCommand < BaseLLMCommand
  def initialize(message, user_id, options = {})
    super(message: message, user_id: user_id, **options)
  end

  protected

  def validate_params
    raise ArgumentError, "Message is required" if @params[:message].blank?
    raise ArgumentError, "User ID is required" if @params[:user_id].blank?
  end

  def perform
    chat = find_or_create_chat
    response = chat.say(@params[:message])
    save_message_and_response(chat, response)
    response
  end

  private

  def find_or_create_chat
    # Логика поиска или создания чата
  end

  def save_message_and_response(chat, response)
    # Сохранение сообщений в базе данных
  end
end
```

### 9. Caching Pattern for LLM Responses

Паттерн для кэширования ответов LLM:

```ruby
# app/services/llm_cache_service.rb
class LLMCacheService
  CACHE_VERSION = 'v1'.freeze
  DEFAULT_TTL = 1.hour

  class << self
    def get(key, model: nil)
      cache_key = build_cache_key(key, model)
      Rails.cache.read(cache_key)
    end

    def set(key, value, model: nil, ttl: DEFAULT_TTL)
      cache_key = build_cache_key(key, model)
      Rails.cache.write(cache_key, value, expires_in: ttl)
      value
    end

    def cached_chat(message, options = {}, &block)
      cache_key = generate_chat_cache_key(message, options)
      model = options[:model] || ApplicationConfig.llm_model

      get(cache_key, model: model) || set(cache_key, block.call, model: model)
    end

    def cached_embedding(text, model: 'text-embedding-3-large')
      cache_key = "embedding:#{Digest::MD5.hexdigest(text)}:#{model}"
      get(cache_key, model: model) || set(cache_key, RubyLLM.embed(text, model: model), model: model, ttl: 24.hours)
    end

    def invalidate_pattern(pattern)
      keys = Rails.cache.redis.keys("llm:#{CACHE_VERSION}:*#{pattern}*")
      Rails.cache.redis.del(*keys) if keys.any?
    end

    private

    def build_cache_key(key, model)
      "llm:#{CACHE_VERSION}:#{model}:#{Digest::MD5.hexdigest(key.to_s)}"
    end

    def generate_chat_cache_key(message, options)
      # Создаем уникальный ключ на основе сообщения и опций
      key_data = {
        message: message,
        system: options[:system],
        temperature: options[:temperature],
        max_tokens: options[:max_tokens]
      }
      Digest::MD5.hexdigest(key_data.to_json)
    end
  end
end

# Использование кэширования
class CachedLLMService
  def self.chat(message, options = {})
    LLMCacheService.cached_chat(message, options) do
      chat = RubyLLM.chat.new(
        model: options[:model],
        system: options[:system],
        temperature: options[:temperature]
      )
      chat.say(message)
    end
  end

  def self.embed(text, model: 'text-embedding-3-large')
    LLMCacheService.cached_embedding(text, model: model)
  end
end
```

## Best Practices

### 1. Безопасность
- Всегда валидируйте входные данные
- Фильтруйте sensitive информацию в ответах
- Используйте rate limiting
- Логируйте все запросы и ответы

### 2. Производительность
- Используйте кэширование для повторяющихся запросов
- Implement circuit breakers для защиты от сбоев
- Оптимизируйте размер контекста
- Используйте streaming для длинных ответов

### 2. Масштабирование
- Используйте очереди для фоновых задач
- Implement horizontal scaling для обработки нагрузки
- Мониторьте использование токенов и стоимость
- Используйте connection pooling

### 3. Тестирование
- Изолируйте LLM вызовы в сервисах
- Используйте моки для unit тестов
- Пишите интеграционные тесты
- Тестируйте fallback сценарии

### 4. Мониторинг
- Отслеживайте метрики использования
- Мониторьте стоимость API
- Настраивайте алерты для ошибок
- Анализируйте производительность моделей