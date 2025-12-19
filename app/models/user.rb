# frozen_string_literal: true

class User < ApplicationRecord
  has_many :owned_tenants, class_name: 'Tenant', foreign_key: :owner_id, dependent: :nullify, inverse_of: :owner

  validates :email, presence: true, uniqueness: true
  validates :name, presence: true
end
