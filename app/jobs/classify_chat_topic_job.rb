# frozen_string_literal: true

# Job для классификации темы чата
#
# Запускается после создания заявки или по таймауту неактивности.
# Использует ChatTopicClassifier для LLM-классификации.
#
# @example Запуск классификации
#   ClassifyChatTopicJob.perform_later(chat.id)
#
# @see ChatTopicClassifier
# @see Booking#after_create_commit
class ClassifyChatTopicJob < ApplicationJob
  include ErrorLogger

  queue_as :low_priority

  # Используем lambda для совместимости с SolidQueue
  retry_on StandardError, wait: ->(executions) { (executions**2) + 2 }, attempts: 3

  # @param chat_id [Integer] ID чата для классификации
  def perform(chat_id)
    chat = Chat.find_by(id: chat_id)
    return if chat.nil?
    return if chat.chat_topic.present?

    ChatTopicClassifier.new(chat).classify
  end
end
