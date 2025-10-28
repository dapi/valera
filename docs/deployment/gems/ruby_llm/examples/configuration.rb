#!/usr/bin/env ruby

require 'ruby_llm'
require 'dotenv/load'

# Примеры различных конфигураций Ruby LLM
class RubyLLMConfigurationExamples
  def self.run_all_examples
    puts "⚙️ Примеры конфигурации Ruby LLM"
    puts "=" * 50

    demonstrate_basic_configuration
    demonstrate_multi_provider_configuration
    demonstrate_environment_specific_config
    demonstrate_advanced_configuration
    demonstrate_error_handling_config
    demonstrate_rails_integration_config
  end

  private

  def self.demonstrate_basic_configuration
    puts "\n📋 Пример 1: Базовая конфигурация"
    puts "-" * 35

    config_code = <<~RUBY
      # config/initializers/ruby_llm.rb
      require 'ruby_llm'

      RubyLLM.configure do |config|
        # Базовые настройки
        config.use_new_acts_as = true
        config.request_timeout = 120
        config.max_retries = 2

        # API ключ OpenAI
        config.openai_api_key = ENV.fetch('OPENAI_API_KEY', nil)

        # Модели по умолчанию
        config.default_model = 'gpt-3.5-turbo'
        config.default_embedding_model = 'text-embedding-3-large'
        config.default_image_model = 'dall-e-3'
      end
    RUBY

    puts config_code

    # Демонстрация
    configure_basic
    puts "\n✅ Базовая конфигурация успешно установлена"
    puts "   Модель по умолчанию: #{RubyLLM.configuration.default_model}"
  end

  def self.demonstrate_multi_provider_configuration
    puts "\n🌐 Пример 2: Мульти-провайдер конфигурация"
    puts "-" * 40

    config_code = <<~RUBY
      # config/initializers/ruby_llm.rb
      require 'ruby_llm'

      RubyLLM.configure do |config|
        # Общие настройки
        config.use_new_acts_as = true
        config.request_timeout = 120
        config.max_retries = 3

        # OpenAI
        config.openai_api_key = ENV.fetch('OPENAI_API_KEY', nil)

        # Anthropic Claude
        config.anthropic_api_key = ENV.fetch('ANTHROPIC_API_KEY', nil)

        # Google Gemini
        config.gemini_api_key = ENV.fetch('GEMINI_API_KEY', nil)

        # DeepSeek
        config.deepseek_api_key = ENV.fetch('DEEPSEEK_API_KEY', nil)

        # Mistral
        config.mistral_api_key = ENV.fetch('MISTRAL_API_KEY', nil)

        # OpenRouter (агрегатор моделей)
        config.openrouter_api_key = ENV.fetch('OPENROUTER_API_KEY', nil)

        # Модели по умолчанию для разных задач
        config.default_model = 'gpt-3.5-turbo'           # Для чатов
        config.default_embedding_model = 'text-embedding-3-large'  # Для эмбеддингов
        config.default_image_model = 'dall-e-3'          # Для изображений
      end
    RUBY

    puts config_code

    # Демонстрация доступных провайдеров
    configure_multi_provider
    puts "\n✅ Мульти-провайдер конфигурация установлена"
    puts "   Доступные провайдеры: OpenAI, Anthropic, Google Gemini, DeepSeek, Mistral, OpenRouter"
  end

  def self.demonstrate_environment_specific_config
    puts "\n🏗️ Пример 3: Конфигурация для разных окружений"
    puts "-" * 42

    config_code = <<~RUBY
      # config/initializers/ruby_llm.rb
      require 'ruby_llm'

      # Базовая конфигурация
      base_config = {
        use_new_acts_as: true,
        request_timeout: 120,
        max_retries: 2
      }

      # Конфигурация для разработки
      development_config = base_config.merge(
        request_timeout: 30,
        max_retries: 1,
        default_model: 'gpt-3.5-turbo'  # Более дешевая модель для разработки
      )

      # Конфигурация для продакшена
      production_config = base_config.merge(
        request_timeout: 180,
        max_retries: 5,
        default_model: 'gpt-4'  # Более мощная модель для продакшена
      )

      # Конфигурация для тестирования
      test_config = base_config.merge(
        request_timeout: 10,
        max_retries: 0,
        default_model: 'gpt-3.5-turbo'
      )

      # Применение конфигурации в зависимости от окружения
      config_to_use = case Rails.env
                      when 'development'
                        development_config
                      when 'production'
                        production_config
                      when 'test'
                        test_config
                      else
                        base_config
                      end

      RubyLLM.configure do |config|
        config_to_use.each { |key, value| config.send("#{key}=", value) }

        # API ключи (загружаются из ENV)
        config.openai_api_key = ENV.fetch('OPENAI_API_KEY', nil)
        config.anthropic_api_key = ENV.fetch('ANTHROPIC_API_KEY', nil)
        config.gemini_api_key = ENV.fetch('GEMINI_API_KEY', nil)
      end
    RUBY

    puts config_code

    # Демонстрация
    configure_for_environment('development')
    puts "\n✅ Конфигурация для development окружения"
    puts "   Таймаут: #{RubyLLM.configuration.request_timeout}s"
    puts "   Повторов: #{RubyLLM.configuration.max_retries}"
    puts "   Модель: #{RubyLLM.configuration.default_model}"
  end

  def self.demonstrate_advanced_configuration
    puts "\n🚀 Пример 4: Продвинутая конфигурация с middleware"
    puts "-" * 48

    config_code = <<~RUBY
      # config/initializers/ruby_llm.rb
      require 'ruby_llm'

      class LLMLogger
        def self.log_request(request)
          Rails.logger.info "LLM Request: #{request.model} - #{request.messages&.last&.content&.truncate(50)}"
        end

        def self.log_response(response)
          Rails.logger.info "LLM Response: #{response.usage[:total_tokens]} tokens"
        end
      end

      class LLMRateLimiter
        @requests = {}
        @mutex = Mutex.new

        def self.check_limit(user_id)
          @mutex.synchronize do
            now = Time.now
            @requests[user_id] ||= []
            @requests[user_id] = @requests[user_id].select { |t| now - t < 60 }  # За последнюю минуту

            if @requests[user_id].size >= 10  # Максимум 10 запросов в минуту
              raise "Rate limit exceeded for user #{user_id}"
            end

            @requests[user_id] << now
          end
        end
      end

      RubyLLM.configure do |config|
        # Базовые настройки
        config.use_new_acts_as = true
        config.request_timeout = 120
        config.max_retries = 3

        # API ключи
        config.openai_api_key = ENV.fetch('OPENAI_API_KEY', nil)
        config.anthropic_api_key = ENV.fetch('ANTHROPIC_API_KEY', nil)

        # Модели
        config.default_model = 'gpt-3.5-turbo'
        config.default_embedding_model = 'text-embedding-3-large'
        config.default_image_model = 'dall-e-3'

        # Middleware/hooks
        config.before_request = lambda do |request|
          user_id = request.metadata[:user_id]
          LLMRateLimiter.check_limit(user_id) if user_id
          LLMLogger.log_request(request)
        end

        config.after_request = lambda do |response|
          LLMLogger.log_response(response)
        end

        config.on_error = lambda do |error, request|
          Rails.logger.error "LLM Error: #{error.message} for request #{request.id}"
          # Отправка уведомления об ошибке
          ErrorNotifier.notify(error, context: { request: request })
        end
      end
    RUBY

    puts config_code

    # Демонстрация
    configure_with_middleware
    puts "\n✅ Продвинутая конфигурация с middleware установлена"
    puts "   Включены логирование, rate limiting и обработка ошибок"
  end

  def self.demonstrate_error_handling_config
    puts "\n🛡️ Пример 5: Конфигурация с обработкой ошибок"
    puts "-" * 40

    config_code = <<~RUBY
      # config/initializers/ruby_llm.rb
      require 'ruby_llm'

      class ResilientLLMClient
        MAX_RETRIES = 3
        BASE_DELAY = 1
        MAX_DELAY = 60

        def self.chat_with_fallback(message, model: nil, system: nil)
          models_to_try = model ? [model] : [
            'gpt-3.5-turbo',
            'claude-haiku-3.5',
            'gemini-pro'
          ]

          models_to_try.each do |current_model|
            begin
              return attempt_chat_with_retry(message, model: current_model, system: system)
            rescue RubyLLM::AuthenticationError => e
              Rails.logger.error "Authentication failed for #{current_model}: #{e.message}"
              next  # Пробуем следующую модель
            rescue RubyLLM::RateLimitError => e
              Rails.logger.warn "Rate limit for #{current_model}, retrying..."
              sleep(e.retry_after || BASE_DELAY)
              retry
            rescue RubyLLM::APIError => e
              Rails.logger.error "API error for #{current_model}: #{e.message}"
              next  # Пробуем следующую модель
            rescue => e
              Rails.logger.error "Unexpected error with #{current_model}: #{e.message}"
              next
            end
          end

          raise "All models failed to process the request"
        end

        private

        def self.attempt_chat_with_retry(message, model:, system:)
          attempts = 0

          begin
            chat = RubyLLM.chat.new(model: model, system: system)
            chat.say(message)
          rescue RubyLLM::RateLimitError, RubyLLM::APIError => e
            if attempts < MAX_RETRIES
              attempts += 1
              delay = [BASE_DELAY * (2 ** (attempts - 1)), MAX_DELAY].min
              Rails.logger.info "Retrying in #{delay}s (attempt #{attempts}/#{MAX_RETRIES})"
              sleep(delay)
              retry
            else
              raise e
            end
          end
        end
      end

      RubyLLM.configure do |config|
        config.use_new_acts_as = true
        config.request_timeout = 60
        config.max_retries = 2
        config.openai_api_key = ENV.fetch('OPENAI_API_KEY', nil)
        config.anthropic_api_key = ENV.fetch('ANTHROPIC_API_KEY', nil)
        config.gemini_api_key = ENV.fetch('GEMINI_API_KEY', nil)

        # Настройка обработки ошибок
        config.on_error = lambda do |error, request|
          case error
          when RubyLLM::AuthenticationError
            ErrorNotifier.auth_error(error)
          when RubyLLM::RateLimitError
            ErrorNotifier.rate_limit_error(error, request.metadata[:user_id])
          when RubyLLM::APIError
            ErrorNotifier.api_error(error)
          else
            ErrorNotifier.general_error(error)
          end
        end
      end
    RUBY

    puts config_code

    # Демонстрация
    configure_with_error_handling
    puts "\n✅ Конфигурация с обработкой ошибок установлена"
    puts "   Включены retry логика и fallback модели"
  end

  def self.demonstrate_rails_integration_config
    puts "\n🔧 Пример 6: Интеграция с Rails и anyway_config"
    puts "-" * 48

    config_code = <<~RUBY
      # config/configs/application_config.rb
      class ApplicationConfig
        config_name :application

        # LLM конфигурация
        attr_config :llm_model, default: 'gpt-3.5-turbo'
        attr_config :llm_temperature, default: 0.7
        attr_config :llm_max_tokens, default: 1000
        attr_config :llm_request_timeout, default: 120
        attr_config :llm_max_retries, default: 2
        attr_config :llm_system_prompt, default: 'You are a helpful assistant.'

        # API ключи (можно переопределить через ENV)
        attr_config :openai_api_key, default: nil
        attr_config :anthropic_api_key, default: nil
        attr_config :gemini_api_key, default: nil

        # Валидация обязательных параметров
        required :llm_model

        # Валидация значений
        validates :llm_temperature, inclusion: { in: 0.0..2.0 }
        validates :llm_max_tokens, inclusion: { in: 1..4096 }
        validates :llm_request_timeout, inclusion: { in: 10..300 }
        validates :llm_max_retries, inclusion: { in: 0..5 }
      end

      # config/initializers/ruby_llm.rb
      require 'ruby_llm'

      RubyLLM.configure do |config|
        # Общие настройки
        config.use_new_acts_as = true
        config.request_timeout = ApplicationConfig.llm_request_timeout
        config.max_retries = ApplicationConfig.llm_max_retries

        # API ключи
        config.openai_api_key = ApplicationConfig.openai_api_key || ENV.fetch('OPENAI_API_KEY', nil)
        config.anthropic_api_key = ApplicationConfig.anthropic_api_key || ENV.fetch('ANTHROPIC_API_KEY', nil)
        config.gemini_api_key = ApplicationConfig.gemini_api_key || ENV.fetch('GEMINI_API_KEY', nil)

        # Модели по умолчанию
        config.default_model = ApplicationConfig.llm_model
        config.default_embedding_model = 'text-embedding-3-large'
        config.default_image_model = 'dall-e-3'

        # Настройки для Rails окружения
        if Rails.env.development?
          config.default_model = 'gpt-3.5-turbo'  # Более дешевая модель для разработки
        elsif Rails.env.production?
          config.default_model = ApplicationConfig.llm_model
        end
      end

      # app/services/llm_service.rb
      class LLMService
        def self.chat(message, options = {})
          model = options[:model] || ApplicationConfig.llm_model
          system = options[:system] || ApplicationConfig.llm_system_prompt
          temperature = options[:temperature] || ApplicationConfig.llm_temperature
          max_tokens = options[:max_tokens] || ApplicationConfig.llm_max_tokens

          chat = RubyLLM.chat.new(
            model: model,
            system: system,
            temperature: temperature,
            max_tokens: max_tokens
          )

          chat.say(message)
        end

        def self.embed(text)
          RubyLLM.embed(text, model: 'text-embedding-3-large')
        end

        def self.generate_image(prompt, options = {})
          model = options[:model] || 'dall-e-3'
          size = options[:size] || '1024x1024'
          quality = options[:quality] || 'standard'

          RubyLLM.paint(prompt, model: model, size: size, quality: quality)
        end
      end
    RUBY

    puts config_code

    # Демонстрация
    configure_rails_integration
    puts "\n✅ Конфигурация с Rails интеграцией установлена"
    puts "   Используется anyway_config для управления параметрами"
  end

  # Вспомогательные методы конфигурации для демонстрации

  def self.configure_basic
    RubyLLM.configure do |config|
      config.use_new_acts_as = true
      config.request_timeout = 120
      config.max_retries = 2
      config.openai_api_key = ENV.fetch('OPENAI_API_KEY', 'demo-key')
      config.default_model = 'gpt-3.5-turbo'
      config.default_embedding_model = 'text-embedding-3-large'
      config.default_image_model = 'dall-e-3'
    end
  end

  def self.configure_multi_provider
    RubyLLM.configure do |config|
      config.use_new_acts_as = true
      config.request_timeout = 120
      config.max_retries = 3
      config.openai_api_key = ENV.fetch('OPENAI_API_KEY', 'demo-key')
      config.anthropic_api_key = ENV.fetch('ANTHROPIC_API_KEY', 'demo-key')
      config.gemini_api_key = ENV.fetch('GEMINI_API_KEY', 'demo-key')
      config.deepseek_api_key = ENV.fetch('DEEPSEEK_API_KEY', 'demo-key')
      config.mistral_api_key = ENV.fetch('MISTRAL_API_KEY', 'demo-key')
      config.openrouter_api_key = ENV.fetch('OPENROUTER_API_KEY', 'demo-key')
      config.default_model = 'gpt-3.5-turbo'
      config.default_embedding_model = 'text-embedding-3-large'
      config.default_image_model = 'dall-e-3'
    end
  end

  def self.configure_for_environment(env)
    case env
    when 'development'
      RubyLLM.configure do |config|
        config.use_new_acts_as = true
        config.request_timeout = 30
        config.max_retries = 1
        config.openai_api_key = ENV.fetch('OPENAI_API_KEY', 'demo-key')
        config.default_model = 'gpt-3.5-turbo'
      end
    when 'production'
      RubyLLM.configure do |config|
        config.use_new_acts_as = true
        config.request_timeout = 180
        config.max_retries = 5
        config.openai_api_key = ENV.fetch('OPENAI_API_KEY', 'demo-key')
        config.default_model = 'gpt-4'
      end
    end
  end

  def self.configure_with_middleware
    RubyLLM.configure do |config|
      config.use_new_acts_as = true
      config.request_timeout = 120
      config.max_retries = 3
      config.openai_api_key = ENV.fetch('OPENAI_API_KEY', 'demo-key')
      config.default_model = 'gpt-3.5-turbo'

      # Эмуляция middleware
      config.before_request = lambda { |req| puts "Request: #{req.model}" }
      config.after_request = lambda { |res| puts "Response received" }
      config.on_error = lambda { |err, req| puts "Error: #{err.message}" }
    end
  end

  def self.configure_with_error_handling
    RubyLLM.configure do |config|
      config.use_new_acts_as = true
      config.request_timeout = 60
      config.max_retries = 2
      config.openai_api_key = ENV.fetch('OPENAI_API_KEY', 'demo-key')
      config.anthropic_api_key = ENV.fetch('ANTHROPIC_API_KEY', 'demo-key')
      config.gemini_api_key = ENV.fetch('GEMINI_API_KEY', 'demo-key')
      config.default_model = 'gpt-3.5-turbo'

      config.on_error = lambda { |err, req| puts "Error handled: #{err.message}" }
    end
  end

  def self.configure_rails_integration
    # Эмуляция anyway_config
    app_config = OpenStruct.new(
      llm_model: 'gpt-3.5-turbo',
      llm_temperature: 0.7,
      llm_max_tokens: 1000,
      llm_request_timeout: 120,
      llm_max_retries: 2,
      llm_system_prompt: 'You are a helpful assistant.',
      openai_api_key: ENV.fetch('OPENAI_API_KEY', 'demo-key'),
      anthropic_api_key: ENV.fetch('ANTHROPIC_API_KEY', 'demo-key'),
      gemini_api_key: ENV.fetch('GEMINI_API_KEY', 'demo-key')
    )

    RubyLLM.configure do |config|
      config.use_new_acts_as = true
      config.request_timeout = app_config.llm_request_timeout
      config.max_retries = app_config.llm_max_retries
      config.openai_api_key = app_config.openai_api_key
      config.anthropic_api_key = app_config.anthropic_api_key
      config.gemini_api_key = app_config.gemini_api_key
      config.default_model = app_config.llm_model
      config.default_embedding_model = 'text-embedding-3-large'
      config.default_image_model = 'dall-e-3'
    end
  end
