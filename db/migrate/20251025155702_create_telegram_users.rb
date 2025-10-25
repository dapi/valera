class CreateTelegramUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :telegram_users do |t|
      t.string "first_name"
      t.string "last_name"
      t.string "username"
      t.string "photo_url"
      t.timestamps
    end
  end
end
