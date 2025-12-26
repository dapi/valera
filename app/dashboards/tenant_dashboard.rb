# frozen_string_literal: true

require 'administrate/base_dashboard'
require_relative '../fields/url_field'
require_relative '../fields/telegram_bot_field'

class TenantDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    name: Field::String,
    key: Field::String,
    dashboard_url: UrlField.with_options(link_text: ->(field) { "#{URI.parse(field.data).host} ↗" }),
    bot_username: TelegramBotField,
    bot_token: Field::Password, # Hide sensitive token
    webhook_secret: Field::Password, # Hide sensitive secret
    admin_chat_id: Field::Number,
    owner: Field::BelongsTo,
    manager: Field::BelongsTo,
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
    dashboard_url
    bot_username
    owner
    manager
    created_at
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    name
    key
    dashboard_url
    bot_username
    bot_token
    webhook_secret
    admin_chat_id
    owner
    manager
    company_info
    price_list
    system_prompt
    welcome_message
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    name
    key
    bot_username
    bot_token
    admin_chat_id
    owner
    manager
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
