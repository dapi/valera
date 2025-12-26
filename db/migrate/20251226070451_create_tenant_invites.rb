class CreateTenantInvites < ActiveRecord::Migration[8.1]
  def change
    create_table :tenant_invites do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :invited_by, null: false, foreign_key: { to_table: :users }
      t.references :accepted_by, foreign_key: { to_table: :users }
      t.string :token, null: false
      t.integer :role, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.datetime :expires_at, null: false
      t.datetime :accepted_at
      t.datetime :cancelled_at

      t.timestamps
    end
    add_index :tenant_invites, :token, unique: true
    add_index :tenant_invites, %i[tenant_id status]
  end
end
