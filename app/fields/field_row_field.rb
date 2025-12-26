# frozen_string_literal: true

require 'administrate/field/base'

# Custom Administrate field that groups multiple fields on one row
# Usage:
#   owner_and_manager: FieldRowField.with_options(
#     fields: [:owner, :manager],
#     field_types: { owner: Field::BelongsTo, manager: Field::BelongsTo }
#   )
class FieldRowField < Administrate::Field::Base
  def fields_config
    options.fetch(:fields, [])
  end

  def field_types
    options.fetch(:field_types, {})
  end

  # Build field instances for each sub-field
  def sub_fields
    @sub_fields ||= fields_config.map do |field_name|
      field_class = field_types[field_name] || Administrate::Field::String
      field_class.new(field_name, resource.send(field_name), page)
    end
  end

  # For form rendering - we need the resource and page context
  def resource
    @resource ||= data
  end

  def self.permitted_attribute(attr, _options = {})
    # Return permitted attributes for all sub-fields
    fields = _options.fetch(:fields, [])
    fields
  end
end
