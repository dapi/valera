# frozen_string_literal: true

require 'administrate/base_dashboard'

class AdminUserDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    email: Field::Email,
    password: Field::Password,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    email
    created_at
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    email
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    email
    password
  ].freeze

  COLLECTION_FILTERS = {}.freeze

  def display_resource(admin_user)
    admin_user.email
  end
end
