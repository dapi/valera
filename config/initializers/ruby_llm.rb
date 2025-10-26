# frozen_string_literal: true

require 'ruby_llm'

RubyLLM.configure do |config|
  config.use_new_acts_as = true

  # Устанавливаем таймауты и retry настройки
  config.request_timeout = 120 # AppConfig.request_timeout
  config.max_retries = 1 # AppConfig.max_retries

  # API ключи провайдеров (используем ApplicationConfig вместо ENV)
  config.openai_api_key = ApplicationConfig.openai_api_key
  config.anthropic_api_key = ApplicationConfig.anthropic_api_key
  config.gemini_api_key = ApplicationConfig.gemini_api_key
  config.deepseek_api_key = ApplicationConfig.deepseek_api_key
  config.perplexity_api_key = ApplicationConfig.perplexity_api_key
  config.openrouter_api_key = ApplicationConfig.openrouter_api_key
  config.mistral_api_key = ApplicationConfig.mistral_api_key

  # Google Cloud (VertexAI) configuration
  config.vertexai_location = ApplicationConfig.vertexai_location
  config.vertexai_project_id = ApplicationConfig.vertexai_project_id

  # Модели по умолчанию
  config.default_model = ApplicationConfig.llm_model # 'claude-sonnet-4'           # For RubyLLM.chat
  config.default_embedding_model = ApplicationConfig.llm_model # 'text-embedding-3-large'  # For RubyLLM.embed
  config.default_image_model = ApplicationConfig.llm_model # 'dall-e-3'              # For RubyLLM.paint
end
