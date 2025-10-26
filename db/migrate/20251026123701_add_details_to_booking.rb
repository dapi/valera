class AddDetailsToBooking < ActiveRecord::Migration[8.1]
  def change
    add_column :bookings, :details, :text
  end
end
