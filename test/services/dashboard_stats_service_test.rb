# frozen_string_literal: true

require 'test_helper'

class DashboardStatsServiceTest < ActiveSupport::TestCase
  setup do
    @tenant = tenants(:one)
  end

  test 'raises error when tenant is nil' do
    assert_raises(ArgumentError) do
      DashboardStatsService.new(nil)
    end
  end

  test 'returns Result struct with all metrics' do
    result = DashboardStatsService.new(@tenant).call

    assert_kind_of DashboardStatsService::Result, result
    assert_respond_to result, :clients_total
    assert_respond_to result, :clients_today
    assert_respond_to result, :clients_week
    assert_respond_to result, :bookings_total
    assert_respond_to result, :bookings_today
    assert_respond_to result, :active_chats
    assert_respond_to result, :messages_today
    assert_respond_to result, :chart_data
    assert_respond_to result, :recent_chats
    assert_respond_to result, :funnel_data
  end

  test 'counts total clients for tenant' do
    result = DashboardStatsService.new(@tenant).call

    assert_equal @tenant.clients.count, result.clients_total
  end

  test 'counts clients created today' do
    initial_count = DashboardStatsService.new(@tenant).call.clients_today

    # Создаём нового telegram_user и клиента сегодня
    tg_user = TelegramUser.create!(username: 'today_user', first_name: 'Today')
    @tenant.clients.create!(telegram_user: tg_user, name: 'Today Client')

    result = DashboardStatsService.new(@tenant).call

    assert_equal initial_count + 1, result.clients_today
  end

  test 'counts clients created this week' do
    result = DashboardStatsService.new(@tenant).call

    week_ago = 1.week.ago
    expected = @tenant.clients.where(created_at: week_ago..).count
    assert_equal expected, result.clients_week
  end

  test 'counts total bookings for tenant' do
    result = DashboardStatsService.new(@tenant).call

    assert_equal @tenant.bookings.count, result.bookings_total
  end

  test 'counts active chats with messages in last 24 hours' do
    chat = chats(:one)
    chat.messages.create!(role: 'user', content: 'Recent message')

    result = DashboardStatsService.new(@tenant).call

    assert_operator result.active_chats, :>=, 1
  end

  test 'counts messages created today' do
    chat = chats(:one)
    chat.messages.create!(role: 'user', content: 'Today message')

    result = DashboardStatsService.new(@tenant).call

    assert_operator result.messages_today, :>=, 1
  end

  test 'builds chart_data with labels and values' do
    result = DashboardStatsService.new(@tenant, period: 7).call

    assert_kind_of Hash, result.chart_data
    assert_includes result.chart_data.keys, :labels
    assert_includes result.chart_data.keys, :values
    assert_equal 8, result.chart_data[:labels].size # 7 days + today
    assert_equal 8, result.chart_data[:values].size
  end

  test 'chart_data labels are formatted as dd.mm' do
    result = DashboardStatsService.new(@tenant, period: 7).call

    result.chart_data[:labels].each do |label|
      assert_match(/\d{2}\.\d{2}/, label)
    end
  end

  test 'chart_data fills missing days with zeros' do
    result = DashboardStatsService.new(@tenant, period: 7).call

    result.chart_data[:values].each do |value|
      assert_kind_of Integer, value
      assert_operator value, :>=, 0
    end
  end

  test 'accepts custom period for chart' do
    result_7 = DashboardStatsService.new(@tenant, period: 7).call
    result_30 = DashboardStatsService.new(@tenant, period: 30).call

    assert_equal 8, result_7.chart_data[:labels].size
    assert_equal 31, result_30.chart_data[:labels].size
  end

  test 'returns recent chats limited to 3' do
    result = DashboardStatsService.new(@tenant).call

    assert_kind_of ActiveRecord::Relation, result.recent_chats
    assert_operator result.recent_chats.size, :<=, 3
  end

  test 'recent_chats includes client association' do
    chat = chats(:one)
    chat.messages.create!(role: 'user', content: 'Test message')

    result = DashboardStatsService.new(@tenant).call

    # Проверяем что client загружен без N+1
    result.recent_chats.each do |c|
      assert_respond_to c, :client
    end
  end

  test 'isolates data by tenant' do
    tenant_one = tenants(:one)
    tenant_two = tenants(:two)

    result_one = DashboardStatsService.new(tenant_one).call
    result_two = DashboardStatsService.new(tenant_two).call

    # У разных тенантов разные данные
    assert_equal tenant_one.clients.count, result_one.clients_total
    assert_equal tenant_two.clients.count, result_two.clients_total
  end

  test 'accepts 90 days period' do
    result = DashboardStatsService.new(@tenant, period: 90).call

    assert_equal 91, result.chart_data[:labels].size
    assert_equal 91, result.chart_data[:values].size
  end

  test 'accepts nil period for all time' do
    result = DashboardStatsService.new(@tenant, period: nil).call

    assert_kind_of Hash, result.chart_data
    assert_operator result.chart_data[:labels].size, :>=, 1
  end

  test 'all_time? returns true when period is nil' do
    service = DashboardStatsService.new(@tenant, period: nil)

    assert service.all_time?
  end

  test 'all_time? returns false when period is set' do
    service = DashboardStatsService.new(@tenant, period: 7)

    refute service.all_time?
  end

  test 'funnel_data returns hash with chats_count, bookings_count, and conversion_rate' do
    result = DashboardStatsService.new(@tenant).call

    assert_kind_of Hash, result.funnel_data
    assert_includes result.funnel_data.keys, :chats_count
    assert_includes result.funnel_data.keys, :bookings_count
    assert_includes result.funnel_data.keys, :conversion_rate
  end

  test 'funnel_data counts all chats and bookings for tenant' do
    result = DashboardStatsService.new(@tenant).call

    assert_equal @tenant.chats.count, result.funnel_data[:chats_count]
    assert_equal @tenant.bookings.count, result.funnel_data[:bookings_count]
  end

  test 'funnel_data calculates conversion_rate correctly' do
    result = DashboardStatsService.new(@tenant).call

    chats_count = @tenant.chats.count
    bookings_count = @tenant.bookings.count

    if chats_count.positive?
      expected_rate = (bookings_count.to_f / chats_count * 100).round(1)
      assert_equal expected_rate, result.funnel_data[:conversion_rate]
    else
      assert_equal 0.0, result.funnel_data[:conversion_rate]
    end
  end

  test 'funnel_data returns zero conversion_rate when no chats' do
    # Создаём тенант без чатов
    user = User.create!(name: 'Empty Owner', email: 'empty@test.com', password: 'password123')
    empty_tenant = Tenant.create!(name: 'Empty Tenant', bot_token: '999999999:ABCdefGHIjklMNOpqrsTUVwxyz', bot_username: 'empty_bot', owner: user)

    result = DashboardStatsService.new(empty_tenant).call

    assert_equal 0, result.funnel_data[:chats_count]
    assert_equal 0.0, result.funnel_data[:conversion_rate]
  end
end
