class RemoveRemainingNonCascadeConstraints < ActiveRecord::Migration[8.1]
  def change
    # Remove remaining foreign key constraints without cascade delete
    execute <<-SQL
      ALTER TABLE active_storage_variant_records
        DROP CONSTRAINT IF EXISTS fk_rails_a822b56c41
    SQL

    execute <<-SQL
      ALTER TABLE bookings
        DROP CONSTRAINT IF EXISTS fk_rails_c8428809e2
    SQL

    execute <<-SQL
      ALTER TABLE messages
        DROP CONSTRAINT IF EXISTS fk_rails_7c8b5f3a2d
    SQL
  end
end
