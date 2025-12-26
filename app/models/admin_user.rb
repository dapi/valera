# frozen_string_literal: true

class AdminUser < ApplicationRecord
  has_secure_password
  has_many :managed_leads, class_name: 'Lead', foreign_key: :manager_id, dependent: :nullify, inverse_of: :manager
  has_many :managed_tenants, class_name: 'Tenant', foreign_key: :manager_id, dependent: :nullify, inverse_of: :manager

  enum :role, { manager: 0, superuser: 1 }, default: :manager

  validates :email, presence: true, uniqueness: true, 'valid_email_2/email': true
  validates :role, presence: true
end
