# frozen_string_literal: true

require 'administrate/field/text'

# Custom field for text areas with default value placeholder
# Shows the default value as placeholder when the field is empty
class TextWithDefaultField < Administrate::Field::Text
  # Returns default value via model method
  # Example: :system_prompt_or_default
  def default_value
    method_name = options[:default_method]
    return nil unless method_name && resource.respond_to?(method_name)

    resource.public_send(method_name)
  rescue StandardError
    nil
  end

  def has_default?
    default_value.present?
  end
end
