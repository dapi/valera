# frozen_string_literal: true

# Базовый класс для всех фоновых задач приложения
#
# Предоставляет общую функциональность и настройки для всех
# background jobs в системе.
#
# @example Создание новой задачи
#   class MyJob < ApplicationJob
#     def perform(argument)
#       # реализация задачи
#     end
#   end
#
# @author Danil Pismenny
# @since 0.1.0
class ApplicationJob < ActiveJob::Base
  # Повторяет выполнение при стандартных ошибках
  retry_on StandardError, wait: :exponentially_longer, attempts: 10

  # Автоматически повторяет задачи при deadlock
  # retry_on ActiveRecord::Deadlocked

  # Игнорирует задачи если связанные записи удалены
  # discard_on ActiveJob::DeserializationError
end
