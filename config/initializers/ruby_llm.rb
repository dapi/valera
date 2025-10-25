# frozen_string_literal: true

require 'ruby_llm'

RubyLLM.configure do |config|
  config.use_new_acts_as = true

  # Используем OpenAI API ключ
  # Устанавливаем таймауты и retry настройки
  config.request_timeout = 120 # AppConfig.request_timeout
  config.max_retries = 1 # AppConfig.max_retries
  config.openai_api_key = ENV.fetch('OPENAI_API_KEY', nil)
  config.anthropic_api_key = ENV.fetch('ANTHROPIC_API_KEY', nil)
  config.gemini_api_key = ENV.fetch('GEMINI_API_KEY', nil)
  config.deepseek_api_key = ENV.fetch('DEEPSEEK_API_KEY', nil)
  config.perplexity_api_key = ENV.fetch('PERPLEXITY_API_KEY', nil)
  config.openrouter_api_key = ENV.fetch('OPENROUTER_API_KEY', nil)
  config.mistral_api_key = ENV.fetch('MISTRAL_API_KEY', nil)
  config.vertexai_location = ENV.fetch('GOOGLE_CLOUD_LOCATION', nil)
  config.vertexai_project_id = ENV.fetch('GOOGLE_CLOUD_PROJECT', nil)

  config.default_model = ApplicationConfig.llm_model # 'claude-sonnet-4'           # For RubyLLM.chat
  config.default_embedding_model = ApplicationConfig.llm_model # 'text-embedding-3-large'  # For RubyLLM.embed
  config.default_image_model = ApplicationConfig.llm_model # 'dall-e-3'              # For RubyLLM.paint
end
