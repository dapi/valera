# frozen_string_literal: true

# Migration to add missing performance-optimized indexes for critical queries
#
# These indexes address the most performance-critical queries identified in the analysis:
# 1. Tool call lookups by API tool_call_id
# 2. Message ordering for context compaction
# 3. Message role-based queries
#
# Note: Some analytics indexes already exist in the original migration
# @see Performance analysis report for details on query optimization
class AddPerformanceIndexes < ActiveRecord::Migration[8.1]
  def change
    # Index for tool call lookups - eliminates full table scans
    # Used by: Chat#find_tool_call_db_id
    add_index :tool_calls, :tool_call_id, name: 'idx_tool_calls_tool_call_id' unless index_exists?(:tool_calls, :tool_call_id)

    # Composite index for message ordering in context management
    # Used by: Chat model, future context compaction (FIP-020)
    # Optimizes: chat.messages.order(:created_at)
    add_index :messages,
              [:chat_id, :created_at],
              name: 'idx_messages_chat_created_at' unless index_exists?(:messages, [:chat_id, :created_at])

    # Index for message role-based queries
    # Used by: future context compaction (FIP-020), various message queries
    # Optimizes: chat.messages.where(role: :system)
    add_index :messages,
              [:chat_id, :role],
              name: 'idx_messages_chat_role' unless index_exists?(:messages, [:chat_id, :role])
  end
end