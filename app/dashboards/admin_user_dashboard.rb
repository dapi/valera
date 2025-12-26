# frozen_string_literal: true

require 'administrate/base_dashboard'

class AdminUserDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    name: Field::String,
    email: Field::Email,
    password: Field::Password,
    role: Field::Select.with_options(
      searchable: false,
      collection: ->(field) { field.resource.class.roles.keys }
    ),
    managed_tenants_count: ManagedTenantsCountField,
    managed_tenants: Field::HasMany,
    managed_leads: Field::HasMany,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    name
    email
    role
    managed_tenants_count
    created_at
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    name
    email
    role
    managed_tenants_count
    managed_tenants
    managed_leads
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    name
    email
    password
    role
  ].freeze

  COLLECTION_FILTERS = {}.freeze

  def display_resource(admin_user)
    admin_user.name.presence || admin_user.email
  end
end
