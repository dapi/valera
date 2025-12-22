# frozen_string_literal: true

require 'administrate/base_dashboard'

class LeadDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    name: Field::String,
    phone: Field::String,
    company_name: Field::String,
    city: Field::String,
    source: Field::String,
    utm_source: Field::String,
    utm_medium: Field::String,
    utm_campaign: Field::String,
    manager: Field::BelongsTo.with_options(class_name: 'AdminUser'),
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    name
    phone
    company_name
    manager
    created_at
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    name
    phone
    company_name
    city
    source
    utm_source
    utm_medium
    utm_campaign
    manager
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    name
    phone
    company_name
    city
    manager
  ].freeze

  COLLECTION_FILTERS = {}.freeze

  def display_resource(lead)
    "#{lead.name} (#{lead.phone})"
  end
end