end

# Класс для демонстрации runtime конфигурации
class RuntimeConfigurationDemo
  def self.show_dynamic_model_selection
    puts "\n🔄 Демонстрация динамического выбора моделей"
    puts "-" * 45

    # Фабрика для выбора моделей под разные задачи
    class ModelSelector
      MODELS = {
        code_generation: 'gpt-4',
        creative_writing: 'claude-sonnet-4',
        quick_response: 'gpt-3.5-turbo',
        multilingual: 'gemini-pro',
        cost_effective: 'deepseek-chat'
      }.freeze

      def self.for_task(task_type)
        model = MODELS[task_type] || 'gpt-3.5-turbo'
        puts "   Выбрана модель '#{model}' для задачи '#{task_type}'"
        model
      end

      def self.available_models
        MODELS.keys
      end
    end

    # Демонстрация
    tasks = [:code_generation, :creative_writing, :quick_response, :multilingual, :cost_effective]

    tasks.each do |task|
      model = ModelSelector.for_task(task)
      puts "   ✓ Задача: #{task} → Модель: #{model}"
    end

    puts "\n✅ Динамический выбор моделей работает"
  end

  def self.show_context_aware_configuration
    puts "\n🎯 Демонстрация контекстно-зависимой конфигурации"
    puts "-" * 50

    class ContextAwareLLM
      def initialize(user_id)
        @user_id = user_id
      end

      def chat(message, context = {})
        model = select_model_for_context(context)
        system_prompt = build_system_prompt(context)

        puts "   Пользователь: #{@user_id}"
        puts "   Контекст: #{context}"
        puts "   Модель: #{model}"
        puts "   System prompt: #{system_prompt.truncate(50)}..."

        # Здесь был бы реальный вызов RubyLLM
        "Ответ от модели #{model}"
      end

      private

      def select_model_for_context(context)
        case context[:task]
        when :coding
          context[:senior] ? 'gpt-4' : 'gpt-3.5-turbo'
        when :creative
          'claude-sonnet-4'
        when :analysis
          'gpt-4'
        else
          'gpt-3.5-turbo'
        end
      end

      def build_system_prompt(context)
        base_prompt = "Ты - полезный ассистент."

        case context[:task]
        when :coding
          base_prompt += " Ты - опытный Ruby разработчик."
        when :creative
          base_prompt += " Ты - креативный писатель."
        when :analysis
          base_prompt += " Ты - аналитик данных."
        end

        base_prompt
      end
    end

    # Демонстрация
    llm = ContextAwareLLM.new('user_123')

    contexts = [
      { task: :coding, senior: true },
      { task: :creative },
      { task: :analysis, domain: 'business' },
      {}
    ]

    contexts.each do |context|
      llm.chat("Пример сообщения", context)
      puts
    end

    puts "✅ Контекстно-зависимая конфигурация работает"
  end
end

# Запуск примеров
if __FILE__ == $0
  # Запуск основных примеров конфигурации
  RubyLLMConfigurationExamples.run_all_examples

  # Запуск демонстраций runtime конфигурации
  RuntimeConfigurationDemo.show_dynamic_model_selection
  RuntimeConfigurationDemo.show_context_aware_configuration

  puts "\n🎉 Все примеры конфигурации завершены!"
  puts "\n💡 Советы:"
  puts "   • Используйте переменные окружения для API ключей"
  puts "   • Настраивайте разные модели для разных окружений"
  puts "   • Внедряйте retry логику и обработку ошибок"
  puts "   • Используйте anyway_config для управления конфигурацией"
  puts "   • Выбирайте модели в зависимости от типа задачи"
end