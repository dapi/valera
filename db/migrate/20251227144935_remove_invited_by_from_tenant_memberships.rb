class RemoveInvitedByFromTenantMemberships < ActiveRecord::Migration[8.1]
  def change
    remove_reference :tenant_memberships, :invited_by, foreign_key: { to_table: :users }
  end
end
