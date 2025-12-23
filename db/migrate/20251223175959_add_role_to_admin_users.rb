# frozen_string_literal: true

class AddRoleToAdminUsers < ActiveRecord::Migration[8.1]
  def change
    # role: 0 = manager (default), 1 = superuser
    add_column :admin_users, :role, :integer, default: 0, null: false
  end
end
