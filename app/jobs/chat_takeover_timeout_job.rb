# frozen_string_literal: true

# Фоновая задача для автоматического возврата чата боту по таймауту
#
# Выполняется после истечения времени manager takeover (по умолчанию 30 минут).
# Проверяет, что чат всё ещё в режиме менеджера и таймаут действительно истёк,
# затем возвращает управление боту.
#
# @note Эта задача автоматически планируется в Manager::TakeoverService.
#   Не вызывайте её напрямую - используйте TakeoverService для перехвата чата.
#
# @example Перехват чата через TakeoverService (автоматически планирует timeout job)
#   result = Manager::TakeoverService.call(chat: chat, user: current_user)
#   # ChatTakeoverTimeoutJob автоматически запланирован на manager_active_until
#
# @see Manager::TakeoverService для логики перехвата
# @see Manager::ReleaseService для логики возврата
# @author AI Assistant
# @since 0.38.0
class ChatTakeoverTimeoutJob < ApplicationJob
  include ErrorLogger
  include TakeoverDurationCalculator

  # Ошибка при неуспешном release - позволяет SolidQueue сделать retry
  class ReleaseFailedError < StandardError; end

  queue_as :default

  # Не ретрить если чат не найден - это ожидаемое поведение
  discard_on ActiveRecord::RecordNotFound

  # Retry при ошибке release - чат не должен застревать в manager_mode
  # SolidQueue не поддерживает символы, используем lambda (согласно CLAUDE.md)
  retry_on ReleaseFailedError, wait: ->(executions) { (executions**2) + 2 }, attempts: 5

  # Выполняет автоматический возврат чата боту
  #
  # @param chat_id [Integer] ID чата для возврата
  # @param expected_takeover_at [Time, nil] ожидаемое время takeover для защиты от race condition
  # @return [void] возвращает чат боту если условия выполнены
  def perform(chat_id, expected_takeover_at = nil)
    chat = Chat.find(chat_id)

    # Проверяем что чат всё ещё в режиме менеджера
    unless chat.manager_mode?
      Rails.logger.info(
        "[ChatTakeoverTimeoutJob] Skipping: chat #{chat_id} is no longer in manager mode " \
        '(likely manually released)'
      )
      return
    end

    # Защита от race condition: если был новый takeover - не возвращаем
    if expected_takeover_at.present?
      actual_takeover_at = chat.taken_at
      if actual_takeover_at.present? && actual_takeover_at > expected_takeover_at
        Rails.logger.info(
          "[ChatTakeoverTimeoutJob] Skipping: chat #{chat_id} has newer takeover " \
          "(expected: #{expected_takeover_at}, actual: #{actual_takeover_at})"
        )
        return
      end
    end

    # Проверяем что таймаут действительно истёк
    unless takeover_expired?(chat)
      Rails.logger.info(
        "[ChatTakeoverTimeoutJob] Skipping: chat #{chat_id} timeout not yet expired " \
        "(active_until: #{chat.manager_active_until})"
      )
      return
    end

    release_chat_to_bot(chat)
  end

  private

  # Проверяет, истёк ли таймаут менеджера
  #
  # @param chat [Chat] чат для проверки
  # @return [Boolean] true если таймаут истёк
  def takeover_expired?(chat)
    return true if chat.manager_active_until.blank?

    chat.manager_active_until <= Time.current
  end

  # Возвращает чат боту через ReleaseService
  #
  # @param chat [Chat] чат для возврата
  # @return [void]
  # @raise [ReleaseFailedError] если release не удался (для retry через SolidQueue)
  def release_chat_to_bot(chat)
    # Сохраняем данные ДО release, так как после release они будут nil
    taken_by_id = chat.taken_by_id
    taken_at = chat.taken_at

    result = Manager::ReleaseService.call(
      chat: chat,
      notify_client: true
    )

    if result.success?
      Rails.logger.info("[ChatTakeoverTimeoutJob] Chat #{chat.id} released to bot by timeout")
      track_timeout_release(chat, taken_by_id:, taken_at:)
    else
      # Критичная ошибка - чат застрянет в manager_mode без retry
      # Выбрасываем исключение чтобы SolidQueue сделал retry
      log_error(
        ReleaseFailedError.new("Failed to release chat #{chat.id}: #{result.error}"),
        { chat_id: chat.id, result_error: result.error, taken_by_id: taken_by_id }
      )
      raise ReleaseFailedError, "Failed to release chat #{chat.id}: #{result.error}"
    end
  end

  # Отслеживает событие возврата чата по таймауту
  #
  # @param chat [Chat] возвращённый чат
  # @param taken_by_id [Integer] ID менеджера (сохранён до release)
  # @param taken_at [Time] время takeover (сохранено до release)
  # @return [void]
  def track_timeout_release(chat, taken_by_id:, taken_at:)
    duration_minutes = calculate_takeover_duration(taken_at)

    AnalyticsService.track(
      AnalyticsService::Events::CHAT_TAKEOVER_ENDED,
      tenant: chat.tenant,
      chat_id: chat.id,
      properties: {
        taken_by_id: taken_by_id,
        reason: 'timeout',
        duration_minutes: duration_minutes
      }
    )
  end

end
