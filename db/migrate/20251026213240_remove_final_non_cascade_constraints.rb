class RemoveFinalNonCascadeConstraints < ActiveRecord::Migration[8.1]
  def change
    # Remove final foreign key constraints without cascade delete
    execute <<-SQL
      ALTER TABLE active_storage_variant_records
        DROP CONSTRAINT IF EXISTS fk_rails_993965df05
    SQL

    execute <<-SQL
      ALTER TABLE bookings
        DROP CONSTRAINT IF EXISTS fk_rails_4ebdeca62b
    SQL

    execute <<-SQL
      ALTER TABLE messages
        DROP CONSTRAINT IF EXISTS fk_rails_c02b47ad97
    SQL
  end
end
