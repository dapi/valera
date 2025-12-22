# frozen_string_literal: true

module Tenants
  # Контроллер авторизации через Telegram для владельцев tenant
  #
  # Обрабатывает:
  # - GET /auth/telegram/login - редирект на Platform Bot
  # - GET /auth/telegram/confirm - подтверждение авторизации
  #
  # @see TelegramAuthService для работы с токенами
  # @author Danil Pismenny
  # @since 0.2.0
  class TelegramAuthController < ApplicationController
    skip_before_action :authenticate_owner!
    layout 'tenants/auth'

    # GET /auth/telegram/login
    #
    # Генерирует auth request и редиректит на Auth Bot
    def login
      # Если уже авторизован - редирект на главную
      if current_user
        redirect_to tenant_root_path
        return
      end

      key = auth_service.create_auth_request(
        tenant_key: current_tenant.key,
        return_url: tenant_root_url
      )

      bot_url = "https://t.me/#{ApplicationConfig.platform_bot_username}?start=#{key}"
      redirect_to bot_url, allow_other_host: true
    end

    # GET /auth/telegram/confirm
    #
    # Верифицирует confirm token и создаёт сессию
    def confirm
      token = params[:token].to_s

      if token.blank?
        redirect_to new_tenant_session_path, alert: 'Неверный токен авторизации'
        return
      end

      data = auth_service.verify_confirm_token(token)

      unless data
        redirect_to new_tenant_session_path, alert: 'Токен авторизации устарел или недействителен'
        return
      end

      # Проверяем что токен для этого tenant'а
      unless data[:tenant_key] == current_tenant.key
        redirect_to new_tenant_session_path, alert: 'Токен для другого автосервиса'
        return
      end

      # Ищем TelegramUser
      telegram_user = TelegramUser.find_by(id: data[:telegram_user_id])

      unless telegram_user
        redirect_to new_tenant_session_path, alert: 'Пользователь Telegram не найден'
        return
      end

      # Ищем User по TelegramUser
      user = User.find_by(telegram_user_id: telegram_user.id)

      unless user
        redirect_to new_tenant_session_path, alert: 'Ваш Telegram не привязан к аккаунту владельца'
        return
      end

      # Проверяем что этот User - владелец текущего tenant'а
      unless user.id == current_tenant.owner_id
        redirect_to new_tenant_session_path, alert: 'Вы не являетесь владельцем этого автосервиса'
        return
      end

      # Создаём сессию
      session[:user_id] = user.id

      redirect_to tenant_root_path, notice: 'Вы успешно вошли через Telegram'
    end

    private

    def auth_service
      @auth_service ||= TelegramAuthService.new
    end
  end
end
