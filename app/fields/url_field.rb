# frozen_string_literal: true

require 'administrate/field/base'

# Custom Administrate field for displaying URLs as clickable links
class UrlField < Administrate::Field::Base
  def to_s
    data
  end

  def link_text
    options.fetch(:link_text, data)
  end

  def target
    options.fetch(:target, '_blank')
  end
end
