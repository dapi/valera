class PopulateChatsBookingStats < ActiveRecord::Migration[8.1]
  def up
    execute <<-SQL.squish
      UPDATE chats
      SET
        bookings_count = (
          SELECT COUNT(*) FROM bookings WHERE bookings.chat_id = chats.id
        ),
        first_booking_at = (
          SELECT MIN(created_at) FROM bookings WHERE bookings.chat_id = chats.id
        ),
        last_booking_at = (
          SELECT MAX(created_at) FROM bookings WHERE bookings.chat_id = chats.id
        )
      WHERE EXISTS (
        SELECT 1 FROM bookings WHERE bookings.chat_id = chats.id
      )
    SQL
  end

  def down
    execute <<-SQL.squish
      UPDATE chats
      SET bookings_count = 0, first_booking_at = NULL, last_booking_at = NULL
    SQL
  end
end
