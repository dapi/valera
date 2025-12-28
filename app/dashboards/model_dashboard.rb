# frozen_string_literal: true

require 'administrate/base_dashboard'

class ModelDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    model_id: Field::String.with_options(searchable: true),
    name: Field::String.with_options(searchable: true),
    provider: Field::String,
    family: Field::String,
    context_window: Field::Number,
    max_output_tokens: Field::Number,
    knowledge_cutoff: Field::Date,
    modalities: Field::String.with_options(searchable: false),
    capabilities: Field::String.with_options(searchable: false),
    pricing: Field::String.with_options(searchable: false),
    metadata: Field::String.with_options(searchable: false),
    model_created_at: Field::DateTime,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    model_id
    name
    provider
    family
    context_window
    max_output_tokens
  ].freeze

  SHOW_PAGE_ATTRIBUTES = {
    '' => %i[
      id
      model_id
      name
      provider
      family
      context_window
      max_output_tokens
      knowledge_cutoff
      model_created_at
      created_at
      updated_at
    ],
    'Capabilities' => %i[
      modalities
      capabilities
    ],
    'Pricing' => %i[
      pricing
    ],
    'Metadata' => %i[
      metadata
    ]
  }.freeze

  # Read-only resource
  FORM_ATTRIBUTES = [].freeze

  COLLECTION_FILTERS = {
    name: ->(resources, attr) { resources.where('name ILIKE ?', "%#{attr}%") },
    provider: ->(resources, attr) { resources.where(provider: attr) },
    family: ->(resources, attr) { resources.where(family: attr) }
  }.freeze

  def display_resource(model)
    model.name.presence || model.model_id
  end
end
