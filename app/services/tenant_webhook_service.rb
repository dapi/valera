# frozen_string_literal: true

# Сервис для управления Telegram webhook для тенанта
#
# Обеспечивает регистрацию и удаление webhook в Telegram API
# с использованием secret_token для верификации запросов.
#
# @example Регистрация webhook
#   service = TenantWebhookService.new(tenant, base_url: 'https://example.com')
#   result = service.setup_webhook
#   #=> { ok: true }
#
# @example Удаление webhook
#   service = TenantWebhookService.new(tenant)
#   result = service.remove_webhook
#   #=> { ok: true }
#
# @see Tenant модель тенанта с bot_token и webhook_secret
# @see https://core.telegram.org/bots/api#setwebhook Telegram setWebhook API
# @author Danil Pismenny
# @since 0.2.0
class TenantWebhookService
  include ErrorLogger

  # Ошибка при работе с Telegram API
  class TelegramApiError < StandardError; end

  # @param tenant [Tenant] тенант для которого настраивается webhook
  # @param base_url [String, nil] базовый URL для webhook (например https://example.com)
  def initialize(tenant, base_url: nil)
    @tenant = tenant
    @base_url = base_url
  end

  # Регистрирует webhook в Telegram для тенанта
  #
  # Вызывает Telegram API setWebhook с:
  # - URL вида {base_url}/telegram/webhook/{tenant.key}
  # - secret_token для верификации запросов
  #
  # @return [Hash] ответ от Telegram API
  # @raise [TelegramApiError] при ошибке вызова API
  # @raise [ArgumentError] если base_url не задан
  def setup_webhook
    raise ArgumentError, 'base_url is required for setup_webhook' if @base_url.blank?

    webhook_url = build_webhook_url

    response = bot_client.set_webhook(
      url: webhook_url,
      secret_token: tenant.webhook_secret
    )

    log_webhook_setup(response, webhook_url)
    response
  rescue Telegram::Bot::Error => e
    handle_telegram_error('setup_webhook', e)
  end

  # Удаляет webhook в Telegram для тенанта
  #
  # Вызывает Telegram API deleteWebhook.
  #
  # @return [Hash] ответ от Telegram API
  # @raise [TelegramApiError] при ошибке вызова API
  def remove_webhook
    response = bot_client.delete_webhook

    log_webhook_removal(response)
    response
  rescue Telegram::Bot::Error => e
    handle_telegram_error('remove_webhook', e)
  end

  # Получает информацию о текущем webhook
  #
  # @return [Hash] информация о webhook из Telegram API
  # @raise [TelegramApiError] при ошибке вызова API
  def webhook_info
    bot_client.get_webhook_info
  rescue Telegram::Bot::Error => e
    handle_telegram_error('webhook_info', e)
  end

  private

  attr_reader :tenant

  # Создает Telegram Bot клиент для тенанта
  #
  # @return [Telegram::Bot::Client]
  # @api private
  def bot_client
    @bot_client ||= Telegram::Bot::Client.new(tenant.bot_token, tenant.bot_username)
  end

  # Формирует URL webhook для тенанта
  #
  # @return [String] полный URL webhook
  # @api private
  def build_webhook_url
    "#{@base_url.chomp('/')}/telegram/webhook/#{tenant.key}"
  end

  # Логирует успешную настройку webhook
  #
  # @param response [Hash] ответ от Telegram API
  # @param webhook_url [String] URL webhook
  # @return [void]
  # @api private
  def log_webhook_setup(response, webhook_url)
    Rails.logger.info do
      "[TenantWebhookService] Webhook setup for tenant #{tenant.key}: " \
        "url=#{webhook_url}, response=#{response.inspect}"
    end
  end

  # Логирует удаление webhook
  #
  # @param response [Hash] ответ от Telegram API
  # @return [void]
  # @api private
  def log_webhook_removal(response)
    Rails.logger.info do
      "[TenantWebhookService] Webhook removed for tenant #{tenant.key}: " \
        "response=#{response.inspect}"
    end
  end

  # Обрабатывает ошибки Telegram API
  #
  # @param operation [String] название операции
  # @param error [Telegram::Bot::Error] ошибка от API
  # @raise [TelegramApiError] всегда поднимает исключение
  # @api private
  def handle_telegram_error(operation, error)
    log_error(error, context: { operation: operation, tenant_key: tenant.key })

    raise TelegramApiError, "#{operation} failed for tenant #{tenant.key}: #{error.message}"
  end
end
