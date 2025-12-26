# frozen_string_literal: true

require 'administrate/field/base'

# Custom Administrate field for displaying managed tenants count with link
class ManagedTenantsCountField < Administrate::Field::Base
  def to_s
    data.to_s
  end

  def count
    data.to_i
  end

  def link_path
    return nil if resource.nil?

    "/tenants?manager_id=#{resource.id}"
  end
end
