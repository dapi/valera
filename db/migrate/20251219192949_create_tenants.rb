# frozen_string_literal: true

class CreateTenants < ActiveRecord::Migration[8.1]
  def change
    create_table :tenants do |t|
      t.string :key, null: false
      t.string :name, null: false
      t.string :bot_token, null: false
      t.string :bot_username, null: false
      t.string :webhook_secret, null: false
      t.bigint :admin_chat_id
      t.references :owner, foreign_key: { to_table: :users }
      t.text :system_prompt
      t.text :welcome_message
      t.text :company_info
      t.text :price_list

      t.timestamps
    end
    add_index :tenants, :key, unique: true
    add_index :tenants, :name, unique: true
  end
end
