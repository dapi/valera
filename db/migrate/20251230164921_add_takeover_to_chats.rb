# frozen_string_literal: true

# Добавляет поля для функционала takeover (перехват диалога менеджером)
# mode: 0 = ai_mode (по умолчанию), 1 = manager_mode
# taken_by_id: ссылка на User, который перехватил диалог
# taken_at: время перехвата (для расчёта таймаута)
class AddTakeoverToChats < ActiveRecord::Migration[8.1]
  def change
    add_column :chats, :mode, :integer, default: 0, null: false
    add_column :chats, :taken_by_id, :bigint
    add_column :chats, :taken_at, :datetime

    add_index :chats, %i[tenant_id mode]
    add_index :chats, :taken_by_id
    add_foreign_key :chats, :users, column: :taken_by_id
  end
end
