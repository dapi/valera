class CreateLeads < ActiveRecord::Migration[8.1]
  def change
    create_table :leads do |t|
      t.string :name
      t.string :phone
      t.string :company_name
      t.string :source
      t.string :utm_source
      t.string :utm_medium
      t.string :utm_campaign

      t.timestamps
    end
  end
end
