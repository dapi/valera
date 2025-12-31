# frozen_string_literal: true

# Cleanup дублирующихся колонок после merge conflict resolution
#
# После слияния веток feature/103 и master образовались дублирующиеся колонки:
#
# Chats:
#   - manager_user_id + taken_by_id → оставляем taken_by_id
#   - manager_active_at + taken_at → оставляем taken_at
#   - manager_active boolean → удаляем (mode enum заменяет)
#
# Messages:
#   - sent_by_user_id → оставляем (для manager messages)
#   - sender_id, sender_type → удаляем (не используются)
#
class CleanupDuplicateTakeoverColumns < ActiveRecord::Migration[8.1]
  def up
    # Перенос данных из старых колонок в новые (если есть)
    execute <<-SQL.squish
      UPDATE chats
      SET taken_by_id = COALESCE(taken_by_id, manager_user_id),
          taken_at = COALESCE(taken_at, manager_active_at)
      WHERE manager_user_id IS NOT NULL OR manager_active_at IS NOT NULL
    SQL

    # Удаление старых колонок из chats
    remove_foreign_key :chats, column: :manager_user_id, if_exists: true
    remove_index :chats, :manager_active, name: 'index_chats_on_manager_active_true', if_exists: true
    remove_column :chats, :manager_user_id
    remove_column :chats, :manager_active_at
    remove_column :chats, :manager_active

    # Удаление неиспользуемых колонок из messages
    remove_foreign_key :messages, column: :sender_id, if_exists: true
    remove_index :messages, [:chat_id, :sender_type], if_exists: true
    remove_column :messages, :sender_id
    remove_column :messages, :sender_type
  end

  def down
    # Восстановление колонок в chats
    add_column :chats, :manager_user_id, :bigint
    add_column :chats, :manager_active_at, :datetime
    add_column :chats, :manager_active, :boolean, default: false, null: false
    add_foreign_key :chats, :users, column: :manager_user_id
    add_index :chats, :manager_active, where: 'manager_active = true', name: 'index_chats_on_manager_active_true'

    # Восстановление колонок в messages
    add_column :messages, :sender_id, :bigint
    add_column :messages, :sender_type, :integer, default: 0, null: false
    add_foreign_key :messages, :users, column: :sender_id
    add_index :messages, [:chat_id, :sender_type]

    # Перенос данных обратно
    execute <<-SQL.squish
      UPDATE chats
      SET manager_user_id = taken_by_id,
          manager_active_at = taken_at,
          manager_active = (mode = 1)
      WHERE taken_by_id IS NOT NULL
    SQL
  end
end
