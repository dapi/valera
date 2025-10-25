class AddTelegramUserToChat < ActiveRecord::Migration[8.1]
  def change
    add_reference :chats, :telegram_user, null: false, foreign_key: true

    add_index :chats, :telegram_user_id, unique: true, name: :chat_telegram_user_uniq
  end
end
