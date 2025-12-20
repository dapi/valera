# frozen_string_literal: true

# Сервис для нахождения или создания Client по TelegramUser и Tenant
#
# Обеспечивает связь между Telegram пользователем и конкретным автосервисом (tenant).
# Один TelegramUser может быть клиентом нескольких автосервисов.
#
# @example Нахождение или создание клиента
#   resolver = ClientResolver.new(tenant: tenant, telegram_user: telegram_user)
#   client = resolver.resolve
#   #=> Client (существующий или новый)
#
# @example Использование через класс-метод
#   client = ClientResolver.resolve(tenant: tenant, telegram_user: telegram_user)
#
# @see Client модель клиента
# @see TelegramUser модель Telegram пользователя
# @see Tenant модель тенанта
# @author Danil Pismenny
# @since 0.2.0
class ClientResolver
  # @param tenant [Tenant] тенант (автосервис)
  # @param telegram_user [TelegramUser] Telegram пользователь
  def initialize(tenant:, telegram_user:)
    @tenant = tenant
    @telegram_user = telegram_user
  end

  # Находит или создает клиента
  #
  # @param tenant [Tenant] тенант
  # @param telegram_user [TelegramUser] Telegram пользователь
  # @return [Client] найденный или созданный клиент
  def self.resolve(tenant:, telegram_user:)
    new(tenant: tenant, telegram_user: telegram_user).resolve
  end

  # Находит существующего клиента или создает нового
  #
  # @return [Client] клиент для данной пары tenant + telegram_user
  # @raise [ActiveRecord::RecordInvalid] при ошибке создания клиента
  def resolve
    find_existing_client || create_client
  end

  # Находит клиента без создания
  #
  # @return [Client, nil] существующий клиент или nil
  def find
    find_existing_client
  end

  # Проверяет существует ли клиент
  #
  # @return [Boolean] true если клиент существует
  def exists?
    find_existing_client.present?
  end

  private

  attr_reader :tenant, :telegram_user

  # Ищет существующего клиента по tenant и telegram_user
  #
  # @return [Client, nil] найденный клиент или nil
  # @api private
  def find_existing_client
    @find_existing_client ||= tenant.clients.find_by(telegram_user: telegram_user)
  end

  # Создает нового клиента
  #
  # @return [Client] созданный клиент
  # @api private
  def create_client
    tenant.clients.create!(
      telegram_user: telegram_user,
      name: telegram_user.name
    )
  end
end
