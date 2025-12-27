class AddInvitedByAdminToTenantInvites < ActiveRecord::Migration[8.1]
  def change
    rename_column :tenant_invites, :invited_by_id, :invited_by_user_id
    change_column_null :tenant_invites, :invited_by_user_id, true
    add_reference :tenant_invites, :invited_by_admin,
                  foreign_key: { to_table: :admin_users }
  end
end
