# frozen_string_literal: true

require 'administrate/base_dashboard'

class VehicleDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    brand: Field::String,
    model: Field::String,
    year: Field::Number,
    vin: Field::String,
    plate_number: Field::String,
    notes: Field::Text,
    client: Field::BelongsTo,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    brand
    model
    year
    plate_number
    client
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    brand
    model
    year
    vin
    plate_number
    notes
    client
    created_at
    updated_at
  ].freeze

  # Read-only resource
  FORM_ATTRIBUTES = [].freeze

  COLLECTION_FILTERS = {
    tenant: ->(resources, attr) { resources.joins(:client).where(clients: { tenant_id: attr }) }
  }.freeze

  def display_resource(vehicle)
    "#{vehicle.brand} #{vehicle.model}".presence || "Vehicle ##{vehicle.id}"
  end
end
