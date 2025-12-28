class CreateChatTopics < ActiveRecord::Migration[8.1]
  def change
    create_table :chat_topics do |t|
      t.references :tenant, null: true, foreign_key: true
      t.string :key, null: false
      t.string :label, null: false
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :chat_topics, [:tenant_id, :key], unique: true
    add_index :chat_topics, :active
  end
end
