# frozen_string_literal: true

require 'administrate/base_dashboard'

class ChatDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    tenant: Field::BelongsTo,
    client: Field::BelongsTo,
    bookings_count: Field::Number,
    first_booking_at: Field::DateTime,
    last_booking_at: Field::DateTime,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    tenant
    client
    bookings_count
    last_booking_at
    created_at
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    tenant
    client
    bookings_count
    first_booking_at
    last_booking_at
    created_at
    updated_at
  ].freeze

  # Read-only resource
  FORM_ATTRIBUTES = [].freeze

  COLLECTION_FILTERS = {
    tenant: ->(resources, attr) { resources.where(tenant_id: attr) },
    tenant_id: ->(resources, attr) { resources.where(tenant_id: attr) },
    has_bookings: ->(resources, attr) {
      attr == 'true' ? resources.where('bookings_count > 0') : resources.where(bookings_count: 0)
    }
  }.freeze

  def display_resource(chat)
    "Chat ##{chat.id}"
  end
end
