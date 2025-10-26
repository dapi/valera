# frozen_string_literal: true

# Represents a tool/function call made by the AI assistant
class ToolCall < ApplicationRecord
  acts_as_tool_call
end
