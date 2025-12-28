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
  Result = Struct.new(
    :clients_total,
    :clients_today,
    :clients_week,
    :bookings_total,
    :bookings_today,
    :active_chats,
    :messages_today,
    :chart_data,
    :recent_chats,
    :funnel_data,
    :funnel_trend,
    :llm_costs,
    keyword_init: true
  )

  # Структура для понедельных данных воронки
  WeekData = Struct.new(:week_start, :week_end, :chats_count, :bookings_count, :conversion_rate, keyword_init: true)

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

  # Рассчитывает понедельный тренд воронки конверсии
  # Возвращает данные за последние N недель в зависимости от периода
  #
  # @return [Array<WeekData>] массив данных по неделям
  def build_funnel_trend
    weeks_count = calculate_weeks_count
    return [] if weeks_count.zero?

    start_date = (Date.current - (weeks_count - 1).weeks).beginning_of_week.beginning_of_day
    end_date = Date.current.end_of_week.end_of_day
    date_range = start_date..end_date

    # 2 SQL запроса вместо 2×N (группировка по дате начала недели)
    chats_by_week = tenant.chats
                          .where(created_at: date_range)
                          .group("DATE(DATE_TRUNC('week', created_at))")
                          .count

    bookings_by_week = bookings
                       .where(created_at: date_range)
                       .group("DATE(DATE_TRUNC('week', created_at))")
                       .count

    # Собираем недели от старой к новой
    (0...weeks_count).map do |i|
      week_start = (Date.current - (weeks_count - 1 - i).weeks).beginning_of_week
      week_key = week_start.to_date

      chats_count = chats_by_week[week_key] || 0
      bookings_count = bookings_by_week[week_key] || 0
      rate = chats_count.positive? ? (bookings_count.to_f / chats_count * 100).round(1) : 0.0

      WeekData.new(
        week_start: week_start,
        week_end: week_start.end_of_week,
        chats_count: chats_count,
        bookings_count: bookings_count,
        conversion_rate: rate
      )
    end
  end

  # Определяет количество недель для отображения тренда
  def calculate_weeks_count
    return 8 if period.nil? # Для "всё время" показываем 8 недель

    case period
    when 7 then 4    # 4 недели для 7-дневного периода
    when 30 then 8   # 8 недель для 30-дневного периода
    when 90 then 12  # 12 недель для 90-дневного периода
    else 4
    end
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
