# frozen_string_literal: true

# Periodic job для классификации неактивных чатов
#
# Находит чаты без топика, которые были неактивны более N часов,
# и запускает для них классификацию.
#
# Запускается по расписанию (каждый час).
#
# @example Ручной запуск
#   ClassifyInactiveChatsJob.perform_now
#
# @see TopicClassifierConfig#inactivity_hours
# @see ClassifyChatTopicJob
class ClassifyInactiveChatsJob < ApplicationJob
  include ErrorLogger

  queue_as :low_priority

  # Не перезапускаем при ошибках - следующий запуск по расписанию обработает
  # Логируем ошибку перед discard для мониторинга
  discard_on StandardError do |job, error|
    job.send(:log_error, error, context: {
      job: job.class.name,
      error_type: 'job_discarded',
      message: 'Job discarded - will be retried on next scheduled run'
    })
  end

  def perform
    inactive_chats.find_each do |chat|
      ClassifyChatTopicJob.perform_later(chat.id)
    rescue StandardError => e
      log_error(e, context: {
        job: self.class.name,
        chat_id: chat.id
      })
    end
  end

  private

  def inactive_chats
    hours = TopicClassifierConfig.inactivity_hours

    Chat
      .where(chat_topic_id: nil)
      .where('last_message_at < ?', hours.hours.ago)
      .where('last_message_at > ?', 7.days.ago) # не старше недели
  end
end
