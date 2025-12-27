# frozen_string_literal: true

require 'test_helper'

# Тесты для ChatIdNotificationJob
#
# Проверяет корректность отправки уведомлений с chat_id
# при добавлении бота в группу или миграции группы.
class ChatIdNotificationJobTest < ActiveJob::TestCase
  test 'uses correct queue' do
    assert_equal 'default', ChatIdNotificationJob.queue_name
  end

  test 'sends message with chat_id when chat_id is provided' do
    chat = chats(:one)
    mock_bot_client = mock('bot_client')

    chat.tenant.stubs(:bot_client).returns(mock_bot_client)
    Chat.stubs(:find).with(chat.id).returns(chat)

    mock_bot_client.expects(:send_message).with(
      chat_id: chat.id,
      text: I18n.t('chat_id_notification.message', chat_id: chat.id),
      parse_mode: 'Markdown'
    ).once

    ChatIdNotificationJob.perform_now(chat.id)
  end

  test 'does not send message when chat_id is blank' do
    # При пустом chat_id не должно быть вызовов Chat.find
    Chat.expects(:find).never

    # Тестируем с nil
    ChatIdNotificationJob.perform_now(nil)

    # Тестируем с пустой строкой
    ChatIdNotificationJob.perform_now('')

    # Тестируем с пробелом
    ChatIdNotificationJob.perform_now('   ')
  end

  test 'handles chat from fixture' do
    chat = chats(:two)
    mock_bot_client = mock('bot_client')

    chat.tenant.stubs(:bot_client).returns(mock_bot_client)
    Chat.stubs(:find).with(chat.id).returns(chat)

    mock_bot_client.expects(:send_message).with(
      chat_id: chat.id,
      text: I18n.t('chat_id_notification.message', chat_id: chat.id),
      parse_mode: 'Markdown'
    ).once

    ChatIdNotificationJob.perform_now(chat.id)
  end

  test 'logs error and retries when send_message fails' do
    chat = chats(:one)
    mock_bot_client = mock('bot_client')
    error_message = 'Telegram API error'

    chat.tenant.stubs(:bot_client).returns(mock_bot_client)
    Chat.stubs(:find).with(chat.id).returns(chat)

    # Мокаем чтобы метод вызывал ошибку
    mock_bot_client.expects(:send_message).raises(StandardError.new(error_message))

    # Мокаем логирование ошибки
    ChatIdNotificationJob.any_instance.expects(:log_error).with(
      instance_of(StandardError),
      job: 'ChatIdNotificationJob',
      chat_id: chat.id
    ).once

    # Проверяем что job запланирован на retry (retry_on StandardError в ApplicationJob)
    assert_enqueued_with(job: ChatIdNotificationJob) do
      ChatIdNotificationJob.perform_now(chat.id)
    end
  end

  test 'uses correct message format with chat_id' do
    chat = chats(:one)
    mock_bot_client = mock('bot_client')

    chat.tenant.stubs(:bot_client).returns(mock_bot_client)
    Chat.stubs(:find).with(chat.id).returns(chat)

    mock_bot_client.expects(:send_message).with do |options|
      expected_text = I18n.t('chat_id_notification.message', chat_id: chat.id)
      options[:text] == expected_text &&
      options[:parse_mode] == 'Markdown' &&
      options[:chat_id] == chat.id
    end.once

    ChatIdNotificationJob.perform_now(chat.id)
  end
end
