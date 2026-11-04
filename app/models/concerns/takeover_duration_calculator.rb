# frozen_string_literal: true

# Модуль для расчёта продолжительности takeover
#
# Используется в Manager::ReleaseService и ChatTakeoverTimeoutJob
# для единообразного расчёта времени в минутах.
#
# @example Включение в класс
#   class MyService
#     include TakeoverDurationCalculator
#
#     def track_something(taken_at)
#       duration = calculate_takeover_duration(taken_at)
#       # ...
#     end
#   end
#
# @since 0.39.0
module TakeoverDurationCalculator
  # Рассчитывает продолжительность takeover в минутах
  #
  # @param taken_at [Time, nil] время начала takeover
  # @return [Integer] продолжительность в минутах (0 если taken_at nil)
  def calculate_takeover_duration(taken_at)
    return 0 unless taken_at.present?

    ((Time.current - taken_at) / 60).round
  end
end
