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
      chart_data: build_chart_data,
      recent_chats: fetch_recent_chats,
      funnel_data: build_funnel_data
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
end
