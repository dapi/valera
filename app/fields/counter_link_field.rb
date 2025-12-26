# frozen_string_literal: true

require 'administrate/field/base'

# Custom Administrate field for displaying counter with link to filtered resources
#
# Usage in dashboard:
#   chats_count: CounterLinkField.with_options(resource_name: :chats)
#
class CounterLinkField < Administrate::Field::Base
  def to_s
    data.to_i.to_s
  end

  def resource_name
    options.fetch(:resource_name)
  end

  def link_path
    "/admin/#{resource_name}?tenant_id=#{resource.id}"
  end

  def count
    data.to_i
  end

  def linkable?
    count.positive?
  end
end
