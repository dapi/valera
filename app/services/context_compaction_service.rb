# frozen_string_literal: true

# Сервис для автоматического сжатия контекстного окна диалога
#
# Управляет размером контекста диалога, автоматически сжимая старые сообщения
# при достижении максимального размера для оптимизации токенов и производительности.
#
# @example Сжатие контекста чата
#   ContextCompactionService.compact_if_needed(chat)
#
# @example Проверка необходимости сжатия
#   needed = ContextCompactionService.compaction_needed?(chat)
#   #=> true/false
#
# @see Chat модель диалога
# @see Message модель сообщений
# @author Danil Pismenny
# @since 0.1.0
class ContextCompactionService
  include ErrorLogger

  # Максимальное количество сообщений в контексте перед сжатием
  MAX_MESSAGES_BEFORE_COMPACT = 20

  # Количество сообщений для сохранения после сжатия
  MESSAGES_TO_KEEP_AFTER_COMPACT = 10

  class << self
    # Проверяет, необходимо ли сжатие контекста
    #
    # @param chat [Chat] чат для проверки
    # @return [Boolean] true если сжатие необходимо
    def compaction_needed?(chat)
      chat.messages.count > MAX_MESSAGES_BEFORE_COMPACT
    rescue StandardError => e
      log_error(e, { chat_id: chat.id, service: 'ContextCompactionService' })
      false
    end

    # Выполняет сжатие контекста если необходимо
    #
    # @param chat [Chat] чат для сжатия
    # @return [Boolean] true если сжатие было выполнено
    def compact_if_needed(chat)
      return false unless compaction_needed?(chat)

      compact_context(chat)
      true
    rescue StandardError => e
      log_error(e, { chat_id: chat.id, service: 'ContextCompactionService' })
      false
    end

    # Принудительно выполняет сжатие контекста
    #
    # @param chat [Chat] чат для сжатия
    # @param keep_count [Integer] количество сообщений для сохранения
    # @return [Integer] количество удаленных сообщений
    def compact_context(chat, keep_count: MESSAGES_TO_KEEP_AFTER_COMPACT)
      messages = chat.messages.order(:created_at)
      total_count = messages.count

      return 0 if total_count <= keep_count

      # Сохраняем последние keep_count сообщений + системные инструкции
      messages_to_keep = messages.last(keep_count)
      system_messages = messages.where(role: :system)

      # Удаляем старые сообщения, которые не являются системными
      messages_to_delete = messages.where.not(id: messages_to_keep + system_messages)
      deleted_count = messages_to_delete.count

      messages_to_delete.delete_all

      # Логируем операцию сжатия
      Rails.logger.info "Context compacted for chat #{chat.id}: " \
                       "deleted #{deleted_count} messages, kept #{messages_to_keep.count + system_messages.count}"

      deleted_count
    rescue StandardError => e
      log_error(e, { chat_id: chat.id, service: 'ContextCompactionService', keep_count: keep_count })
      0
    end

    # Возвращает статистику по контексту чата
    #
    # @param chat [Chat] чат для анализа
    # @return [Hash] статистика контекста
    def context_stats(chat)
      messages = chat.messages

      {
        total_messages: messages.count,
        system_messages: messages.where(role: :system).count,
        user_messages: messages.where(role: :user).count,
        assistant_messages: messages.where(role: :assistant).count,
        tool_calls_count: messages.joins(:tool_calls).count,
        oldest_message_date: messages.minimum(:created_at),
        newest_message_date: messages.maximum(:created_at),
        compaction_needed: compaction_needed?(chat)
      }
    rescue StandardError => e
      log_error(e, { chat_id: chat.id, service: 'ContextCompactionService' })
      { error: e.message }
    end

    # Выполняет сжатие с сохранением ключевых сообщений
    #
    # @param chat [Chat] чат для сжатия
    # @return [Integer] количество удаленных сообщений
    def smart_compact(chat)
      messages = chat.messages.includes(:tool_calls).order(:created_at)

      # Сохраняем системные сообщения
      system_messages = messages.where(role: :system)

      # Сохраняем последние сообщения
      recent_messages = messages.last(MESSAGES_TO_KEEP_AFTER_COMPACT)

      # Сохраняем сообщения с tool calls (важные для контекста)
      tool_call_messages = messages.joins(:tool_calls)

      # Объединяем все важные сообщения
      important_messages = (system_messages + recent_messages + tool_call_messages).uniq

      # Удаляем остальные сообщения
      messages_to_delete = messages.where.not(id: important_messages)
      deleted_count = messages_to_delete.count

      messages_to_delete.delete_all

      Rails.logger.info "Smart context compacted for chat #{chat.id}: " \
                       "deleted #{deleted_count} messages, kept #{important_messages.count}"

      deleted_count
    rescue StandardError => e
      log_error(e, { chat_id: chat.id, service: 'ContextCompactionService' })
      0
    end
  end
end