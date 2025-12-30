# frozen_string_literal: true

# Добавляет поля для различения типа отправителя сообщения
# sender_type: 0 = ai (по умолчанию), 1 = manager, 2 = client, 3 = system
# sender_id: ссылка на User, который отправил сообщение (для manager)
class AddSenderTypeToMessages < ActiveRecord::Migration[8.1]
  def change
    add_column :messages, :sender_type, :integer, default: 0, null: false
    add_column :messages, :sender_id, :bigint

    add_index :messages, %i[chat_id sender_type]
    add_foreign_key :messages, :users, column: :sender_id
  end
end
