# frozen_string_literal: true

Rails.application.routes.draw do
  # Platform Bot webhook (единый бот для авторизации и системных уведомлений платформы)
  # Доступен на любом домене без subdomain constraint
  telegram_webhook Telegram::PlatformBotController, :default

  # Admin panel with subdomain constraint
  constraints subdomain: 'admin' do
    scope module: :admin, as: :admin do
      # Authentication
      get 'login', to: 'sessions#new', as: :login
      post 'login', to: 'sessions#create'
      delete 'logout', to: 'sessions#destroy', as: :logout

      # Administrate resources
      resources :tenants do
        # Telegram webhook management (singular resource)
        resource :webhook, only: %i[show create destroy], module: :tenants
      end
      resources :users
      resources :admin_users do
        post :impersonate, on: :member, to: 'impersonations#create'
      end
      delete :stop_impersonating, to: 'impersonations#destroy', as: :stop_impersonating
      resources :leads
      resources :telegram_users, only: %i[index show]
      resources :tenant_memberships
      resources :tenant_invites, only: %i[index show new create destroy]
      resources :clients, only: %i[index show]
      resources :chats, only: %i[index show]
      resources :vehicles, only: %i[index show]
      resources :bookings, only: %i[index show]

      # GoodJob dashboard - background jobs monitoring
      mount GoodJob::Engine, at: '/jobs'

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

      # Cross-domain auth token endpoint
      get 'auth/token', to: 'token_auth#show', as: :auth_token

      # Telegram auth routes
      scope :auth, as: :auth do
        get 'telegram/login', to: 'telegram_auth#login', as: :telegram_login
        get 'telegram/confirm', to: 'telegram_auth#confirm', as: :telegram_confirm
      end

      root 'home#show'

      resources :clients, only: %i[index show]
      resources :bookings, only: %i[index show]
      resources :members, only: %i[index create update destroy] do
        collection do
          get :invite
          delete 'invites/:id', action: :cancel_invite, as: :cancel_invite
        end
      end
      resource :settings, only: %i[edit update]
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get 'up' => 'rails/health#show', as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Universal auth on main domain (no subdomain)
  scope :login, controller: :auth do
    get '/', action: :new, as: :login
    post '/', action: :create
    delete '/', action: :destroy, as: :logout

    get 'select', action: :select, as: :select_tenant
    post 'select', action: :switch_tenant

    # Telegram auth via Platform Bot
    get 'telegram', action: :telegram_login, as: :login_telegram
    get 'telegram/callback', action: :telegram_callback, as: :login_telegram_callback
  end

  # Landing page (main domain without subdomain)
  root 'landing#show'
  get 'price', to: 'landing#price'
  get 'lp1', to: 'landing#lp1'
  get 'lp2', to: 'landing#lp2'
  post 'leads', to: 'landing#create_lead', as: :leads
end
