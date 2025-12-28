# frozen_string_literal: true

require 'administrate/base_dashboard'

# Dashboard для управления темами чатов
#
# @see ChatTopic
class ChatTopicDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    key: Field::String,
    label: Field::String,
    tenant: Field::BelongsTo.with_options(required: false),
    active: Field::Boolean,
    chats: Field::HasMany,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    key
    label
    tenant
    active
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    key
    label
    tenant
    active
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    tenant
    key
    label
    active
  ].freeze

  COLLECTION_FILTERS = {
    global: ->(resources) { resources.where(tenant_id: nil) },
    active: ->(resources) { resources.where(active: true) },
    inactive: ->(resources) { resources.where(active: false) }
  }.freeze

  def display_resource(chat_topic)
    chat_topic.label
  end
end
