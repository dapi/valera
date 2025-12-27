# frozen_string_literal: true

require 'administrate/base_dashboard'

class TenantInviteDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    tenant: Field::BelongsTo,
    invited_by_user: Field::BelongsTo.with_options(class_name: 'User'),
    invited_by_admin: Field::BelongsTo.with_options(class_name: 'AdminUser'),
    accepted_by: Field::BelongsTo.with_options(class_name: 'User'),
    token: Field::String,
    role: Field::Select.with_options(
      collection: ->(field) { field.resource.class.roles.keys }
    ),
    status: Field::Select.with_options(
      collection: ->(field) { field.resource.class.statuses.keys }
    ),
    expires_at: Field::DateTime,
    accepted_at: Field::DateTime,
    cancelled_at: Field::DateTime,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
    telegram_url: TelegramLinkField
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    tenant
    role
    status
    telegram_url
    expires_at
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    tenant
    invited_by_user
    invited_by_admin
    accepted_by
    token
    telegram_url
    role
    status
    expires_at
    accepted_at
    cancelled_at
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    tenant
    role
  ].freeze

  COLLECTION_FILTERS = {
    tenant: ->(resources, attr) { resources.where(tenant_id: attr) },
    pending: ->(resources) { resources.pending },
    accepted: ->(resources) { resources.accepted },
    cancelled: ->(resources) { resources.cancelled },
    active: ->(resources) { resources.active }
  }.freeze

  def display_resource(invite)
    "Invite ##{invite.id} (#{invite.role})"
  end
end
