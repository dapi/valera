class AddChatTopicToChats < ActiveRecord::Migration[8.1]
  def change
    add_reference :chats, :chat_topic, null: true, foreign_key: true
    add_column :chats, :topic_classified_at, :datetime

    add_index :chats, :topic_classified_at
  end
end
