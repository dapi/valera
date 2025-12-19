class AddTenantAndClientToBookings < ActiveRecord::Migration[8.1]
  def change
    # Очистка тестовых данных перед добавлением NOT NULL constraint
    execute 'DELETE FROM bookings'

    add_reference :bookings, :tenant, null: false, foreign_key: true
    add_reference :bookings, :client, null: false, foreign_key: true
    add_reference :bookings, :vehicle, foreign_key: true  # vehicle опционален
  end
end
