# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password validations: false

  belongs_to :telegram_user, optional: true
  has_many :owned_tenants, class_name: 'Tenant', foreign_key: :owner_id, dependent: :nullify, inverse_of: :owner
  has_many :tenant_memberships, dependent: :destroy
  has_many :member_tenants, through: :tenant_memberships, source: :tenant

  validates :email, presence: true, uniqueness: true, 'valid_email_2/email': true, unless: :telegram_only_user?
  validates :email, uniqueness: true, 'valid_email_2/email': true, allow_blank: true, if: :telegram_only_user?
  validates :name, presence: true
  validates :password, length: { minimum: 8 }, confirmation: true, if: -> { password.present? }

  # Проверяет привязан ли Telegram к аккаунту
  #
  # @return [Boolean]
  def telegram_linked?
    telegram_user_id.present?
  end

  # Возвращает все tenant'ы, к которым пользователь имеет доступ
  # (owned + memberships)
  #
  # @return [Array<Tenant>]
  def accessible_tenants
    (owned_tenants.to_a + member_tenants.to_a).uniq
  end

  # Находит membership для конкретного tenant'а
  #
  # @param tenant [Tenant]
  # @return [TenantMembership, nil]
  def membership_for(tenant)
    tenant_memberships.find_by(tenant: tenant)
  end

  # Проверяет является ли пользователь owner'ом tenant'а
  #
  # @param tenant [Tenant]
  # @return [Boolean]
  def owner_of?(tenant)
    owned_tenants.include?(tenant)
  end

  # Проверяет имеет ли пользователь доступ к tenant'у
  #
  # @param tenant [Tenant]
  # @return [Boolean]
  def has_access_to?(tenant)
    owner_of?(tenant) || membership_for(tenant).present?
  end

  # Проверяет является ли пользователь "telegram-only"
  # (зарегистрирован только через Telegram, без email)
  #
  # @return [Boolean]
  def telegram_only_user?
    telegram_user_id.present? && email.blank? && !persisted?
  end
end
