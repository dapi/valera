# frozen_string_literal: true

# Добавляет ссылку на пользователя, отправившего сообщение
#
# Используется для сообщений от менеджера (role: 'manager')
# чтобы знать какой именно менеджер написал сообщение
class AddSentByUserToMessages < ActiveRecord::Migration[8.1]
  def change
    add_reference :messages, :sent_by_user, null: true, foreign_key: { to_table: :users }
  end
end
