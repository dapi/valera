class FixDuplicateForeignKeyConstraints < ActiveRecord::Migration[8.1]
  def change
    # Remove duplicate foreign key constraints without cascade delete
    execute <<-SQL
      ALTER TABLE active_storage_attachments
        DROP CONSTRAINT IF EXISTS fk_rails_c3b3935057
    SQL

    execute <<-SQL
      ALTER TABLE active_storage_variant_records
        DROP CONSTRAINT IF EXISTS fk_rails_4ebdeca62b
    SQL

    execute <<-SQL
      ALTER TABLE bookings
        DROP CONSTRAINT IF EXISTS fk_rails_a74b55a035
    SQL

    execute <<-SQL
      ALTER TABLE chats
        DROP CONSTRAINT IF EXISTS fk_rails_1761e4f7b5
    SQL

    execute <<-SQL
      ALTER TABLE chats
        DROP CONSTRAINT IF EXISTS fk_rails_1835d93df1
    SQL

    execute <<-SQL
      ALTER TABLE messages
        DROP CONSTRAINT IF EXISTS fk_rails_4d9a5c5e3f
    SQL

    execute <<-SQL
      ALTER TABLE messages
        DROP CONSTRAINT IF EXISTS fk_rails_552873cb52
    SQL

    execute <<-SQL
      ALTER TABLE tool_calls
        DROP CONSTRAINT IF EXISTS fk_rails_9c8daee481
    SQL
  end
end
