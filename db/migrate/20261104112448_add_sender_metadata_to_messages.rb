# frozen_string_literal: true

class AddSenderMetadataToMessages < ActiveRecord::Migration[8.1]
  def change
    add_column :messages, :sender_id, :bigint
    add_column :messages, :sender_type, :integer, default: 0, null: false
    add_index :messages, %i[chat_id sender_type]
  end
end
