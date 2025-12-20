class AddClientToChats < ActiveRecord::Migration[8.1]
  def change
    # Chats уже очищены в предыдущей миграции
    add_reference :chats, :client, null: false, foreign_key: true
  end
end
