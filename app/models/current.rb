# frozen_string_literal: true

# Current provides request-scoped attributes for multi-tenancy.
# Set Current.tenant at the beginning of each request to scope all operations.
#
# @example Setting tenant in webhook controller
#   Current.tenant = Tenant.find_by!(key: params[:tenant_key])
#
# @example Using tenant in models
#   class Chat < ApplicationRecord
#     belongs_to :tenant, default: -> { Current.tenant }
#   end
#
class Current < ActiveSupport::CurrentAttributes
  attribute :tenant
end
