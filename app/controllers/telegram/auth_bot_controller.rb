# frozen_string_literal: true

# Контроллер для обработки webhook Auth Bot
#
# Обрабатывает команду /start с payload для авторизации владельцев:
# - /start KEY - авторизация существующего владельца
# - /start INV_KEY - привязка Telegram к новому владельцу (invite flow)
# - /start (без payload) - информационное сообщение
#
# @see TelegramAuthService для работы с токенами
# @author Danil Pismenny
# @since 0.2.0
module Telegram
  class AuthBotController < Telegram::Bot::UpdatesController
    include ErrorLogger

    # Обработчик команды /start
    #
    # @param payload [String] ключ авторизации или invite токен
    # @return [void]
    def start!(payload = nil)
      if payload.blank?
        handle_empty_start
      elsif payload.start_with?('INV_')
        handle_invite(payload)
      else
        handle_auth_request(payload)
      end
    rescue StandardError => e
      log_error(e, context: { controller: 'AuthBotController', method: 'start!', payload: payload })
      respond_with :message, text: 'Произошла ошибка. Попробуйте позже.'
    end

    private

    # Обработка /start без payload
    def handle_empty_start
      respond_with :message, text: <<~TEXT
        👋 Это бот для авторизации владельцев автосервисов в Valera.

        Для входа в панель управления используйте кнопку "Войти через Telegram" на странице входа вашего автосервиса.

        Если вы новый владелец - обратитесь к администратору для получения приглашения.
      TEXT
    end

    # Обработка auth request от веб-страницы
    #
    # @param key [String] короткий ключ из Redis
    def handle_auth_request(key)
      auth_data = auth_service.get_auth_request(key)

      unless auth_data
        respond_with :message, text: '❌ Ссылка для авторизации устарела или недействительна. Попробуйте войти заново.'
        return
      end

      telegram_user = find_or_create_telegram_user
      user = find_user_by_telegram(telegram_user)

      unless user
        respond_with :message, text: <<~TEXT
          ❌ Ваш Telegram не привязан к аккаунту владельца.

          Если вы новый владелец - обратитесь к администратору для получения приглашения.
        TEXT
        return
      end

      # Удаляем использованный ключ
      auth_service.delete_auth_request(key)

      # Генерируем confirm token
      confirm_token = auth_service.generate_confirm_token(
        telegram_user_id: telegram_user.id,
        tenant_key: auth_data[:tenant_key] || auth_data['tenant_key']
      )

      return_url = auth_data[:return_url] || auth_data['return_url']
      confirm_url = build_confirm_url(return_url, confirm_token)

      respond_with :message,
                   text: "✅ Авторизация подтверждена!\n\nНажмите на ссылку для входа:\n#{confirm_url}\n\n⏱ Ссылка действительна 5 минут.",
                   reply_markup: {
                     inline_keyboard: [
                       [ { text: '🔐 Войти в панель управления', url: confirm_url } ]
                     ]
                   }
    end

    # Обработка invite токена для нового владельца
    #
    # @param key [String] invite ключ (INV_...)
    def handle_invite(key)
      invite_data = auth_service.consume_invite_token(key)

      unless invite_data
        respond_with :message, text: '❌ Приглашение устарело или уже использовано.'
        return
      end

      user_id = invite_data[:user_id] || invite_data['user_id']
      user = User.find_by(id: user_id)

      unless user
        respond_with :message, text: '❌ Пользователь не найден.'
        return
      end

      telegram_user = find_or_create_telegram_user

      if auth_service.link_user_to_telegram(user, telegram_user)
        respond_with :message, text: <<~TEXT
          ✅ Ваш Telegram успешно привязан к аккаунту!

          Теперь вы можете входить в панель управления через Telegram.

          Для входа используйте кнопку "Войти через Telegram" на странице вашего автосервиса.
        TEXT
      else
        respond_with :message, text: '❌ Не удалось привязать Telegram. Возможно, этот аккаунт уже привязан к другому Telegram.'
      end
    end

    # Находит или создаёт TelegramUser из данных update
    #
    # @return [TelegramUser]
    def find_or_create_telegram_user
      from_data = payload.dig('message', 'from') || from
      TelegramUser.find_or_create_by_telegram_data!(from_data)
    end

    # Ищет User по привязанному TelegramUser
    #
    # @param telegram_user [TelegramUser]
    # @return [User, nil]
    def find_user_by_telegram(telegram_user)
      User.find_by(telegram_user_id: telegram_user.id)
    end

    # Строит URL для подтверждения авторизации
    #
    # @param return_url [String] базовый URL
    # @param token [String] confirm token
    # @return [String]
    def build_confirm_url(return_url, token)
      uri = URI.parse(return_url)
      uri.path = '/auth/telegram/confirm'
      uri.query = "token=#{CGI.escape(token)}"
      uri.to_s
    end

    def auth_service
      @auth_service ||= TelegramAuthService.new
    end
  end
end
