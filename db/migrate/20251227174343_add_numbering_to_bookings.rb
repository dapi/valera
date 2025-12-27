# frozen_string_literal: true

# Добавляет нумерацию заявок в рамках тенанта.
#
# - number: порядковый номер заявки внутри тенанта (начинается с 1)
# - public_number: публичный номер формата "{tenant_id}-{number}" для глобального поиска
class AddNumberingToBookings < ActiveRecord::Migration[8.1]
  def change
    add_column :bookings, :number, :integer
    add_column :bookings, :public_number, :string

    # Заполняем номера для существующих заявок
    reversible do |dir|
      dir.up do
        execute <<~SQL
          WITH numbered AS (
            SELECT id, tenant_id,
                   ROW_NUMBER() OVER (PARTITION BY tenant_id ORDER BY created_at, id) as num
            FROM bookings
          )
          UPDATE bookings
          SET number = numbered.num,
              public_number = CONCAT(numbered.tenant_id, '-', numbered.num)
          FROM numbered
          WHERE bookings.id = numbered.id
        SQL
      end
    end

    # После заполнения данных делаем поля NOT NULL и добавляем индексы
    change_column_null :bookings, :number, false
    change_column_null :bookings, :public_number, false
    add_index :bookings, %i[tenant_id number], unique: true
    add_index :bookings, :public_number, unique: true
  end
end
