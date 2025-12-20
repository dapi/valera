class AddTenantToChats < ActiveRecord::Migration[8.1]
  def change
    # Очистка тестовых данных перед добавлением NOT NULL constraint
    execute 'DELETE FROM chats'

    add_reference :chats, :tenant, null: false, foreign_key: true
  end
end
