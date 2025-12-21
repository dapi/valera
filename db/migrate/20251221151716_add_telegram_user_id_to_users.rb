class AddTelegramUserIdToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :telegram_user_id, :bigint
    add_index :users, :telegram_user_id, unique: true
    add_foreign_key :users, :telegram_users, column: :telegram_user_id
  end
end
