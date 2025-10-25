class CreateBookings < ActiveRecord::Migration[8.1]
  def change
    create_table :bookings do |t|
      t.belongs_to :telegram_user, null: false, foreign_key: true
      t.belongs_to :chat, null: true, foreign_key: true
      t.jsonb :meta, default: {}, null: false

      t.timestamps
    end
  end
end
