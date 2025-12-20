# frozen_string_literal: true

module Telegram
  # Middleware для обработки multi-tenant webhook запросов от Telegram
  #
  # Определяет tenant по ключу из URL, верифицирует webhook secret,
  # и передаёт обработку в WebhookController.
  #
  # Преимущества перед контроллером:
  # - Более идиоматичен для gem telegram-bot-rb
  # - Работает на уровне Rack без overhead Rails контроллера
  # - Лучшая интеграция с фичами gem (UpdatesPoller, Async, instrumentation)
  #
  # @example Использование в routes.rb
  #   post 'telegram/webhook/:tenant_key',
  #        to: Telegram::MultiTenantMiddleware.new(WebhookController)
  #
  # @see Tenant для модели тенанта
  # @see TenantWebhookService для регистрации webhook
  # @see WebhookController для обработки сообщений
  # @author Danil Pismenny
  # @since 0.3.0
  class MultiTenantMiddleware
    include ErrorLogger

    # Исключение для неавторизованного доступа
    class UnauthorizedError < StandardError; end

    attr_reader :controller

    # @param controller [Class] класс контроллера для обработки webhook
    def initialize(controller)
      @controller = controller
    end

    # Обрабатывает входящий Rack запрос
    #
    # @param env [Hash] Rack environment
    # @return [Array] Rack response [status, headers, body]
    def call(env)
      request = ActionDispatch::Request.new(env)
      tenant_key = extract_tenant_key(env)
      tenant = Tenant.find_by!(key: tenant_key)

      verify_webhook_secret!(request, tenant)
      Current.tenant = tenant

      update = request.request_parameters
      bot = Rails.env.test? ? Telegram.bot : tenant.bot_client
      controller.dispatch(bot, update, request)

      [ 200, {}, [ '' ] ]
    rescue ActiveRecord::RecordNotFound => e
      log_error(e, service: self.class.name, tenant_key: tenant_key, ip: request.remote_ip)
      [ 404, { 'Content-Type' => 'text/plain' }, [ 'Tenant not found' ] ]
    rescue UnauthorizedError => e
      log_error(e, service: self.class.name, tenant_key: tenant_key, ip: request.remote_ip)
      [ 401, { 'Content-Type' => 'text/plain' }, [ 'Unauthorized' ] ]
    end

    # Возвращает читаемое представление для логов и отладки
    #
    # @return [String]
    def inspect
      "#<#{self.class.name}(#{controller&.name})>"
    end

    private

    # Извлекает tenant_key из URL path parameters
    #
    # @param env [Hash] Rack environment
    # @return [String] ключ тенанта
    def extract_tenant_key(env)
      env['action_dispatch.request.path_parameters'][:tenant_key]
    end

    # Верифицирует X-Telegram-Bot-Api-Secret-Token заголовок
    #
    # Telegram присылает этот заголовок при каждом webhook запросе,
    # если secret_token был указан при регистрации webhook.
    # Сравнение выполняется в constant-time для защиты от timing attacks.
    #
    # @param request [ActionDispatch::Request]
    # @param tenant [Tenant]
    # @raise [UnauthorizedError] если токен невалиден или отсутствует
    # @see https://core.telegram.org/bots/api#setwebhook
    def verify_webhook_secret!(request, tenant)
      provided_secret = request.headers['X-Telegram-Bot-Api-Secret-Token'].to_s

      return if ActiveSupport::SecurityUtils.secure_compare(provided_secret, tenant.webhook_secret)

      raise UnauthorizedError
    end
  end
end
