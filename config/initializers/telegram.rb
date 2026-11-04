# frozen_string_literal: true

require Rails.root.join('lib/telegram/client_transport')
require Rails.root.join('lib/telegram/response_errors')
Telegram::Bot::Client.prepend(Telegram::ClientTransport)
Telegram::Bot::Client.singleton_class.prepend(Telegram::ResponseErrors)

Rails.application.config.telegram_updates_controller
     .session_store = :redis_cache_store, { url: ApplicationConfig.redis_cache_store_url, expires_in: 1.month }

# Platform Bot - единый бот для авторизации и системных уведомлений платформы
# Tenant-боты создаются динамически per-tenant через MultiTenantMiddleware
Telegram.bots_config = {
  default: {
    token: ApplicationConfig.platform_bot_token,
    username: ApplicationConfig.platform_bot_username
  }
}

if Rails.env.test?
  Telegram.reset_bots
  Telegram::Bot::ClientStub.stub_all!
  Telegram.bots_config = {
    default: {
      token: '123:fake',
      username: 'fakebot'
    }
  }
end
