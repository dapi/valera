class AddLastMessageAtToChats < ActiveRecord::Migration[8.1]
  def change
    add_column :chats, :last_message_at, :datetime
    add_index :chats, [ :tenant_id, :last_message_at ]

    # Заполнить last_message_at для существующих чатов
    reversible do |dir|
      dir.up do
        execute <<~SQL.squish
          UPDATE chats
          SET last_message_at = (
            SELECT MAX(messages.created_at)
            FROM messages
            WHERE messages.chat_id = chats.id
          )
        SQL

        # Для чатов без сообщений используем created_at
        execute <<~SQL.squish
          UPDATE chats
          SET last_message_at = created_at
          WHERE last_message_at IS NULL
        SQL
      end
    end
  end
end
