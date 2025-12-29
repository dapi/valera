class AddSentByUserToMessages < ActiveRecord::Migration[8.1]
  def change
    add_reference :messages, :sent_by_user, null: true, foreign_key: { to_table: :users }
  end
end
