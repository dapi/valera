class AddCityToLeads < ActiveRecord::Migration[8.1]
  def change
    add_column :leads, :city, :string
  end
end
