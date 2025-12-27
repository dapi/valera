# frozen_string_literal: true

# Контроллер для обработки webhook Platform Bot
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
  class PlatformBotController < Telegram::Bot::UpdatesController
    include ErrorLogger

    # Обработчик команды /start
    #
    # @param payload [String] ключ авторизации или invite токен
    # @return [void]
    def start!(payload = nil)
      if payload.blank?
        handle_empty_start
      elsif payload.start_with?('MBR_')
        handle_member_invite(payload)
      elsif payload.start_with?('INV_')
        handle_invite(payload)
      elsif payload.start_with?('GLB_')
        handle_global_auth_request(payload)
      else
        handle_auth_request(payload)
      end
    rescue StandardError => e
      log_error(e, context: { controller: 'PlatformBotController', method: 'start!', payload: payload })
      respond_with :message, text: I18n.t('platform_bot.errors.generic')
    end

    # Обработчик добавления новых участников в группу
    # Telegram присылает это событие когда бот добавляется в группу
    #
    # @param message [Hash] сообщение с данными о новых участниках
    # @return [void]
    def new_chat_members(message)
      chat_id = message.dig('chat', 'id')
      new_members = message['new_chat_members']

      # Проверяем что добавлен наш бот
      bot_added = new_members&.any? do |member|
        member['is_bot'] && member['id'] == ApplicationConfig.platform_bot_id
      end
      return unless bot_added

      if ApplicationConfig.platform_admin_chat_id.blank?
        # Подсказываем как настроить
        respond_with :message, text: I18n.t('platform_bot.group.added', chat_id: chat_id)
      elsif chat_id.to_s != ApplicationConfig.platform_admin_chat_id.to_s
        # Не админская группа — молчим, но логируем
        Rails.logger.warn("[PlatformBot] Added to non-admin group: #{chat_id}")
      end
    end

    # Обработчик сообщений
    #
    # - В личных чатах: отвечает про неизвестную команду
    # - В группах без admin_chat_id: предупреждает о настройке
    # - В админской группе: отвечает только при reply/mention
    #
    # @param message [Hash] сообщение
    # @return [void]
    def message(message)
      chat_id = message.dig('chat', 'id')
      chat_type = message.dig('chat', 'type')

      # Личные сообщения — отвечаем про неизвестную команду
      if chat_type == 'private'
        respond_with :message, text: I18n.t('platform_bot.messages.unknown_command').strip
        return
      end

      # Группа без настроенного admin_chat_id
      if ApplicationConfig.platform_admin_chat_id.blank?
        Rails.logger.info("[PlatformBot] Message in group without admin_chat_id: #{chat_id}")
        respond_with :message, text: I18n.t('platform_bot.messages.bot_not_configured')
        return
      end

      # Админская группа — отвечаем только при обращении к боту
      if chat_id.to_s == ApplicationConfig.platform_admin_chat_id.to_s
        return unless message_addressed_to_bot?(message)

        respond_with :message, text: I18n.t('platform_bot.messages.group_reply')
        return
      end

      # Не админская группа — молчим, но логируем
      Rails.logger.warn("[PlatformBot] Message in non-admin group: #{chat_id}")
    end

    private

    # Проверяет, адресовано ли сообщение боту (reply или @mention)
    #
    # @param message [Hash] сообщение от Telegram
    # @return [Boolean] true если сообщение адресовано боту
    def message_addressed_to_bot?(message)
      # Reply на сообщение бота
      reply_to = message.dig('reply_to_message', 'from')
      if reply_to && reply_to['is_bot'] && reply_to['id'] == ApplicationConfig.platform_bot_id
        return true
      end

      # @mention бота
      text = message['text'] || ''
      bot_username = ApplicationConfig.platform_bot_username
      if bot_username.present? && text.include?("@#{bot_username}")
        return true
      end

      false
    end

    # Обработка /start без payload
    def handle_empty_start
      respond_with :message, text: I18n.t('platform_bot.messages.empty_start')
    end

    # Обработка auth request от веб-страницы
    #
    # @param key [String] короткий ключ из Redis
    def handle_auth_request(key)
      auth_data = auth_service.get_auth_request(key)

      unless auth_data
        respond_with :message, text: I18n.t('platform_bot.errors.link_expired')
        return
      end

      telegram_user = find_or_create_telegram_user
      user = find_user_by_telegram(telegram_user)

      unless user
        respond_with :message, text: I18n.t('platform_bot.errors.not_linked')
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
                   text: I18n.t('platform_bot.messages.auth_confirmed', confirm_url: confirm_url),
                   reply_markup: {
                     inline_keyboard: [
                       [ { text: I18n.t('platform_bot.messages.login_button'), url: confirm_url } ]
                     ]
                   }
    end

    # Обработка глобального auth request (для главного домена)
    #
    # @param key [String] глобальный ключ (GLB_...)
    def handle_global_auth_request(key)
      auth_data = auth_service.get_global_auth_request(key)

      unless auth_data
        respond_with :message, text: I18n.t('platform_bot.errors.link_expired')
        return
      end

      telegram_user = find_or_create_telegram_user
      user = find_user_by_telegram(telegram_user)

      unless user
        respond_with :message, text: I18n.t('platform_bot.errors.not_linked')
        return
      end

      # Удаляем использованный ключ
      auth_service.delete_global_auth_request(key)

      # Генерируем глобальный confirm token
      confirm_token = auth_service.generate_global_confirm_token(
        telegram_user_id: telegram_user.id
      )

      return_url = auth_data[:return_url] || auth_data['return_url']
      confirm_url = build_global_confirm_url(return_url, confirm_token)

      respond_with :message,
                   text: I18n.t('platform_bot.messages.auth_confirmed', confirm_url: confirm_url),
                   reply_markup: {
                     inline_keyboard: [
                       [ { text: I18n.t('platform_bot.messages.login_personal_button'), url: confirm_url } ]
                     ]
                   }
    end

    # Обработка member invite токена для добавления участника в tenant
    #
    # @param key [String] member invite ключ (MBR_...)
    def handle_member_invite(key)
      invite = TenantInvite.active.find_by(token: key)

      unless invite
        respond_with :message, text: I18n.t('platform_bot.errors.invite_expired')
        return
      end

      tenant = invite.tenant

      telegram_user = find_or_create_telegram_user
      user = find_or_create_user_by_telegram(telegram_user)

      # Проверяем не является ли пользователь уже владельцем
      if tenant.owner_id == user.id
        respond_with :message, text: I18n.t('platform_bot.messages.already_owner')
        return
      end

      # Проверяем не существует ли уже membership
      existing_membership = TenantMembership.find_by(tenant: tenant, user: user)
      if existing_membership
        respond_with :message, text: I18n.t('platform_bot.messages.already_member', role: role_display_name(existing_membership.role))
        return
      end

      # Создаём membership и принимаем инвайт атомарно
      became_owner = false
      ActiveRecord::Base.transaction do
        # Если у tenant нет владельца, назначаем первого приглашённого пользователя владельцем
        if tenant.owner_id.nil?
          tenant.update!(owner: user)
          became_owner = true
          Rails.logger.info("[TenantOwnership] User #{user.id} became owner of tenant #{tenant.id} via invite #{invite.id}")
        end

        TenantMembership.create!(
          tenant: tenant,
          user: user,
          role: invite.role,
          invited_by_id: invite.invited_by_user_id
        )
        invite.accept!(user)
      end

      if became_owner
        respond_with :message, text: I18n.t('platform_bot.messages.became_owner', tenant_name: tenant.name)
      else
        respond_with :message, text: I18n.t('platform_bot.messages.member_added', tenant_name: tenant.name, role: role_display_name(invite.role))
      end
    rescue ActiveRecord::RecordInvalid
      respond_with :message, text: I18n.t('platform_bot.errors.membership_failed')
    end

    # Обработка invite токена для нового владельца
    #
    # @param key [String] invite ключ (INV_...)
    def handle_invite(key)
      invite_data = auth_service.consume_invite_token(key)

      unless invite_data
        respond_with :message, text: I18n.t('platform_bot.errors.invite_expired')
        return
      end

      user_id = invite_data[:user_id] || invite_data['user_id']
      user = User.find_by(id: user_id)

      unless user
        respond_with :message, text: I18n.t('platform_bot.errors.user_not_found')
        return
      end

      telegram_user = find_or_create_telegram_user

      if auth_service.link_user_to_telegram(user, telegram_user)
        respond_with :message, text: I18n.t('platform_bot.messages.link_success')
      else
        respond_with :message, text: I18n.t('platform_bot.errors.link_failed')
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

    # Находит или создаёт User по TelegramUser
    # Для member invite нужно создавать нового пользователя если его нет
    #
    # @param telegram_user [TelegramUser]
    # @return [User]
    def find_or_create_user_by_telegram(telegram_user)
      user = User.find_by(telegram_user_id: telegram_user.id)
      return user if user

      User.create!(
        name: telegram_user.full_name.presence || "User #{telegram_user.telegram_id}",
        telegram_user_id: telegram_user.id
      )
    end

    # Возвращает человекочитаемое название роли
    #
    # @param role [String, Symbol]
    # @return [String]
    def role_display_name(role)
      I18n.t("platform_bot.roles.#{role}", default: role.to_s)
    end

    # Строит URL для подтверждения авторизации на tenant
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

    # Строит URL для глобального подтверждения авторизации
    #
    # @param return_url [String] callback URL
    # @param token [String] confirm token
    # @return [String]
    def build_global_confirm_url(return_url, token)
      uri = URI.parse(return_url)
      uri.query = "token=#{CGI.escape(token)}"
      uri.to_s
    end

    def auth_service
      @auth_service ||= TelegramAuthService.new
    end
  end
end
