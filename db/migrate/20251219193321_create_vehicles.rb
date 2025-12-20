class CreateVehicles < ActiveRecord::Migration[8.1]
  def change
    create_table :vehicles do |t|
      t.references :client, null: false, foreign_key: true
      t.string :brand
      t.string :model
      t.integer :year
      t.string :vin
      t.string :plate_number
      t.text :notes

      t.timestamps
    end
  end
end
