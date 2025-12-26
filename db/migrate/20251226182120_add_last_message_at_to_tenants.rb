class AddLastMessageAtToTenants < ActiveRecord::Migration[8.1]
  def change
    add_column :tenants, :last_message_at, :datetime
  end
end
