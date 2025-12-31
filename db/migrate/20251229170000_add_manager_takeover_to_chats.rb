# frozen_string_literal: true

# Добавляет поля для режима менеджера (takeover)
#
# mode: enum - 0 = ai_mode (бот отвечает), 1 = manager_mode (менеджер отвечает)
# taken_by_id: менеджер, который перехватил чат
# taken_at: время перехвата (для расчёта таймаута и аналитики)
# manager_active_until: время до которого активен режим менеджера
class AddManagerTakeoverToChats < ActiveRecord::Migration[8.1]
  def change
    add_column :chats, :mode, :integer, default: 0, null: false
    add_column :chats, :taken_by_id, :bigint
    add_column :chats, :taken_at, :datetime
    add_column :chats, :manager_active_until, :datetime

    add_index :chats, %i[tenant_id mode]
    add_index :chats, :taken_by_id
    add_foreign_key :chats, :users, column: :taken_by_id
  end
end
