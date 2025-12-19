# frozen_string_literal: true

require 'test_helper'

# Тесты для UserSegmentationService
#
# Проверяет корректность определения сегмента пользователя
# через различные точки входа (chat_id, telegram_user, chat)
class UserSegmentationServiceTest < ActiveSupport::TestCase
  setup do
    @tenant = tenants(:one)
    @telegram_user = telegram_users(:one)
    @client = clients(:one)
    @chat = chats(:one)
  end

  test 'determine_segment returns new for test environment' do
    segment = UserSegmentationService.determine_segment(chat_id: 12345)
    assert_equal UserSegmentationService::Segments::NEW, segment
  end

  test 'determine_segment_for_user uses telegram_user chat_id' do
    segment = UserSegmentationService.determine_segment_for_user(@telegram_user)
    assert_equal UserSegmentationService::Segments::NEW, segment
  end

  test 'determine_segment_for_chat accesses telegram_user through client' do
    # This test verifies the has_one :through relationship
    # Chat -> Client -> TelegramUser
    segment = UserSegmentationService.determine_segment_for_chat(@chat)
    assert_equal UserSegmentationService::Segments::NEW, segment
  end

  test 'determine_segment_for_chat handles has_one through correctly' do
    # Verify that chat.telegram_user works through the client association
    assert_equal @client.telegram_user, @chat.telegram_user
    assert_not_nil @chat.telegram_user

    # Verify segment determination works
    segment = UserSegmentationService.determine_segment_for_chat(@chat)
    assert_includes [
      UserSegmentationService::Segments::NEW,
      UserSegmentationService::Segments::ENGAGED,
      UserSegmentationService::Segments::RETURNING
    ], segment
  end
end
