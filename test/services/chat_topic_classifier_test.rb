# frozen_string_literal: true

require 'test_helper'

class ChatTopicClassifierTest < ActiveSupport::TestCase
  setup do
    @tenant = tenants(:one)
    @chat = chats(:one)
    # Используем fixtures или find_or_create для избежания конфликтов
    @topic = chat_topics(:global_service_booking)
    # other топик уже есть в fixtures (global_other)
  end

  test 'returns existing topic if already classified' do
    @chat.update!(chat_topic: @topic)

    classifier = ChatTopicClassifier.new(@chat)
    result = classifier.classify

    assert_equal @topic, result
  end

  test 'returns nil when no user messages' do
    @chat.messages.destroy_all

    classifier = ChatTopicClassifier.new(@chat)
    result = classifier.classify

    assert_nil result
  end

  test 'classifies chat with mocked LLM response' do
    @chat.messages.destroy_all
    @chat.messages.create!(role: 'user', content: 'Хочу записаться на ТО')

    # Mock RubyLLM using mocha
    mock_response = stub(content: 'service_booking')
    mock_chat = stub(ask: mock_response)
    RubyLLM.stubs(:chat).returns(mock_chat)

    classifier = ChatTopicClassifier.new(@chat)
    result = classifier.classify

    assert_equal @topic, result
    assert_equal @topic, @chat.reload.chat_topic
    assert_not_nil @chat.topic_classified_at
  end

  test 'uses fallback topic when LLM returns unknown key' do
    @chat.messages.destroy_all
    @chat.messages.create!(role: 'user', content: 'Непонятное сообщение')

    fallback = chat_topics(:global_other)

    mock_response = stub(content: 'unknown_key_xyz')
    mock_chat = stub(ask: mock_response)
    RubyLLM.stubs(:chat).returns(mock_chat)

    classifier = ChatTopicClassifier.new(@chat)
    result = classifier.classify

    assert_equal fallback, result
  end

  test 'normalizes LLM response to lowercase key' do
    @chat.messages.destroy_all
    @chat.messages.create!(role: 'user', content: 'Записаться на сервис')

    mock_response = stub(content: "  SERVICE_BOOKING  \n")
    mock_chat = stub(ask: mock_response)
    RubyLLM.stubs(:chat).returns(mock_chat)

    classifier = ChatTopicClassifier.new(@chat)
    result = classifier.classify

    assert_equal @topic, result
  end

  test 'handles LLM errors gracefully' do
    @chat.messages.destroy_all
    @chat.messages.create!(role: 'user', content: 'Тест')

    mock_chat = stub
    mock_chat.stubs(:ask).raises(StandardError.new('LLM error'))
    RubyLLM.stubs(:chat).returns(mock_chat)

    classifier = ChatTopicClassifier.new(@chat)
    result = classifier.classify

    assert_nil result
    assert_nil @chat.reload.chat_topic
  end

  test 'only processes user messages' do
    @chat.messages.destroy_all
    @chat.messages.create!(role: 'assistant', content: 'Привет! Чем могу помочь?')
    @chat.messages.create!(role: 'user', content: 'Хочу записаться')
    @chat.messages.create!(role: 'assistant', content: 'Конечно!')

    classifier = ChatTopicClassifier.new(@chat)

    # Проверяем что только user-сообщения попадают в prompt
    messages = classifier.send(:fetch_user_messages)

    assert_equal 1, messages.size
    assert_equal 'Хочу записаться', messages.first
  end

  test 'uses tenant-specific topics when available' do
    tenant_topic = ChatTopic.create!(key: 'custom_topic', label: 'Custom Topic', tenant: @tenant)

    @chat.messages.destroy_all
    @chat.messages.create!(role: 'user', content: 'Custom request')

    mock_response = stub(content: 'custom_topic')
    mock_chat = stub(ask: mock_response)
    RubyLLM.stubs(:chat).returns(mock_chat)

    classifier = ChatTopicClassifier.new(@chat)
    result = classifier.classify

    assert_equal tenant_topic, result
  end
end
