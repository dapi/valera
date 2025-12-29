# frozen_string_literal: true

require 'test_helper'

class ChatTest < ActiveSupport::TestCase
  test 'fixture is valid and persisted' do
    chat = chats(:one)
    assert chat.valid?
    assert chat.persisted?
  end

  # Manager takeover tests

  test 'new chat is in bot mode by default' do
    chat = chats(:one)
    assert chat.bot_mode?
    assert_not chat.manager_mode?
    assert_not chat.manager_active?
  end

  test 'takeover_by_manager! switches chat to manager mode' do
    chat = chats(:one)
    user = users(:one)

    chat.takeover_by_manager!(user)

    assert chat.manager_mode?
    assert_not chat.bot_mode?
    assert chat.manager_active?
    assert_equal user, chat.manager_user
    assert_not_nil chat.manager_active_at
    assert_not_nil chat.manager_active_until
  end

  test 'takeover_by_manager! sets correct timeout' do
    chat = chats(:one)
    user = users(:one)

    freeze_time do
      chat.takeover_by_manager!(user, timeout_minutes: 15)

      assert_equal 15.minutes.from_now, chat.manager_active_until
    end
  end

  test 'release_to_bot! switches chat back to bot mode' do
    chat = chats(:one)
    user = users(:one)

    chat.takeover_by_manager!(user)
    chat.release_to_bot!

    assert chat.bot_mode?
    assert_not chat.manager_mode?
    assert_not chat.manager_active?
    assert_nil chat.manager_user
    assert_nil chat.manager_active_at
    assert_nil chat.manager_active_until
  end

  test 'manager_mode? returns false when timeout expired' do
    chat = chats(:one)
    user = users(:one)

    chat.takeover_by_manager!(user, timeout_minutes: 1)

    # Simulate time passing
    travel 2.minutes do
      assert_not chat.manager_mode?
      assert chat.bot_mode?
      # Should auto-release
      chat.reload
      assert_not chat.manager_active?
    end
  end

  test 'extend_manager_timeout! extends the timeout' do
    chat = chats(:one)
    user = users(:one)

    chat.takeover_by_manager!(user, timeout_minutes: 10)
    original_until = chat.manager_active_until

    travel 5.minutes

    chat.extend_manager_timeout!(timeout_minutes: 15)
    assert chat.manager_active_until > original_until
    assert_equal 15.minutes.from_now, chat.manager_active_until

    travel_back
  end

  test 'extend_manager_timeout! returns false if not in manager mode' do
    chat = chats(:one)

    assert_not chat.extend_manager_timeout!
  end

  test 'time_until_auto_release returns remaining time' do
    chat = chats(:one)
    user = users(:one)

    chat.takeover_by_manager!(user, timeout_minutes: 30)

    travel 10.minutes

    remaining = chat.time_until_auto_release
    assert_not_nil remaining
    assert_in_delta 20.minutes.to_i, remaining.to_i, 1

    travel_back
  end

  test 'time_until_auto_release returns nil when not in manager mode' do
    chat = chats(:one)

    assert_nil chat.time_until_auto_release
  end

  test 'manager_controlled scope returns only manager-controlled chats' do
    chat1 = chats(:one)
    chat2 = chats(:two)
    user = users(:one)

    chat1.takeover_by_manager!(user)

    manager_chats = Chat.manager_controlled
    assert_includes manager_chats, chat1
    assert_not_includes manager_chats, chat2
  end

  test 'bot_controlled scope returns only bot-controlled chats' do
    chat1 = chats(:one)
    chat2 = chats(:two)
    user = users(:one)

    chat1.takeover_by_manager!(user)

    bot_chats = Chat.bot_controlled
    assert_not_includes bot_chats, chat1
    assert_includes bot_chats, chat2
  end
end
