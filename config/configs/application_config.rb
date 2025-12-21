# frozen_string_literal: true

# Base class for application config classes
class ApplicationConfig < Anyway::Config
  env_prefix ''

  attr_config(
    # RubyLLM configuration
    :llm_provider,
    :llm_model,

    # LLM Provider API Keys
    :openai_api_key,
    :anthropic_api_key,
    :gemini_api_key,
    :deepseek_api_key,
    :perplexity_api_key,
    :openrouter_api_key,
    :mistral_api_key,

    # Google Cloud (VertexAI) configuration
    :vertexai_location,
    :vertexai_project_id,

    # Application branding
    app_name: 'Супер Валера',

    # File paths
    system_prompt_path: './data/system-prompt.md',
    welcome_message_path: './data/welcome-message.md',
    price_list_path: './data/price.csv',
    tools_instruction_path: './config/tools-instruction.md',
    company_info_path: './data/company-info.md',
    redis_cache_store_url: 'redis://localhost:6379/2',

    # Rate limiter configuration
    rate_limit_requests: 10,
    rate_limit_period: 60,

    # Conversation management
    max_history_size: 10,

    # LLM configuration
    llm_temperature: 0.5,

    # Development warnings
    development_warning: true
  )

  # Type coercions to ensure proper data types from environment variables
  coerce_types(
    # Strings
    app_name: :string,
    llm_provider: :string,
    llm_model: :string,
    openai_api_base: :string,
    system_prompt_path: :string,
    welcome_message_path: :string,
    price_list_path: :string,
    company_info_path: :string,
    bugsnag_api_key: :string,

    anthropic_base_url: :string,

    # LLM Provider API Keys
    openai_api_key: :string,
    anthropic_api_key: :string,
    gemini_api_key: :string,
    deepseek_api_key: :string,
    perplexity_api_key: :string,
    openrouter_api_key: :string,
    mistral_api_key: :string,

    # Google Cloud
    vertexai_location: :string,
    vertexai_project_id: :string,

    # Integers
    rate_limit_requests: :integer,
    rate_limit_period: :integer,
    max_history_size: :integer,
    webhook_port: :integer,

    # Floats
    llm_temperature: :float,

    # Booleans
    development_warning: :boolean
  )

  # System prompt
  def system_prompt
    File.read(system_prompt_path).presence || raise('No system prompt defined')
  end

  def system_prompt_md5
    @system_prompt_md5 ||= Digest::MD5.hexdigest system_prompt
    # Альтернативный способ поднять последнее сообщение от LLM
  end

  def company_info
    File.read(company_info_path).presence || raise('No company info defined')
  end

  def price_list
    File.read(price_list_path).presence || raise('No price list defined')
  end

  def tools_instruction
    File.read(tools_instruction_path).presence || raise('No tools instruction defined')
  end

  def welcome_message_template
    File.read(welcome_message_path).presence || raise('No welcome message defined')
  end

  # Declare required parameters using anyway_config's required method
  required :llm_provider, :llm_model

  class << self
    # Make it possible to access a singleton config instance
    # via class methods (i.e., without explicitly calling `instance`)
    delegate_missing_to :instance

    private

    # Returns a singleton config instance
    def instance
      @instance ||= new
    end
  end
end
