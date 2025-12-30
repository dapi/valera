# frozen_string_literal: true

require 'test_helper'

class Manager::TelegramMessageSenderTest < ActiveSupport::TestCase
  setup do
    @chat = chats(:one)
    @mock_bot_client = mock('bot_client')
    @chat.tenant.stubs(:bot_client).returns(@mock_bot_client)
  end

  test 'sends message successfully' do
    @mock_bot_client.expects(:send_message).with(
      chat_id: @chat.client.telegram_user_id,
      text: 'Hello!',
      parse_mode: 'HTML'
    ).returns({ 'result' => { 'message_id' => 123 } })

    result = Manager::TelegramMessageSender.call(chat: @chat, text: 'Hello!')

    assert result.success?
    assert_equal 123, result.telegram_message_id
    assert_nil result.error
  end

  test 'returns error when chat is nil' do
    result = Manager::TelegramMessageSender.call(chat: nil, text: 'Hello!')

    assert_not result.success?
    assert_equal 'Chat is required', result.error
  end

  test 'returns error when text is blank' do
    result = Manager::TelegramMessageSender.call(chat: @chat, text: '')

    assert_not result.success?
    assert_equal 'Text is required', result.error
  end

  test 'returns error when chat has no telegram_user' do
    @chat.client.stubs(:telegram_user_id).returns(nil)

    result = Manager::TelegramMessageSender.call(chat: @chat, text: 'Hello!')

    assert_not result.success?
    assert_equal 'Chat has no telegram_user', result.error
  end

  test 'uses custom parse_mode' do
    @mock_bot_client.expects(:send_message).with(
      chat_id: @chat.client.telegram_user_id,
      text: '*Bold*',
      parse_mode: 'Markdown'
    ).returns({ 'result' => { 'message_id' => 456 } })

    result = Manager::TelegramMessageSender.call(
      chat: @chat,
      text: '*Bold*',
      parse_mode: 'Markdown'
    )

    assert result.success?
  end

  test 'handles telegram API error' do
    @mock_bot_client.expects(:send_message).raises(Faraday::Error.new('API Error'))

    result = Manager::TelegramMessageSender.call(chat: @chat, text: 'Hello!')

    assert_not result.success?
    assert_equal 'API Error', result.error
  end

  test 'handles timeout error' do
    @mock_bot_client.expects(:send_message).raises(Timeout::Error.new('Connection timed out'))

    result = Manager::TelegramMessageSender.call(chat: @chat, text: 'Hello!')

    assert_not result.success?
    assert_equal 'Connection timed out', result.error
  end
end
