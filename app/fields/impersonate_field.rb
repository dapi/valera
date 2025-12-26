# frozen_string_literal: true

require 'administrate/field/base'

# Custom Administrate field for impersonate button
class ImpersonateField < Administrate::Field::Base
  def to_s
    nil
  end

  def admin_user
    data
  end
end
