# frozen_string_literal: true

# Base class for application config classes
class ApplicationConfig < Anyway::Config
  config_name :valera
  env_prefix ''

  attr_config(
    # RubyLLM configuration
    llm_provider: '',
    llm_model: '',

    # File paths
    system_prompt_path: './data/system-prompt.md',
    welcome_message_path: './data/welcome-message.md',
    price_list_path: './data/price.csv',
    company_info_path: './data/company-info.md',
    redis_cache_store_url: 'redis://localhost:6379/2',

    # Telegram configuration
    bot_token: '',
    admin_chat_id: nil,  # ID чата для отправки уведомлений о заявках

    # Rate limiter configuration
    rate_limit_requests: 10,
    rate_limit_period: 60,

    # Conversation management
    max_history_size: 10,
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
    bot_token: :string,
    admin_chat_id: :integer,

    # Integers
    rate_limit_requests: :integer,
    rate_limit_period: :integer,
    max_history_size: :integer,
    webhook_port: :integer
  )

  # Declare required parameters using anyway_config's required method
  required :bot_token, :llm_provider, :llm_model

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
