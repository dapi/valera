# frozen_string_literal: true

# BelongsToTenant provides multi-tenancy support for models.
# Automatically scopes queries and sets tenant_id on creation.
#
# @example Basic usage
#   class Chat < ApplicationRecord
#     include BelongsToTenant
#   end
#
# @example With additional scoping
#   class Booking < ApplicationRecord
#     include BelongsToTenant
#     # Additional scopes work on top of tenant scoping
#     scope :active, -> { where(status: :active) }
#   end
#
module BelongsToTenant
  extend ActiveSupport::Concern

  included do
    belongs_to :tenant

    # Auto-assign tenant from Current on create
    before_validation :set_tenant_from_current, on: :create, if: -> { tenant_id.nil? && Current.tenant.present? }

    # Default scope to current tenant when available
    default_scope { where(tenant: Current.tenant) if Current.tenant.present? }
  end

  private

  def set_tenant_from_current
    self.tenant = Current.tenant
  end
end
