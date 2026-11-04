class AddDeliveryAndIdempotencyToBookings < ActiveRecord::Migration[8.1]
  def change
    add_reference :bookings, :telegram_update, null: true, foreign_key: true, index: { unique: true }
    add_column :bookings, :notified_at, :datetime
    add_column :bookings, :notification_failed_at, :datetime
    add_column :bookings, :notification_requested_at, :datetime
  end
end
