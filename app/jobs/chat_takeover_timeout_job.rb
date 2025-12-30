# frozen_string_literal: true

# Фоновая задача для автоматического возврата чата боту по таймауту
#
# Выполняется после истечения времени manager takeover (по умолчанию 30 минут).
# Проверяет, что чат всё ещё в режиме менеджера и таймаут действительно истёк,
# затем возвращает управление боту.
#
# @example Планирование задачи при takeover
#   ChatTakeoverTimeoutJob.set(wait: 30.minutes).perform_later(chat.id)
#
# @see Manager::TakeoverService для логики перехвата
# @see Manager::ReleaseService для логики возврата
# @author AI Assistant
# @since 0.38.0
class ChatTakeoverTimeoutJob < ApplicationJob
  include ErrorLogger

  queue_as :default

  # Не ретрить если чат не найден - это ожидаемое поведение
  discard_on ActiveRecord::RecordNotFound

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
        "(likely manually released)"
      )
      return
    end

    # Защита от race condition: если был новый takeover - не возвращаем
    if expected_takeover_at.present?
      actual_takeover_at = chat.manager_active_at
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
  def release_chat_to_bot(chat)
    result = Manager::ReleaseService.call(
      chat: chat,
      notify_client: true
    )

    if result.success?
      Rails.logger.info("[ChatTakeoverTimeoutJob] Chat #{chat.id} released to bot by timeout")
      track_timeout_release(chat)
    else
      Rails.logger.warn(
        "[ChatTakeoverTimeoutJob] Failed to release chat #{chat.id}: #{result.error}"
      )
    end
  end

  # Отслеживает событие возврата чата по таймауту
  #
  # @param chat [Chat] возвращённый чат
  # @return [void]
  def track_timeout_release(chat)
    duration_minutes = calculate_takeover_duration(chat)

    AnalyticsService.track(
      AnalyticsService::Events::CHAT_TAKEOVER_ENDED,
      tenant: chat.tenant,
      chat_id: chat.id,
      properties: {
        manager_user_id: chat.manager_user_id,
        reason: 'timeout',
        duration_minutes: duration_minutes
      }
    )
  end

  # Рассчитывает продолжительность takeover в минутах
  #
  # @param chat [Chat] чат
  # @return [Integer] продолжительность в минутах
  def calculate_takeover_duration(chat)
    return 0 unless chat.manager_active_at.present?

    ((Time.current - chat.manager_active_at) / 60).round
  end
end
