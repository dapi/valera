class RemoveTelegramUserFromChatsAndBookings < ActiveRecord::Migration[8.1]
  def change
    remove_column :chats, :telegram_user_id, :bigint
    remove_column :bookings, :telegram_user_id, :bigint
  end
end
