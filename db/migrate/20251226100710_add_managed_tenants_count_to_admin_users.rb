class AddManagedTenantsCountToAdminUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :admin_users, :managed_tenants_count, :integer, default: 0, null: false

    reversible do |dir|
      dir.up do
        execute <<-SQL.squish
          UPDATE admin_users
          SET managed_tenants_count = (
            SELECT COUNT(*)
            FROM tenants
            WHERE tenants.manager_id = admin_users.id
          )
        SQL
      end
    end
  end
end
