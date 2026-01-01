# frozen_string_literal: true

# Автоматически возвращает диалог боту после таймаута
#
# Выполняется через заданное время после takeover.
# Проверяет что это та же сессия takeover (через taken_at timestamp).
#
# @example Использование
#   ChatTakeoverTimeoutJob.set(wait: 30.minutes).perform_later(chat.id, chat.taken_at.to_i)
#
# @see ChatTakeoverService для логики takeover/release
# @author Danil Pismenny
# @since 0.1.0
class ChatTakeoverTimeoutJob < ApplicationJob
  include ErrorLogger
  include TakeoverDurationCalculator

  # Ошибка при неуспешном release - позволяет SolidQueue сделать retry
  class ReleaseFailedError < StandardError; end

  queue_as :default

  # Retry с экспоненциальной задержкой для временных ошибок
  # SolidQueue не поддерживает символы, используем lambda
  retry_on StandardError,
           wait: ->(executions) { (executions**2) + 2 },
           attempts: 3

  # Не ретраить при отсутствии записи
  discard_on ActiveRecord::RecordNotFound

  # @param chat_id [Integer] ID чата
  # @param taken_at_timestamp [Integer] Unix timestamp времени takeover
  def perform(chat_id, taken_at_timestamp)
    chat = Chat.find_by(id: chat_id)

    unless chat
      Rails.logger.info "[ChatTakeoverTimeoutJob] Chat #{chat_id} not found, skipping"
      return
    end

    unless chat.manager_mode?
      Rails.logger.info "[ChatTakeoverTimeoutJob] Chat #{chat_id} not in manager_mode, skipping"
      return
    end

    # Проверяем что это та же сессия takeover
    # (не новая, начавшаяся после планирования этого job)
    unless chat.taken_at&.to_i == taken_at_timestamp
      Rails.logger.info "[ChatTakeoverTimeoutJob] Chat #{chat_id} has newer takeover session, skipping"
      return
    end

    ChatTakeoverService.new(chat).release!(timeout: true)
    Rails.logger.info "[ChatTakeoverTimeoutJob] Chat #{chat_id} released due to timeout"
  rescue StandardError => e
    log_error(e, context: { chat_id: chat_id, taken_at_timestamp: taken_at_timestamp })
    raise # Re-raise для retry механизма
  end
end
