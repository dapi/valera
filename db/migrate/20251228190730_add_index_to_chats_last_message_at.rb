class AddIndexToChatsLastMessageAt < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    # Композитный индекс для оптимизации ClassifyInactiveChatsJob
    # который ищет чаты без топика с фильтрацией по last_message_at
    add_index :chats, [:chat_topic_id, :last_message_at],
              algorithm: :concurrently,
              if_not_exists: true
  end
end
