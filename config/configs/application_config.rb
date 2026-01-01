# frozen_string_literal: true

# Base class for application config classes
class ApplicationConfig < Anyway::Config
  env_prefix ''

  # Defaults are in config/application.yml
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

    # Platform Bot (единый бот для авторизации и уведомлений платформы)
    :platform_bot_token,
    :platform_bot_username,
    :platform_admin_chat_id,

    # Application branding
    :app_name,

    # Landing page and support
    :demo_bot_username,
    :support_telegram,
    :support_email,
    :offer_url,
    :requisites_url,
    :commercial_proposal_url,
    :contract_url,
    :project_folder_url,

    # File paths
    :system_prompt_path,
    :welcome_message_path,
    :price_list_path,
    :tools_instruction_path,
    :company_info_path,
    :redis_cache_store_url,

    # Rate limiter configuration
    :rate_limit_requests,
    :rate_limit_period,

    # Conversation management
    :max_history_size,

    # LLM configuration
    :llm_temperature,

    # Development warnings
    :development_warning,

    # Allowed hosts for subdomain routing
    :allowed_hosts,

    # Web console permissions (IP addresses/networks)
    :web_console_permissions,

    # Host and port for URL generation and subdomain routing
    :host,
    :port,
    :protocol,
    :public_port, # Публичный порт для формирования URL (по умолчанию: 443 для https, 80 для http)

    # Admin host for URL generation (default: admin.#{host})
    :admin_host,

    # Telegram Auth settings
    :telegram_auth_expiration,

    # Reserved subdomains that cannot be used as tenant keys
    :reserved_subdomains,

    # Tenant invite expiration (in days)
    :tenant_invite_expiration_days,

    # Dashboard: максимальное количество сообщений для отображения в чате
    max_chat_messages_display: 200,

    # Dashboard: количество чатов на странице (для infinite scroll)
    chats_per_page: 20,

    # Manager takeover: включить возможность менеджеру вступать в диалог
    manager_takeover_enabled: true,

    # Manager takeover: таймаут в минутах до автоматического возврата чата боту
    manager_takeover_timeout_minutes: 30
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
    port: :integer,

    # Host and protocol
    host: :string,
    protocol: :string,
    public_port: :integer,

    # Floats
    llm_temperature: :float,

    # Booleans
    development_warning: :boolean,

    # Platform Bot
    platform_bot_token: :string,
    platform_bot_username: :string,
    platform_admin_chat_id: :string,
    telegram_auth_expiration: :integer,

    # Tenant invites
    tenant_invite_expiration_days: :integer,

    # Dashboard
    max_chat_messages_display: :integer,
    chats_per_page: :integer,

    # Manager takeover
    manager_takeover_enabled: :boolean,
    manager_takeover_timeout_minutes: :integer,

    # Admin host
    admin_host: :string,

    # Landing page and support
    demo_bot_username: :string,
    support_telegram: :string,
    support_email: :string,
    offer_url: :string,
    requisites_url: :string,
    commercial_proposal_url: :string,
    contract_url: :string,
    project_folder_url: :string
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

  # Возвращает хост админки (с дефолтом admin.#{host})
  def admin_host_with_default
    admin_host.presence || "admin.#{host}"
  end

  # Вычисляет tld_length для корректной работы с поддоменами
  #
  # tld_length определяет сколько сегментов справа считаются TLD (top-level domain).
  # Формула: количество точек в host (минимум 1).
  #
  # Для 'lvh.me' (1 точка) -> 1 ('me' = TLD, 'lvh' = domain, subdomain 'dev' даст 'dev.lvh.me')
  # Для '3010.brandymint.ru' (2 точки) -> 2 ('brandymint.ru' = TLD+domain, subdomain 'dev' даст 'dev.3010.brandymint.ru')
  # Для 'localhost' (0 точек) -> 1 (default)
  def tld_length
    dots = host.to_s.count('.')
    [ dots, 1 ].max
  end

  # Возвращает ID платформенного бота (первая часть токена)
  # Токен имеет формат: BOT_ID:SECRET_KEY
  def platform_bot_id
    platform_bot_token.to_s.split(':').first.to_i
  end

  # Возвращает публичный порт для URL (по умолчанию: 443 для https, 80 для http)
  def public_port_with_default
    return public_port if public_port.present?

    protocol == 'https' ? 443 : 80
  end

  # Опции для генерации URL в routes и mailers
  def default_url_options
    options = { host:, protocol: }
    effective_port = public_port_with_default
    # Добавляем port только если он нестандартный
    unless (effective_port == 80 && protocol == 'http') || (effective_port == 443 && protocol == 'https')
      options[:port] = effective_port
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
