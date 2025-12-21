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
    development_warning: true,

    # Allowed hosts for subdomain routing (array or comma-separated string)
    allowed_hosts: [],

    # Web console permissions (IP addresses/networks)
    # E.g., ['192.168.0.0/16', '10.0.0.0/8']
    web_console_permissions: [],

    # Host and port for URL generation and subdomain routing
    host: 'localhost',
    port: 3000,
    protocol: 'http'
  )

  # Type coercions to ensure proper data types from environment variables
  coerce_types(
    # Strings
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
    port: :integer,

    # Host and protocol
    host: :string,
    protocol: :string,

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

  # Вычисляет tld_length для корректной работы с поддоменами
  # Для '3010.brandymint.ru' -> 2 (чтобы subdomain был 'admin', а не 'admin.3010')
  # Для 'localhost' -> 1 (default)
  def tld_length
    dots = host.to_s.count('.')
    dots.positive? ? dots : 1
  end

  # Опции для генерации URL в routes и mailers
  def default_url_options
    options = { host:, protocol: }
    # Добавляем port только если он нестандартный
    unless (port.to_s == '80' && protocol == 'http') || (port.to_s == '443' && protocol == 'https')
      options[:port] = port
    end
    options
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
