# frozen_string_literal: true

require 'test_helper'

class MessageTest < ActiveSupport::TestCase
  test 'fixture is valid and persisted' do
    message = messages(:one)
    assert message.valid?
    assert message.persisted?
  end

  # Role tests

  test 'ROLES constant includes all expected roles' do
    assert_includes Message::ROLES, 'user'
    assert_includes Message::ROLES, 'assistant'
    assert_includes Message::ROLES, 'manager'
    assert_includes Message::ROLES, 'system'
    assert_includes Message::ROLES, 'tool'
  end

  test 'validates role inclusion' do
    message = messages(:one)
    message.role = 'invalid_role'
    assert_not message.valid?
    assert message.errors[:role].any?
  end

  test 'manager role requires sent_by_user' do
    chat = chats(:one)
    message = chat.messages.build(role: 'manager', content: 'Test')

    assert_not message.valid?
    assert message.errors[:sent_by_user].any?
  end

  test 'manager role is valid with sent_by_user' do
    chat = chats(:one)
    user = users(:one)
    message = chat.messages.build(role: 'manager', content: 'Test', sent_by_user: user)

    assert message.valid?
  end

  test 'user role does not require sent_by_user' do
    chat = chats(:one)
    message = chat.messages.build(role: 'user', content: 'Test')

    assert message.valid?
  end

  test 'assistant role does not require sent_by_user' do
    chat = chats(:one)
    message = chat.messages.build(role: 'assistant', content: 'Test')

    assert message.valid?
  end

  # Helper method tests

  test 'from_manager? returns true for manager role' do
    chat = chats(:one)
    user = users(:one)
    message = chat.messages.create!(role: 'manager', content: 'Test', sent_by_user: user)

    assert message.from_manager?
    assert_not message.from_bot?
    assert_not message.from_client?
  end

  test 'from_bot? returns true for assistant role' do
    message = messages(:one)
    message.role = 'assistant'

    assert message.from_bot?
    assert_not message.from_manager?
    assert_not message.from_client?
  end

  test 'from_client? returns true for user role' do
    message = messages(:one)
    message.role = 'user'

    assert message.from_client?
    assert_not message.from_manager?
    assert_not message.from_bot?
  end

  # Scope tests

  test 'from_manager scope returns only manager messages' do
    chat = chats(:one)
    user = users(:one)

    manager_message = chat.messages.create!(role: 'manager', content: 'Manager msg', sent_by_user: user)
    bot_message = chat.messages.create!(role: 'assistant', content: 'Bot msg')

    manager_messages = Message.from_manager
    assert_includes manager_messages, manager_message
    assert_not_includes manager_messages, bot_message
  end

  test 'from_bot scope returns only assistant messages' do
    chat = chats(:one)
    user = users(:one)

    manager_message = chat.messages.create!(role: 'manager', content: 'Manager msg', sent_by_user: user)
    bot_message = chat.messages.create!(role: 'assistant', content: 'Bot msg')

    bot_messages = Message.from_bot
    assert_includes bot_messages, bot_message
    assert_not_includes bot_messages, manager_message
  end

  test 'from_client scope returns only user messages' do
    chat = chats(:one)

    client_message = chat.messages.create!(role: 'user', content: 'Client msg')
    bot_message = chat.messages.create!(role: 'assistant', content: 'Bot msg')

    client_messages = Message.from_client
    assert_includes client_messages, client_message
    assert_not_includes client_messages, bot_message
  end
end
