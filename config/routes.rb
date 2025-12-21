# frozen_string_literal: true

Rails.application.routes.draw do
  # Admin panel with subdomain constraint
  constraints subdomain: 'admin' do
    scope module: :admin, as: :admin do
      # Authentication
      get 'login', to: 'sessions#new', as: :login
      post 'login', to: 'sessions#create'
      delete 'logout', to: 'sessions#destroy', as: :logout

      # Administrate resources
      resources :tenants
      resources :users
      resources :admin_users

      root to: 'tenants#index'
    end
  end

  # Tenant dashboard and webhook (subdomain-based routing)
  # Accessible at {tenant_key}.lvh.me (dev) or {tenant_key}.example.com (prod)
  constraints Constraints::TenantSubdomainConstraint.new do
    # Telegram webhook endpoint for this tenant
    post 'telegram/webhook',
         to: Telegram::MultiTenantMiddleware.new(Telegram::WebhookController),
         as: :tenant_telegram_webhook

    # Tenant dashboard routes
    scope module: :tenants, as: :tenant do
      resource :session, only: %i[new create destroy]
      resource :password, only: %i[new create]

      root 'home#show'

      resources :clients, only: %i[index show]
      resources :bookings, only: %i[index show]
      resource :settings, only: %i[edit update]
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get 'up' => 'rails/health#show', as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Landing page (main domain without subdomain)
  root 'landing#show'
  post 'leads', to: 'landing#create_lead', as: :leads
end
