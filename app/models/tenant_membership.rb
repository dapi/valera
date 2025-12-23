# frozen_string_literal: true

# Связь пользователя с tenant'ом с определённой ролью
#
# @example Создание membership
#   TenantMembership.create!(
#     tenant: tenant,
#     user: user,
#     role: :operator,
#     invited_by: admin_user
#   )
#
# @example Проверка прав
#   membership.admin? # => true
#   membership.can_manage_members? # => true
#
class TenantMembership < ApplicationRecord
  belongs_to :tenant
  belongs_to :user
  belongs_to :invited_by, class_name: 'User', optional: true

  enum :role, { viewer: 0, operator: 1, admin: 2 }

  validates :user_id, uniqueness: { scope: :tenant_id }
  validates :role, presence: true

  # Проверяет может ли пользователь отвечать клиентам
  #
  # @return [Boolean]
  def can_respond_to_clients?
    operator? || admin?
  end

  # Проверяет может ли пользователь управлять настройками
  #
  # @return [Boolean]
  def can_manage_settings?
    admin?
  end

  # Проверяет может ли пользователь управлять участниками
  #
  # @return [Boolean]
  def can_manage_members?
    admin?
  end
end
