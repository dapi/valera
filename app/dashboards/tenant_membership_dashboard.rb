# frozen_string_literal: true

require 'administrate/base_dashboard'

class TenantMembershipDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    tenant: Field::BelongsTo,
    user: Field::BelongsTo,
    invited_by: Field::BelongsTo.with_options(class_name: 'User'),
    role: Field::Select.with_options(searchable: false, collection: ->(field) { field.resource.class.roles.keys }),
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    tenant
    user
    role
    created_at
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    tenant
    user
    invited_by
    role
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    tenant
    user
    invited_by
    role
  ].freeze

  COLLECTION_FILTERS = {}.freeze

  def display_resource(tenant_membership)
    "#{tenant_membership.user&.name || 'User'} @ #{tenant_membership.tenant&.name || 'Tenant'}"
  end
end
