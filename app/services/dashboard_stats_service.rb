# frozen_string_literal: true

# Сервис для сбора статистики дашборда тенанта
#
# Собирает KPI метрики, данные для графика активности
# и последние активные чаты для отображения на главной странице.
#
# @example Получение статистики
#   stats = DashboardStatsService.new(tenant, period: 7).call
#   stats.clients_total #=> 142
#   stats.chart_data    #=> { labels: [...], values: [...] }
#
# @see Tenants::HomeController
class DashboardStatsService
  include ErrorLogger

  Result = Struct.new(
    :clients_total,
    :clients_today,
    :clients_week,
    :bookings_total,
    :bookings_today,
    :active_chats,
    :messages_today,
    :avg_messages_per_dialog,
    :chart_data,
    :recent_chats,
    :funnel_data,
    :funnel_trend,
    :llm_costs,
    keyword_init: true
  )

  # @param tenant [Tenant] тенант для которого собирается статистика
  # @param period [Integer, nil] период для графика в днях (по умолчанию 7, nil = всё время)
  def initialize(tenant, period: 7)
    raise ArgumentError, 'tenant is required' if tenant.nil?

    @tenant = tenant
    @period = period
  end

  def all_time?
    period.nil?
  end

  # Собирает и возвращает все метрики дашборда
  #
  # @return [Result] структура со всеми метриками
  def call
    Result.new(
      clients_total: clients.count,
      clients_today: clients.where(created_at: today_range).count,
      clients_week: clients.where(created_at: week_range).count,
      bookings_total: bookings.count,
      bookings_today: bookings.where(created_at: today_range).count,
      active_chats: active_chats_count,
      messages_today: messages_today_count,
      avg_messages_per_dialog: calculate_avg_messages_per_dialog,
      chart_data: build_chart_data,
      recent_chats: fetch_recent_chats,
      funnel_data: build_funnel_data,
      funnel_trend: build_funnel_trend,
      llm_costs: build_llm_costs
    )
  end

  private

  attr_reader :tenant, :period

  def today_range
    Date.current.all_day
  end

  def week_range
    1.week.ago..Time.current
  end

  def clients
    tenant.clients
  end

  def bookings
    tenant.bookings
  end

  def active_chats_count
    tenant.chats
          .joins(:messages)
          .where(messages: { created_at: 24.hours.ago.. })
          .distinct
          .count
  end

  def messages_today_count
    Message.joins(:chat)
           .where(chats: { tenant_id: tenant.id })
           .where(created_at: today_range)
           .count
  end

  # Рассчитывает среднее количество сообщений в диалоге (за всё время)
  #
  # Использует два COUNT запроса вместо загрузки данных в память,
  # что оптимально для тенантов с большим количеством чатов.
  #
  # При ошибках БД возвращает 0.0, чтобы не блокировать загрузку dashboard.
  #
  # @return [Float] среднее количество сообщений, округленное до 1 знака
  def calculate_avg_messages_per_dialog
    chats_with_messages_count = tenant.chats.joins(:messages).distinct.count
    return 0.0 if chats_with_messages_count.zero?

    total_messages = Message.joins(:chat).where(chats: { tenant_id: tenant.id }).count
    (total_messages.to_f / chats_with_messages_count).round(1)
  rescue ActiveRecord::StatementInvalid => e
    log_error(e, { method: 'calculate_avg_messages_per_dialog', tenant_id: tenant.id })
    0.0
  end

  def build_chart_data
    base_query = Message.joins(:chat).where(chats: { tenant_id: tenant.id })
    chart_period = effective_chart_period

    raw_data = base_query
               .where(created_at: chart_period.days.ago.beginning_of_day..)
               .group('DATE(messages.created_at)')
               .count

    date_range = (chart_period.days.ago.to_date..Date.current)
    labels = date_range.map { |d| d.strftime('%d.%m') }
    values = date_range.map { |d| raw_data[d] || 0 }

    { labels: labels, values: values }
  end

  def effective_chart_period
    return period if period

    first_message = Message.joins(:chat)
                           .where(chats: { tenant_id: tenant.id })
                           .minimum(:created_at)
    return 30 unless first_message

    [ (Date.current - first_message.to_date).to_i, 365 ].min
  end

  def fetch_recent_chats
    tenant.chats
          .joins(:messages)
          .includes(:client, :messages)
          .where(messages: { created_at: 7.days.ago.. })
          .order('messages.created_at DESC')
          .distinct
          .limit(3)
  end

  def build_funnel_data
    chats_count = tenant.chats.count
    bookings_count = bookings.count
    conversion_rate = chats_count.positive? ? (bookings_count.to_f / chats_count * 100).round(1) : 0.0

    {
      chats_count: chats_count,
      bookings_count: bookings_count,
      conversion_rate: conversion_rate
    }
  end

  def build_funnel_trend
    weeks = period_weeks
    return [] if weeks.empty?

    weeks.map do |week_start, week_end|
      chats_count = tenant.chats.where(created_at: week_start..week_end).count
      bookings_count = tenant.bookings.where(created_at: week_start..week_end).count
      conversion = chats_count.positive? ? (bookings_count.to_f / chats_count * 100).round(1) : 0.0

      {
        week_start: week_start.to_date,
        week_end: week_end.to_date,
        chats: chats_count,
        bookings: bookings_count,
        conversion: conversion
      }
    end
  end

  def period_weeks
    chart_period = effective_chart_period
    end_date = Date.current.end_of_week
    start_date = (chart_period.days.ago.to_date).beginning_of_week

    weeks = []
    current_week_start = start_date

    while current_week_start <= end_date
      week_end = [ current_week_start.end_of_week, Date.current ].min
      weeks << [ current_week_start.beginning_of_day, week_end.end_of_day ]
      current_week_start += 1.week
    end

    weeks
  end

  def build_llm_costs
    calculator = LlmCostCalculator.new(tenant, period: effective_chart_period)

    totals = calculator.calculate_totals
    by_model = calculator.calculate_by_model
    by_day = calculator.calculate_by_day

    {
      totals: totals,
      by_model: by_model,
      by_day: by_day,
      chart_data: {
        labels: by_day.map { |d| d.date.strftime('%d.%m') },
        values: by_day.map { |d| d.total_cost.round(4) }
      }
    }
  end
end
