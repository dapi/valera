# frozen_string_literal: true

require 'administrate/base_dashboard'

class BookingDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    tenant: Field::BelongsTo,
    client: Field::BelongsTo,
    vehicle: Field::BelongsTo,
    chat: Field::BelongsTo,
    details: Field::Text,
    context: Field::Text,
    meta: Field::String.with_options(searchable: false),
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    tenant
    client
    vehicle
    created_at
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    tenant
    client
    vehicle
    chat
    details
    context
    meta
    created_at
    updated_at
  ].freeze

  # Read-only resource
  FORM_ATTRIBUTES = [].freeze

  COLLECTION_FILTERS = {
    tenant: ->(resources, attr) { resources.where(tenant_id: attr) }
  }.freeze

  def display_resource(booking)
    "Booking ##{booking.id}"
  end
end
