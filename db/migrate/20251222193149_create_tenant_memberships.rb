class CreateTenantMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :tenant_memberships do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :role, null: false, default: 0
      t.references :invited_by, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :tenant_memberships, %i[tenant_id user_id], unique: true
  end
end
