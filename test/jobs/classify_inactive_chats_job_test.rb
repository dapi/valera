# frozen_string_literal: true

require 'test_helper'

class ClassifyInactiveChatsJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @tenant = tenants(:one)
    @chat = chats(:one)
    # Очищаем топики у всех чатов
    Chat.update_all(chat_topic_id: nil)
  end

  test 'finds chats inactive longer than configured hours' do
    # Настроим чат как неактивный (25 часов назад, при дефолте 24ч)
    @chat.update!(last_message_at: 25.hours.ago, chat_topic_id: nil)

    assert_enqueued_with(job: ClassifyChatTopicJob, args: [@chat.id]) do
      ClassifyInactiveChatsJob.perform_now
    end
  end

  test 'excludes chats with existing topic' do
    topic = ChatTopic.find_or_create_by!(key: 'test_exclusion_topic') do |t|
      t.label = 'Test'
    end
    @chat.update!(last_message_at: 25.hours.ago, chat_topic: topic)

    assert_no_enqueued_jobs(only: ClassifyChatTopicJob) do
      ClassifyInactiveChatsJob.perform_now
    end
  end

  test 'excludes chats older than 7 days' do
    @chat.update!(last_message_at: 8.days.ago, chat_topic_id: nil)

    assert_no_enqueued_jobs(only: ClassifyChatTopicJob) do
      ClassifyInactiveChatsJob.perform_now
    end
  end

  test 'excludes recently active chats' do
    @chat.update!(last_message_at: 1.hour.ago, chat_topic_id: nil)

    assert_no_enqueued_jobs(only: ClassifyChatTopicJob) do
      ClassifyInactiveChatsJob.perform_now
    end
  end

  test 'enqueues ClassifyChatTopicJob for each found chat' do
    chat2 = @tenant.chats.create!(
      client: @chat.client,
      last_message_at: 30.hours.ago,
      chat_topic_id: nil
    )
    @chat.update!(last_message_at: 26.hours.ago, chat_topic_id: nil)

    assert_enqueued_jobs 2, only: ClassifyChatTopicJob do
      ClassifyInactiveChatsJob.perform_now
    end
  end

  test 'continues processing when individual chat enqueue fails' do
    @chat.update!(last_message_at: 25.hours.ago, chat_topic_id: nil)

    # Мокируем perform_later чтобы выбросить ошибку
    ClassifyChatTopicJob.stubs(:perform_later).raises(StandardError.new('Test error'))

    # Job должен продолжить работу (не упасть)
    assert_nothing_raised do
      ClassifyInactiveChatsJob.perform_now
    end
  end

  test 'uses low_priority queue' do
    assert_equal 'low_priority', ClassifyInactiveChatsJob.new.queue_name
  end
end
