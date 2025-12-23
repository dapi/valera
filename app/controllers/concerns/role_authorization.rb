# frozen_string_literal: true

# Concern для авторизации по ролям в tenant dashboard
#
# Предоставляет методы для проверки прав доступа на основе роли
# пользователя (owner, admin, operator, viewer).
#
# @example Использование в контроллере
#   class Tenants::SettingsController < Tenants::ApplicationController
#     include RoleAuthorization
#
#     before_action :require_admin!
#   end
#
module RoleAuthorization
  extend ActiveSupport::Concern

  included do
    helper_method :can_view?, :can_operate?, :can_admin?, :can_manage?
  end

  # Проверяет может ли текущий пользователь просматривать данные
  # Доступно всем ролям: owner, admin, operator, viewer
  #
  # @return [Boolean]
  def can_view?
    return false unless current_user && current_tenant

    current_user_is_owner? || current_membership.present?
  end

  # Проверяет может ли текущий пользователь выполнять операции
  # (отвечать клиентам, управлять записями)
  # Доступно: owner, admin, operator
  #
  # @return [Boolean]
  def can_operate?
    return false unless current_user && current_tenant

    current_user_is_owner? || current_membership&.can_respond_to_clients?
  end

  # Проверяет может ли текущий пользователь управлять настройками
  # Доступно: owner, admin
  #
  # @return [Boolean]
  def can_admin?
    current_user_is_admin?
  end

  # Проверяет может ли текущий пользователь управлять участниками
  # Доступно: owner, admin
  #
  # @return [Boolean]
  def can_manage?
    current_user_can_manage_members?
  end

  protected

  # Требует минимум права просмотра
  def require_viewer!
    return if can_view?

    redirect_with_access_denied
  end

  # Требует минимум права оператора
  def require_operator!
    return if can_operate?

    redirect_with_access_denied
  end

  # Требует минимум права администратора
  def require_admin!
    return if can_admin?

    redirect_with_access_denied
  end

  # Требует права владельца
  def require_owner!
    return if current_user_is_owner?

    redirect_with_access_denied
  end

  private

  def redirect_with_access_denied
    redirect_to tenant_root_path, alert: 'У вас недостаточно прав для выполнения этого действия'
  end
end
