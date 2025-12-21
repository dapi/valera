# frozen_string_literal: true

require 'administrate/base_dashboard'

class UserDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    email: Field::Email,
    name: Field::String,
    owned_tenants: Field::HasMany,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    name
    email
    owned_tenants
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    name
    email
    owned_tenants
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    name
    email
  ].freeze

  COLLECTION_FILTERS = {}.freeze

  def display_resource(user)
    user.name.presence || user.email
  end
end
