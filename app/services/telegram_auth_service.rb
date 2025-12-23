# frozen_string_literal: true

# Сервис авторизации владельцев через Telegram Notification Bot
#
# Обеспечивает:
# - Генерацию коротких ключей для /start (лимит Telegram: 64 символа)
# - Хранение auth data в Redis с TTL
# - Генерацию и верификацию confirm токенов
# - Связывание User с TelegramUser
# - Глобальную авторизацию (без tenant_key) для главного домена
#
# @example Генерация auth request для tenant
#   service = TelegramAuthService.new
#   key = service.create_auth_request(tenant_key: 'abc123', return_url: 'https://abc123.example.com/')
#   # => "xYz123..." (22 символа)
#
# @example Генерация глобального auth request
#   service = TelegramAuthService.new
#   key = service.create_global_auth_request(return_url: 'https://example.com/login/telegram/callback')
#   # => "GLB_xYz123..." (26 символов)
#
# @example Получение auth data в боте
#   data = service.get_auth_request(key)
#   # => { tenant_key: 'abc123', return_url: '...', timestamp: 1234567890 }
#
# @author Danil Pismenny
# @since 0.2.0
class TelegramAuthService
  AUTH_REQUEST_PREFIX = 'telegram_auth:'
  GLOBAL_AUTH_PREFIX = 'telegram_global_auth:'
  INVITE_PREFIX = 'telegram_invite:'
  MEMBER_INVITE_PREFIX = 'telegram_member_invite:'

  # Создаёт auth request и возвращает короткий ключ
  #
  # @param tenant_key [String] ключ tenant'а для return URL
  # @param return_url [String] URL для возврата после авторизации
  # @return [String] короткий ключ для /start payload (22 символа)
  def create_auth_request(tenant_key:, return_url:)
    key = SecureRandom.urlsafe_base64(16)  # 22 символа, влезает в лимит 64

    Rails.cache.write(
      "#{AUTH_REQUEST_PREFIX}#{key}",
      {
        type: 'auth_request',
        tenant_key: tenant_key,
        return_url: return_url,
        timestamp: Time.current.to_i
      },
      expires_in: expiration_time
    )

    key
  end

  # Получает auth data по ключу
  #
  # @param key [String] короткий ключ из /start payload
  # @return [Hash, nil] данные авторизации или nil если не найдено/истекло
  def get_auth_request(key)
    Rails.cache.read("#{AUTH_REQUEST_PREFIX}#{key}")
  end

  # Удаляет auth request (одноразовый токен)
  #
  # @param key [String] короткий ключ
  # @return [void]
  def delete_auth_request(key)
    Rails.cache.delete("#{AUTH_REQUEST_PREFIX}#{key}")
  end

  # Генерирует confirm token для перехода на веб
  #
  # @param telegram_user_id [Integer] ID пользователя Telegram
  # @param tenant_key [String] ключ tenant'а
  # @return [String] подписанный токен
  def generate_confirm_token(telegram_user_id:, tenant_key:)
    verifier.generate(
      {
        type: 'confirm',
        telegram_user_id: telegram_user_id,
        tenant_key: tenant_key,
        timestamp: Time.current.to_i
      },
      purpose: :telegram_confirm,
      expires_in: expiration_time
    )
  end

  # Верифицирует confirm token
  #
  # @param token [String] токен для проверки
  # @return [Hash, nil] данные токена или nil если невалиден
  def verify_confirm_token(token)
    data = verifier.verify(token, purpose: :telegram_confirm)
    return nil unless data['type'] == 'confirm'

    data.symbolize_keys
  rescue ActiveSupport::MessageVerifier::InvalidSignature, ActiveSupport::MessageEncryptor::InvalidMessage
    nil
  end

  # Создаёт invite токен для нового владельца
  #
  # @param user_id [Integer] ID User'а в БД
  # @return [String] короткий ключ для /start payload
  def create_invite_token(user_id:)
    key = "INV_#{SecureRandom.urlsafe_base64(12)}"  # ~20 символов

    Rails.cache.write(
      "#{INVITE_PREFIX}#{key}",
      {
        type: 'invite',
        user_id: user_id,
        timestamp: Time.current.to_i
      },
      expires_in: 24.hours  # Invite живёт дольше
    )

    key
  end

  # Получает и удаляет invite token (одноразовый)
  #
  # @param key [String] ключ invite токена
  # @return [Hash, nil] данные invite или nil
  def consume_invite_token(key)
    cache_key = "#{INVITE_PREFIX}#{key}"
    data = Rails.cache.read(cache_key)
    Rails.cache.delete(cache_key) if data
    data
  end

  # Связывает User с TelegramUser
  #
  # @param user [User] владелец tenant'а
  # @param telegram_user [TelegramUser] пользователь Telegram
  # @return [Boolean] успешность связывания
  def link_user_to_telegram(user, telegram_user)
    return false if user.telegram_user_id.present? && user.telegram_user_id != telegram_user.id

    user.update(telegram_user_id: telegram_user.id)
  end

  # === Глобальная авторизация (без tenant_key) ===

  # Создаёт глобальный auth request для авторизации на главном домене
  #
  # @param return_url [String] URL для возврата после авторизации
  # @return [String] короткий ключ для /start payload с префиксом GLB_
  def create_global_auth_request(return_url:)
    key = "GLB_#{SecureRandom.urlsafe_base64(16)}"  # ~26 символов

    Rails.cache.write(
      "#{GLOBAL_AUTH_PREFIX}#{key}",
      {
        type: 'global_auth_request',
        return_url: return_url,
        timestamp: Time.current.to_i
      },
      expires_in: expiration_time
    )

    key
  end

  # Получает глобальный auth data по ключу
  #
  # @param key [String] короткий ключ из /start payload
  # @return [Hash, nil] данные авторизации или nil если не найдено/истекло
  def get_global_auth_request(key)
    Rails.cache.read("#{GLOBAL_AUTH_PREFIX}#{key}")
  end

  # Удаляет глобальный auth request (одноразовый токен)
  #
  # @param key [String] короткий ключ
  # @return [void]
  def delete_global_auth_request(key)
    Rails.cache.delete("#{GLOBAL_AUTH_PREFIX}#{key}")
  end

  # Генерирует глобальный confirm token для перехода на веб
  #
  # @param telegram_user_id [Integer] ID пользователя Telegram
  # @return [String] подписанный токен
  def generate_global_confirm_token(telegram_user_id:)
    verifier.generate(
      {
        type: 'global_confirm',
        telegram_user_id: telegram_user_id,
        timestamp: Time.current.to_i
      },
      purpose: :telegram_global_confirm,
      expires_in: expiration_time
    )
  end

  # Верифицирует глобальный confirm token
  #
  # @param token [String] токен для проверки
  # @return [Hash, nil] данные токена или nil если невалиден
  def verify_global_confirm_token(token)
    data = verifier.verify(token, purpose: :telegram_global_confirm)
    return nil unless data['type'] == 'global_confirm'

    data.symbolize_keys
  rescue ActiveSupport::MessageVerifier::InvalidSignature, ActiveSupport::MessageEncryptor::InvalidMessage
    nil
  end

  # Проверяет является ли ключ глобальным auth request
  #
  # @param key [String] ключ из /start payload
  # @return [Boolean]
  def global_auth_request?(key)
    key.to_s.start_with?('GLB_')
  end

  # === Member Invite (для приглашения участников в tenant) ===

  # Создаёт member invite токен для приглашения участника в tenant
  #
  # @param tenant_id [Integer] ID tenant'а
  # @param role [String, Symbol] роль участника (viewer, operator, admin)
  # @param invited_by_user_id [Integer] ID пользователя, создающего приглашение
  # @return [String] короткий ключ для /start payload с префиксом MBR_
  def create_member_invite_token(tenant_id:, role:, invited_by_user_id:)
    key = "MBR_#{SecureRandom.urlsafe_base64(12)}"

    Rails.cache.write(
      "#{MEMBER_INVITE_PREFIX}#{key}",
      {
        type: 'member_invite',
        tenant_id: tenant_id,
        role: role.to_s,
        invited_by_user_id: invited_by_user_id,
        timestamp: Time.current.to_i
      },
      expires_in: 7.days
    )

    key
  end

  # Получает и удаляет member invite token (одноразовый)
  #
  # @param key [String] ключ member invite токена
  # @return [Hash, nil] данные invite или nil
  def consume_member_invite_token(key)
    cache_key = "#{MEMBER_INVITE_PREFIX}#{key}"
    data = Rails.cache.read(cache_key)
    Rails.cache.delete(cache_key) if data
    data
  end

  # Проверяет является ли ключ member invite
  #
  # @param key [String] ключ из /start payload
  # @return [Boolean]
  def member_invite?(key)
    key.to_s.start_with?('MBR_')
  end

  private

  def verifier
    Rails.application.message_verifier(:telegram_auth)
  end

  def expiration_time
    ApplicationConfig.telegram_auth_expiration.seconds
  end
end
