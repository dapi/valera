require "test_helper"

class ToolCallTest < ActiveSupport::TestCase
  test "fixture is valid and persisted" do
    tool_call = tool_calls(:one)
    assert tool_call.valid?
    assert tool_call.persisted?
  end
end