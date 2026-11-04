class CreateTelegramUpdates < ActiveRecord::Migration[8.1]
  def change
    create_table :telegram_updates do |t|
      t.references :tenant, null: false, foreign_key: true
      t.bigint :update_id, null: false
      t.jsonb :payload, null: false
      t.string :conversation_key, null: false
      t.datetime :processed_at
      t.datetime :failed_at

      t.timestamps
    end
    add_index :telegram_updates, [ :tenant_id, :update_id ], unique: true
    add_index :telegram_updates, [ :tenant_id, :conversation_key, :id ],
              where: 'processed_at IS NULL AND failed_at IS NULL', name: 'index_pending_telegram_conversations'
  end
end
