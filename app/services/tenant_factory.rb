# frozen_string_literal: true

# Фабрика для создания тенантов
#
# Обеспечивает создание нового тенанта с автоматической генерацией
# key и webhook_secret, а также опциональную регистрацию webhook.
#
# @example Создание тенанта без регистрации webhook
#   result = TenantFactory.create(
#     name: 'AutoService Pro',
#     bot_token: '123456:ABC',
#     bot_username: 'autoservice_bot'
#   )
#   result.tenant #=> Tenant
#   result.success? #=> true
#
# @example Создание тенанта с регистрацией webhook
#   result = TenantFactory.create(
#     name: 'AutoService Pro',
#     bot_token: '123456:ABC',
#     bot_username: 'autoservice_bot',
#     register_webhook: true,
#     webhook_base_url: 'https://example.com'
#   )
#
# @see Tenant модель тенанта
# @see TenantWebhookService для регистрации webhook
# @author Danil Pismenny
# @since 0.2.0
class TenantFactory
  include ErrorLogger

  # Результат создания тенанта
  Result = Data.define(:tenant, :webhook_result, :errors) do
    def success?
      errors.empty?
    end

    def failure?
      !success?
    end
  end

  # Создает нового тенанта
  #
  # @param name [String] название автосервиса
  # @param bot_token [String] токен Telegram бота
  # @param bot_username [String] username Telegram бота
  # @param owner [User, nil] владелец тенанта
  # @param register_webhook [Boolean] регистрировать ли webhook
  # @param webhook_base_url [String, nil] базовый URL для webhook
  # @param attributes [Hash] дополнительные атрибуты тенанта
  # @return [Result] результат с тенантом или ошибками
  def self.create(name:, bot_token:, bot_username:, owner: nil, register_webhook: false, webhook_base_url: nil, **attributes)
    new.create(
      name: name,
      bot_token: bot_token,
      bot_username: bot_username,
      owner: owner,
      register_webhook: register_webhook,
      webhook_base_url: webhook_base_url,
      **attributes
    )
  end

  # @see .create
  def create(name:, bot_token:, bot_username:, owner: nil, register_webhook: false, webhook_base_url: nil, **attributes)
    tenant = build_tenant(
      name: name,
      bot_token: bot_token,
      bot_username: bot_username,
      owner: owner,
      **attributes
    )

    unless tenant.save
      return Result.new(tenant: tenant, webhook_result: nil, errors: tenant.errors.full_messages)
    end

    webhook_result = nil
    if register_webhook
      webhook_result = setup_webhook(tenant, webhook_base_url)
    end

    Result.new(tenant: tenant, webhook_result: webhook_result, errors: [])
  rescue StandardError => e
    log_error(e, context: 'TenantFactory.create')
    Result.new(tenant: nil, webhook_result: nil, errors: [ e.message ])
  end

  private

  # Создает объект Tenant с заданными атрибутами
  #
  # @return [Tenant] несохраненный объект Tenant
  # @api private
  def build_tenant(name:, bot_token:, bot_username:, owner:, **attributes)
    Tenant.new(
      name: name,
      bot_token: bot_token,
      bot_username: bot_username,
      owner: owner,
      **attributes
    )
  end

  # Регистрирует webhook для тенанта
  #
  # @param tenant [Tenant] тенант
  # @param base_url [String, nil] базовый URL
  # @return [Hash, nil] результат от Telegram API
  # @api private
  def setup_webhook(tenant, base_url)
    return nil if base_url.blank?

    service = TenantWebhookService.new(tenant, base_url: base_url)
    service.setup_webhook
  rescue TenantWebhookService::TelegramApiError => e
    log_error(e, context: 'TenantFactory.setup_webhook', tenant_key: tenant.key)
    nil
  end
end
