# frozen_string_literal: true

require 'administrate/base_dashboard'

class TelegramUserDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    first_name: Field::String,
    last_name: Field::String,
    username: TelegramUserLinkField,
    photo_url: Field::String,
    user: Field::HasOne,
    tenant_memberships: Field::HasMany,
    clients: Field::HasMany,
    chats: Field::HasMany,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    username
    id
    first_name
    last_name
    user
    created_at
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    first_name
    last_name
    username
    photo_url
    user
    tenant_memberships
    clients
    chats
    created_at
    updated_at
  ].freeze

  # Empty - read-only resource
  FORM_ATTRIBUTES = [].freeze

  COLLECTION_FILTERS = {}.freeze

  def display_resource(telegram_user)
    telegram_user.magic_username || "##{telegram_user.id}"
  end
end
