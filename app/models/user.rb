# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password validations: false

  belongs_to :telegram_user, optional: true
  has_many :owned_tenants, class_name: 'Tenant', foreign_key: :owner_id, dependent: :nullify, inverse_of: :owner

  validates :email, presence: true, uniqueness: true, 'valid_email_2/email': true
  validates :name, presence: true
  validates :password, length: { minimum: 8 }, confirmation: true, if: -> { password.present? }

  # Проверяет привязан ли Telegram к аккаунту
  #
  # @return [Boolean]
  def telegram_linked?
    telegram_user_id.present?
  end
end
