# frozen_string_literal: true

# Контроллер для обработки multi-tenant webhook запросов от Telegram
#
# Принимает входящие обновления от Telegram Bot API с динамической маршрутизацией
# по tenant_key. Обеспечивает изоляцию данных между тенантами.
#
# @example Обработка запроса
#   # POST /telegram/webhook/:tenant_key
#   # Header: X-Telegram-Bot-Api-Secret-Token: <webhook_secret>
#   # {"message": {"text": "Хочу записаться на ТО", "chat": {"id": 123}}}
#
# @see Tenant для модели тенанта
# @see TenantWebhookService для регистрации webhook
# @see WebhookController для обработки сообщений
# @author Danil Pismenny
# @since 0.2.0
module Telegram
  class MultiTenantWebhookController < ActionController::API
    include ErrorLogger

    before_action :find_tenant
    before_action :verify_webhook_secret
    before_action :set_current_tenant

    # Обрабатывает входящий webhook запрос от Telegram
    #
    # Создает динамический Telegram::Bot::Client для тенанта
    # и передает обработку в существующий WebhookController.
    #
    # @return [void] Возвращает пустой ответ с кодом 200
    # @raise [ActiveRecord::RecordNotFound] если тенант не найден
    # @raise [ActionController::BadRequest] если secret невалиден
    def create
      bot = build_bot_client
      update = request.request_parameters

      WebhookController.dispatch(bot, update, request)

      head :ok
    end

    private

    attr_reader :tenant

    # Находит тенант по ключу из URL
    #
    # @return [void]
    # @raise [ActiveRecord::RecordNotFound] если тенант не найден
    # @api private
    def find_tenant
      @tenant = Tenant.find_by!(key: params[:tenant_key])
    end

    # Верифицирует X-Telegram-Bot-Api-Secret-Token заголовок
    #
    # Telegram присылает этот заголовок при каждом webhook запросе,
    # если secret_token был указан при регистрации webhook.
    # Сравнение выполняется в constant-time для защиты от timing attacks.
    #
    # @return [void]
    # @raise [ActionController::BadRequest] если токен невалиден или отсутствует
    # @see https://core.telegram.org/bots/api#setwebhook
    # @api private
    def verify_webhook_secret
      provided_secret = request.headers['X-Telegram-Bot-Api-Secret-Token']

      unless ActiveSupport::SecurityUtils.secure_compare(
        provided_secret.to_s,
        tenant.webhook_secret
      )
        log_unauthorized_webhook_attempt
        head :unauthorized
      end
    end

    # Устанавливает текущий тенант для request scope
    #
    # @return [void]
    # @api private
    def set_current_tenant
      Current.tenant = tenant
    end

    # Создает Telegram::Bot::Client для текущего тенанта
    #
    # В тестовой среде использует глобальный Telegram.bot (stub)
    # для корректной работы с Telegram::Bot::ClientStub.
    #
    # @return [Telegram::Bot::Client] клиент с токеном тенанта
    # @api private
    def build_bot_client
      return Telegram.bot if Rails.env.test?

      Telegram::Bot::Client.new(tenant.bot_token, tenant.bot_username)
    end

    # Логирует попытку неавторизованного доступа к webhook
    #
    # @return [void]
    # @api private
    def log_unauthorized_webhook_attempt
      Rails.logger.warn do
        "[MultiTenantWebhook] Unauthorized attempt for tenant: #{tenant.key}, " \
          "IP: #{request.remote_ip}"
      end
    end
  end
end
