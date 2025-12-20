# frozen_string_literal: true

Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Multi-tenant webhook endpoint
  # Each tenant has their own webhook URL: /telegram/webhook/:tenant_key
  # Uses Middleware instead of Controller for better integration with telegram-bot-rb gem
  post 'telegram/webhook/:tenant_key',
       to: Telegram::MultiTenantMiddleware.new(Telegram::WebhookController),
       as: :tenant_telegram_webhook

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get 'up' => 'rails/health#show', as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
