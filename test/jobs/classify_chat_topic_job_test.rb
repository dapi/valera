# frozen_string_literal: true

require 'test_helper'

class ClassifyChatTopicJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @tenant = tenants(:one)
    @chat = chats(:one)
    # Используем find_or_create чтобы избежать конфликта с fixtures
    @topic = ChatTopic.find_or_create_by!(key: 'job_test_booking') do |t|
      t.label = 'Запись на обслуживание'
    end
  end

  test 'skips when chat does not exist' do
    # Should not raise, just return
    assert_nothing_raised do
      ClassifyChatTopicJob.perform_now(999_999)
    end
  end

  test 'skips when chat already has topic' do
    @chat.update!(chat_topic: @topic)

    ChatTopicClassifier.any_instance.expects(:classify).never

    ClassifyChatTopicJob.perform_now(@chat.id)
  end

  test 'calls ChatTopicClassifier when chat has no topic' do
    @chat.update!(chat_topic: nil)
    @chat.messages.destroy_all
    @chat.messages.create!(role: 'user', content: 'Хочу записаться')

    # Используем ключ топика из fixtures (service_booking - глобальный)
    mock_response = stub(content: 'service_booking')
    mock_chat = stub(ask: mock_response)
    RubyLLM.stubs(:chat).returns(mock_chat)

    ClassifyChatTopicJob.perform_now(@chat.id)

    # Проверяем что топик был назначен
    classified_topic = @chat.reload.chat_topic
    assert_not_nil classified_topic
    assert_equal 'service_booking', classified_topic.key
  end

  test 'uses low_priority queue' do
    assert_equal 'low_priority', ClassifyChatTopicJob.new.queue_name
  end

  test 'enqueues job with chat_id' do
    assert_enqueued_with(job: ClassifyChatTopicJob, args: [@chat.id]) do
      ClassifyChatTopicJob.perform_later(@chat.id)
    end
  end
end
