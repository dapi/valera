class AddCounterCacheToTenants < ActiveRecord::Migration[8.1]
  def change
    add_column :tenants, :chats_count, :integer, default: 0, null: false
    add_column :tenants, :clients_count, :integer, default: 0, null: false
    add_column :tenants, :bookings_count, :integer, default: 0, null: false

    reversible do |dir|
      dir.up do
        execute <<-SQL.squish
          UPDATE tenants
          SET chats_count = (SELECT COUNT(*) FROM chats WHERE chats.tenant_id = tenants.id),
              clients_count = (SELECT COUNT(*) FROM clients WHERE clients.tenant_id = tenants.id),
              bookings_count = (SELECT COUNT(*) FROM bookings WHERE bookings.tenant_id = tenants.id)
        SQL
      end
    end
  end
end
