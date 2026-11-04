# frozen_string_literal: true

module Telegram
  # Applied to every bot client, including per-tenant clients and token validation.
  # HTTPClient uses HTTP CONNECT for HTTPS; other application traffic is unaffected.
  module ClientTransport
    def initialize(...)
      super
      proxy = ApplicationConfig.telegram_api_proxy_url.presence
      client.proxy = proxy if proxy
      client.connect_timeout = 10
      client.send_timeout = 30
      client.receive_timeout = 30
    end
  end
end
