# frozen_string_literal: true

# Job для классификации темы чата
#
# Запускается после создания заявки или по таймауту неактивности.
# Использует ChatTopicClassifier для LLM-классификации.
#
# Гарантируется что для одного чата одновременно выполняется только один job
# благодаря GoodJob concurrency control.
#
# @example Запуск классификации
#   ClassifyChatTopicJob.perform_later(chat.id)
#
# @see ChatTopicClassifier
# @see Booking#after_create_commit
class ClassifyChatTopicJob < ApplicationJob
  include ErrorLogger
  include GoodJob::ActiveJobExtensions::Concurrency

  queue_as :low_priority

  # Используем lambda для совместимости с SolidQueue
  retry_on StandardError, wait: ->(executions) { (executions**2) + 2 }, attempts: 3

  # Гарантируем что для одного chat_id выполняется только один job
  # Дубликаты будут отброшены (не будут ждать в очереди)
  good_job_control_concurrency_with(
    perform_limit: 1,
    enqueue_limit: 1,
    key: -> { "classify_chat_topic_#{arguments.first}" }
  )

  # @param chat_id [Integer] ID чата для классификации
  def perform(chat_id)
    return unless TopicClassifierConfig.enabled

    chat = Chat.find_by(id: chat_id)

    if chat.nil?
      Rails.logger.warn "[ClassifyChatTopicJob] Chat not found: #{chat_id} - possibly deleted"
      return
    end

    return if chat.chat_topic.present?

    ChatTopicClassifier.new(chat).classify
  end
end
