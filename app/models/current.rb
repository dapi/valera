# frozen_string_literal: true

# Current provides request-scoped attributes for multi-tenancy and authentication.
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
# @example Using admin_user in admin controllers
#   Current.admin_user = AdminUser.find(session[:admin_user_id])
#
class Current < ActiveSupport::CurrentAttributes
  attribute :tenant
  attribute :admin_user
end
