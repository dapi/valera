# frozen_string_literal: true

Rails.application.config.telegram_updates_controller
     .session_store = :redis_cache_store, { url: ApplicationConfig.redis_cache_store_url, expires_in: 1.month }

# В multi-tenant режиме боты создаются динамически per-tenant
# Default бот не используется
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
