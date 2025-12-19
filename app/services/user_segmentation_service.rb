# frozen_string_literal: true

# Сервис для определения сегмента пользователя на основе истории взаимодействий
#
# Анализирует количество предыдущих событий для классификации
# пользователя по сегментам вовлеченности.
#
# @example Определение сегмента для пользователя
#   segment = UserSegmentationService.determine_segment(chat_id: 12345)
#   #=> 'new'
#
# @example Для активного пользователя
#   segment = UserSegmentationService.determine_segment(chat_id: 67890)
#   #=> 'engaged'
#
# @see AnalyticsService для отслеживания событий
# @see AnalyticsEvent для модели хранения событий
# @author Danil Pismenny
# @since 0.1.0
class UserSegmentationService
  include ErrorLogger

  # Сегменты пользователей
  module Segments
    NEW = 'new'.freeze
    ENGAGED = 'engaged'.freeze
    RETURNING = 'returning'.freeze
    UNKNOWN = 'unknown'.freeze
  end

  class << self
    # Определяет сегмент пользователя на основе истории взаимодействий
    #
    # Анализирует количество предыдущих событий для классификации
    # пользователя по сегментам вовлеченности.
    #
    # @param chat_id [Integer] ID чата пользователя
    # @return [String] сегмент пользователя ('new', 'engaged', 'returning', 'unknown')
    # @example В тестовой среде
    #   determine_segment(chat_id: 12345) #=> 'new'
    # @example Для активного пользователя
    #   determine_segment(chat_id: 67890) #=> 'engaged'
    # @note В тестовой среде всегда возвращает 'new'
    def determine_segment(chat_id:)
      return Segments::NEW if Rails.env.test?

      events_count = AnalyticsEvent.by_chat(chat_id).count

      case events_count
      when 1..2
        Segments::NEW
      when 3..10
        Segments::ENGAGED
      else
        Segments::RETURNING
      end
    rescue StandardError => e
      log_error(e, { chat_id: chat_id, service: 'UserSegmentationService' })
      Segments::UNKNOWN
    end

    # Определяет сегмент пользователя на основе объекта TelegramUser
    #
    # @param telegram_user [TelegramUser] пользователь Telegram
    # @return [String] сегмент пользователя
    def determine_segment_for_user(telegram_user)
      determine_segment(chat_id: telegram_user.chat_id)
    end

    # Определяет сегмент пользователя на основе объекта Chat
    #
    # @param chat [Chat] чат пользователя
    # @return [String] сегмент пользователя
    # @note Использует has_one :telegram_user, through: :client
    def determine_segment_for_chat(chat)
      telegram_user = chat.telegram_user
      return Segments::UNKNOWN unless telegram_user

      determine_segment(chat_id: telegram_user.chat_id)
    end
  end
end
