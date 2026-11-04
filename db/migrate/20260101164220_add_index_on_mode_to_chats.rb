# frozen_string_literal: true

# Добавляет отдельный index на mode для запросов без tenant_id
# (composite index [tenant_id, mode] не покрывает запросы только по mode)
class AddIndexOnModeToChats < ActiveRecord::Migration[8.1]
  def change
    add_index :chats, :mode
  end
end
