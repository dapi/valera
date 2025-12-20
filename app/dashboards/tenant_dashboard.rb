# frozen_string_literal: true

require 'administrate/base_dashboard'

class TenantDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    name: Field::String,
    key: Field::String,
    bot_username: Field::String,
    bot_token: Field::Password, # Hide sensitive token
    webhook_secret: Field::Password, # Hide sensitive secret
    admin_chat_id: Field::Number,
    owner: Field::BelongsTo,
    company_info: Field::Text,
    price_list: Field::Text,
    system_prompt: Field::Text,
    welcome_message: Field::Text,
    clients: Field::HasMany,
    chats: Field::HasMany,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    name
    bot_username
    owner
    created_at
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    name
    key
    bot_username
    bot_token
    webhook_secret
    admin_chat_id
    owner
    company_info
    price_list
    system_prompt
    welcome_message
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    name
    bot_token
    bot_username
    admin_chat_id
    owner
    company_info
    price_list
    system_prompt
    welcome_message
  ].freeze

  COLLECTION_FILTERS = {}.freeze

  def display_resource(tenant)
    tenant.name
  end
end
