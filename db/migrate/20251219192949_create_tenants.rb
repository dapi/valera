class CreateTenants < ActiveRecord::Migration[8.1]
  def change
    create_table :tenants do |t|
      t.string :key
      t.string :name
      t.string :bot_token
      t.string :bot_username
      t.string :webhook_secret
      t.bigint :admin_chat_id
      t.references :owner, foreign_key: { to_table: :users }
      t.text :system_prompt
      t.text :welcome_message
      t.text :company_info
      t.text :price_list

      t.timestamps
    end
    add_index :tenants, :key, unique: true
  end
end
