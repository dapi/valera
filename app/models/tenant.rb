# frozen_string_literal: true

class Tenant < ApplicationRecord
  include ErrorLogger

  KEY_LENGTH = 3
  KEY_FORMAT = /\A[a-z0-9]+\z/
  WEBHOOK_SECRET_LENGTH = 32
  BOT_TOKEN_FORMAT = /\A\d+:[A-Za-z0-9_-]+\z/

  belongs_to :owner, class_name: 'User', optional: true
  belongs_to :manager, class_name: 'AdminUser', optional: true, counter_cache: :managed_tenants_count

  has_many :tenant_memberships, dependent: :destroy
  has_many :members, through: :tenant_memberships, source: :user
  has_many :tenant_invites, dependent: :destroy
  has_many :clients, dependent: :destroy
  has_many :chats, dependent: :destroy
  has_many :bookings, dependent: :destroy
  has_many :analytics_events, dependent: :destroy

  validates :name, presence: true
  validates :bot_token, presence: true, uniqueness: true, format: { with: BOT_TOKEN_FORMAT, message: :invalid_format }
  validates :bot_username, presence: true
  validates :key, presence: true, uniqueness: true, length: { is: KEY_LENGTH },
                  format: { with: KEY_FORMAT, message: :invalid_key_format },
                  exclusion: { in: ->(_) { ApplicationConfig.reserved_subdomains || [] }, message: :reserved }
  validates :webhook_secret, presence: true

  before_validation :generate_key, on: :create, if: -> { key.blank? }
  before_validation :downcase_key, if: -> { key.present? }
  before_validation :generate_webhook_secret, on: :create, if: -> { webhook_secret.blank? }
  before_validation :fetch_bot_username, if: :should_fetch_bot_username?
  # Возвращает Telegram Bot клиент для этого тенанта
  #
  # @return [Telegram::Bot::Client] клиент бота
  alias_attribute :subdomain, :key

  def bot_client
    @bot_client ||= Telegram::Bot::Client.new(bot_token, bot_username)
  end

  def bot_id
    bot_token.split(':').to_i
  end

  # URL для dashboard тенанта
  #
  # @return [String] полный URL dashboard
  def dashboard_url
    Rails.application.routes.url_helpers.tenant_root_url(subdomain: subdomain)
  end

  # Возвращает system_prompt или дефолтное значение из конфига
  #
  # @return [String] системный промпт
  def system_prompt_or_default
    system_prompt.presence || ApplicationConfig.system_prompt
  end

  # Возвращает welcome_message или дефолтное значение из конфига
  #
  # @return [String] приветственное сообщение
  def welcome_message_or_default
    welcome_message.presence || ApplicationConfig.welcome_message_template
  end

  # Возвращает company_info или дефолтное значение из конфига
  #
  # @return [String] информация о компании
  def company_info_or_default
    company_info.presence || ApplicationConfig.company_info
  end

  # Возвращает price_list или дефолтное значение из конфига
  #
  # @return [String] прайс-лист
  def price_list_or_default
    price_list.presence || ApplicationConfig.price_list
  end

  private

  def generate_key
    alphabet = ('a'..'z').to_a + ('0'..'9').to_a
    self.key = Nanoid.generate(size: KEY_LENGTH, alphabet: alphabet)
  end

  def downcase_key
    self.key = key.downcase
  end

  def generate_webhook_secret
    self.webhook_secret = SecureRandom.hex(WEBHOOK_SECRET_LENGTH)
  end

  def should_fetch_bot_username?
    return false if bot_token.blank?
    return true if bot_username.blank?
    return false if new_record?

    bot_token_changed?
  end

  def fetch_bot_username
    client = Telegram::Bot::Client.new(bot_token)
    response = client.get_me
    self.bot_username = response.dig('result', 'username')
  rescue Telegram::Bot::Error => e
    log_error(e, context: { operation: 'fetch_bot_username', bot_token: bot_token&.first(10) })
    errors.add(:bot_token, :invalid, message: "не удалось получить информацию о боте: #{e.message}")
    throw :abort
  end
end
