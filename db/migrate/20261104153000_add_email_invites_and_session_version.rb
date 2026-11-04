# frozen_string_literal: true

class AddEmailInvitesAndSessionVersion < ActiveRecord::Migration[8.1]
  def change
    add_column :tenant_invites, :email, :string
    add_column :users, :session_version, :integer, null: false, default: 0
  end
end
