class CreateAnalyticsEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :analytics_events do |t|
      t.string :event_name, null: false, limit: 50, index: true
      t.bigint :chat_id, null: false, index: true
      t.string :session_id, limit: 64, index: true
      t.jsonb :properties, default: {}, null: false
      t.timestamp :occurred_at, null: false, index: true
      t.string :platform, default: 'telegram', limit: 20

      t.timestamps
    end

    # Performance indexes for analytics queries
    add_index :analytics_events, [:chat_id, :event_name, :occurred_at],
              name: 'idx_analytics_funnel'
    add_index :analytics_events, [:occurred_at, :event_name],
              name: 'idx_analytics_timeline'
    add_index :analytics_events, [:event_name, :occurred_at],
              name: 'idx_analytics_events_by_type'

    # Partial indexes for common queries - removed for now due to PostgreSQL constraints

    # GIN index for JSONB properties
    add_index :analytics_events, :properties, using: :gin
  end
end
