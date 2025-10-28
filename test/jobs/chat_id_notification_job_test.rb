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
    chat_id = -1001234567890

    # Мокаем Telegram.bot.send_message
    Telegram.bot.expects(:send_message).with(
      chat_id: chat_id,
      text: I18n.t('chat_id_notification.message', chat_id: chat_id),
      parse_mode: 'Markdown'
    ).once

    ChatIdNotificationJob.perform_now(chat_id)
  end

  test 'does not send message when chat_id is blank' do
    # Мокаем чтобы убедиться что метод не вызывается
    Telegram.bot.expects(:send_message).never

    # Тестируем с nil
    ChatIdNotificationJob.perform_now(nil)

    # Тестируем с пустой строкой
    ChatIdNotificationJob.perform_now('')

    # Тестируем с пробелом
    ChatIdNotificationJob.perform_now('   ')
  end

  test 'handles positive chat_id' do
    chat_id = 12345

    Telegram.bot.expects(:send_message).with(
      chat_id: chat_id,
      text: I18n.t('chat_id_notification.message', chat_id: chat_id),
      parse_mode: 'Markdown'
    ).once

    ChatIdNotificationJob.perform_now(chat_id)
  end

  test 'handles negative chat_id (supergroup)' do
    chat_id = -1009876543210

    Telegram.bot.expects(:send_message).with(
      chat_id: chat_id,
      text: I18n.t('chat_id_notification.message', chat_id: chat_id),
      parse_mode: 'Markdown'
    ).once

    ChatIdNotificationJob.perform_now(chat_id)
  end

  test 'logs error when send_message fails' do
    chat_id = -1001234567890
    error_message = 'Telegram API error'

    # Мокаем чтобы метод вызывал ошибку
    Telegram.bot.expects(:send_message).raises(StandardError.new(error_message))

    # Мокаем логирование ошибки
    ChatIdNotificationJob.any_instance.expects(:log_error).with(
      instance_of(StandardError),
      job: 'ChatIdNotificationJob',
      chat_id: chat_id
    ).once

    # Проверяем что ошибка пробрасывается дальше (для retry логики)
    assert_raises StandardError do
      ChatIdNotificationJob.perform_now(chat_id)
    end
  end

  test 'uses correct message format with chat_id' do
    chat_id = -1001234567890

    Telegram.bot.expects(:send_message).with do |options|
      expected_text = I18n.t('chat_id_notification.message', chat_id: chat_id)
      options[:text] == expected_text &&
      options[:parse_mode] == 'Markdown' &&
      options[:chat_id] == chat_id
    end.once

    ChatIdNotificationJob.perform_now(chat_id)
  end
end
