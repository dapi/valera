class AddContextToBookings < ActiveRecord::Migration[8.1]
  def change
    add_column :bookings, :context, :text
  end
end
