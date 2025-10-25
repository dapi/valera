require "test_helper"

class ChatTest < ActiveSupport::TestCase
  test "fixture is valid and persisted" do
    chat = chats(:one)
    assert chat.valid?
    assert chat.persisted?
  end
end