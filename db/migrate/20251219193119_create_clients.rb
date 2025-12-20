class CreateClients < ActiveRecord::Migration[8.1]
  def change
    create_table :clients do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :telegram_user, null: false, foreign_key: true
      t.string :name
      t.string :phone

      t.timestamps

      t.index %i[tenant_id telegram_user_id], unique: true
    end
  end
end
