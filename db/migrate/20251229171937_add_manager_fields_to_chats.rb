class AddManagerFieldsToChats < ActiveRecord::Migration[8.1]
  def change
    add_column :chats, :manager_active, :boolean, default: false, null: false
    add_column :chats, :manager_active_at, :datetime
    add_column :chats, :manager_active_until, :datetime
    add_reference :chats, :manager_user, null: true, foreign_key: { to_table: :users }

    add_index :chats, :manager_active, where: 'manager_active = true', name: 'index_chats_on_manager_active_true'
  end
end
