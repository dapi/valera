# frozen_string_literal: true

require 'test_helper'

class MessageTest < ActiveSupport::TestCase
  test 'fixture is valid and persisted' do
    message = messages(:one)
    assert message.valid?
    assert message.persisted?
  end

  test 'valid roles are accepted' do
    chat = chats(:one)
    Message::VALID_ROLES.each do |role|
      message = Message.new(chat: chat, role: role, content: 'Test content')
      assert message.valid?, "Role '#{role}' should be valid but got errors: #{message.errors.full_messages}"
    end
  end

  test 'invalid role is rejected' do
    chat = chats(:one)
    message = Message.new(chat: chat, role: 'invalid_role', content: 'Test content')
    assert_not message.valid?
    assert message.errors[:role].any?
  end

  test 'empty role is rejected' do
    chat = chats(:one)
    message = Message.new(chat: chat, role: '', content: 'Test content')
    assert_not message.valid?
    assert message.errors[:role].any?
  end

  test 'nil role is rejected' do
    chat = chats(:one)
    message = Message.new(chat: chat, role: nil, content: 'Test content')
    assert_not message.valid?
    assert message.errors[:role].any?
  end

  test 'VALID_ROLES matches RubyLLM roles' do
    expected = RubyLLM::Message::ROLES.map(&:to_s).sort
    actual = Message::VALID_ROLES.sort
    assert_equal expected, actual,
      "Message::VALID_ROLES is out of sync with RubyLLM::Message::ROLES. " \
      "Expected: #{expected}, Got: #{actual}"
  end
end
