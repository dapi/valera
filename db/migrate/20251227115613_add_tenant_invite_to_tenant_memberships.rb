class AddTenantInviteToTenantMemberships < ActiveRecord::Migration[8.1]
  def change
    add_reference :tenant_memberships, :tenant_invite, null: true, foreign_key: true
  end
end
