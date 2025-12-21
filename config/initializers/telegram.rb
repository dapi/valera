# frozen_string_literal: true

Rails.application.config.telegram_updates_controller
     .session_store = :redis_cache_store, { url: ApplicationConfig.redis_cache_store_url, expires_in: 1.month }

# Auth Bot - единый бот для авторизации и уведомлений владельцев
# Tenant-боты создаются динамически per-tenant через MultiTenantMiddleware
Telegram.bots_config = {
  default: {
    token: ApplicationConfig.auth_bot_token,
    username: ApplicationConfig.auth_bot_username
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
