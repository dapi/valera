# frozen_string_literal: true

# Приглашение участника в tenant
#
# Заменяет хранение инвайтов в Redis на персистентное хранилище.
# Позволяет:
# - Видеть список активных инвайтов
# - Отменять инвайты
# - Отслеживать историю приглашений
#
# @example Создание инвайта
#   invite = TenantInvite.create!(
#     tenant: tenant,
#     invited_by: admin_user,
#     role: :operator,
#     expires_at: 7.days.from_now
#   )
#   invite.telegram_url # => "https://t.me/bot?start=MBR_xxx"
#
# @example Принятие инвайта
#   invite = TenantInvite.active.find_by!(token: 'MBR_xxx')
#   invite.accept!(user)
#
class TenantInvite < ApplicationRecord
  belongs_to :tenant
  belongs_to :invited_by_user, class_name: 'User', optional: true
  belongs_to :invited_by_admin, class_name: 'AdminUser', optional: true
  belongs_to :accepted_by, class_name: 'User', optional: true

  enum :role, { viewer: 0, operator: 1, admin: 2 }
  enum :status, { pending: 0, accepted: 1, expired: 2, cancelled: 3 }

  validates :token, presence: true, uniqueness: true
  validates :role, presence: true
  validates :expires_at, presence: true
  validate :inviter_must_be_present

  scope :active, -> { pending.where('expires_at > ?', Time.current) }

  # Единый интерфейс для обратной совместимости
  #
  # @return [User, AdminUser, nil]
  def invited_by
    invited_by_user || invited_by_admin
  end

  # Имя пригласившего
  #
  # @return [String, nil]
  def invited_by_name
    invited_by&.name || invited_by&.email
  end

  before_validation :generate_token, on: :create

  # Принимает инвайт и связывает с пользователем
  #
  # @param user [User] пользователь, принимающий инвайт
  # @return [Boolean]
  def accept!(user)
    update!(status: :accepted, accepted_by: user, accepted_at: Time.current)
  end

  # Отменяет инвайт
  #
  # @return [Boolean]
  def cancel!
    update!(status: :cancelled, cancelled_at: Time.current)
  end

  # Проверяет истёк ли инвайт
  #
  # @return [Boolean]
  def expired?
    pending? && expires_at < Time.current
  end

  # Возвращает Telegram URL для инвайта
  #
  # @return [String]
  def telegram_url
    "https://t.me/#{ApplicationConfig.platform_bot_username}?start=#{token}"
  end

  private

  def generate_token
    self.token ||= "MBR_#{SecureRandom.urlsafe_base64(12)}"
  end

  def inviter_must_be_present
    return if invited_by_user_id.present? || invited_by_admin_id.present?

    errors.add(:base, :inviter_required, message: 'Должен быть указан пригласивший (User или AdminUser)')
  end
end
