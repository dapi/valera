class AddManagerToLeads < ActiveRecord::Migration[8.1]
  def change
    add_reference :leads, :manager, null: true, foreign_key: { to_table: :admin_users }
  end
end
