class CleanupInvalidMessageRoles < ActiveRecord::Migration[8.1]
  VALID_ROLES = %w[system user assistant tool].freeze

  def up
    # Log messages with invalid roles before cleanup
    invalid_count = execute(<<~SQL).first
      SELECT COUNT(*) FROM messages
      WHERE role IS NULL OR role NOT IN ('system', 'user', 'assistant', 'tool')
    SQL

    say "Found #{invalid_count['count']} messages with invalid roles"

    # Delete messages with invalid roles
    # These messages cannot be loaded by ruby_llm and would cause InvalidRoleError
    execute(<<~SQL)
      DELETE FROM messages
      WHERE role IS NULL OR role NOT IN ('system', 'user', 'assistant', 'tool')
    SQL

    say "Deleted messages with invalid roles"
  end

  def down
    # Cannot restore deleted messages
    say "Cannot restore deleted messages with invalid roles"
  end
end
