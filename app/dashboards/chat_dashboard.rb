# frozen_string_literal: true

require 'administrate/base_dashboard'

class ChatDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    tenant: Field::BelongsTo,
    client: Field::BelongsTo,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    tenant
    client
    created_at
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    tenant
    client
    created_at
    updated_at
  ].freeze

  # Read-only resource
  FORM_ATTRIBUTES = [].freeze

  COLLECTION_FILTERS = {
    tenant: ->(resources, attr) { resources.where(tenant_id: attr) },
    tenant_id: ->(resources, attr) { resources.where(tenant_id: attr) }
  }.freeze

  def display_resource(chat)
    "Chat ##{chat.id}"
  end
end
