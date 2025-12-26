# frozen_string_literal: true

require 'administrate/base_dashboard'

class UserDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    email: Field::Email,
    name: Field::String,
    telegram_user: Field::BelongsTo,
    owned_tenants: Field::HasMany,
    tenant_memberships: Field::HasMany,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    name
    email
    telegram_user
    owned_tenants
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    name
    email
    telegram_user
    owned_tenants
    tenant_memberships
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    name
    email
    telegram_user
  ].freeze

  COLLECTION_FILTERS = {}.freeze

  def display_resource(user)
    name = user.name.presence || user.email
    "##{user.id} #{name}"
  end
end
