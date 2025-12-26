# frozen_string_literal: true

require 'administrate/base_dashboard'

class ClientDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    name: Field::String,
    phone: Field::String,
    tenant: Field::BelongsTo,
    telegram_user: Field::BelongsTo,
    vehicles: Field::HasMany,
    chats: Field::HasMany,
    bookings: Field::HasMany,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    name
    phone
    tenant
    telegram_user
    created_at
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    name
    phone
    tenant
    telegram_user
    vehicles
    chats
    bookings
    created_at
    updated_at
  ].freeze

  # Read-only resource
  FORM_ATTRIBUTES = [].freeze

  COLLECTION_FILTERS = {
    tenant: ->(resources, attr) { resources.where(tenant_id: attr) }
  }.freeze

  def display_resource(client)
    client.display_name
  end
end
