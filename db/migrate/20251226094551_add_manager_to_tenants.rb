class AddManagerToTenants < ActiveRecord::Migration[8.1]
  def change
    add_reference :tenants, :manager, null: true, foreign_key: { to_table: :admin_users }
  end
end
