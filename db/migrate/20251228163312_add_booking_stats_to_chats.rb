class AddBookingStatsToChats < ActiveRecord::Migration[8.1]
  def change
    add_column :chats, :first_booking_at, :datetime
    add_column :chats, :last_booking_at, :datetime
    add_column :chats, :bookings_count, :integer, default: 0, null: false

    add_index :chats, :first_booking_at
    add_index :chats, :last_booking_at
    add_index :chats, :bookings_count
  end
end
