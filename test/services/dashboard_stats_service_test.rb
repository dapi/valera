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
    assert_respond_to result, :avg_messages_per_dialog
    assert_respond_to result, :chart_data
    assert_respond_to result, :recent_chats
    assert_respond_to result, :funnel_data
    assert_respond_to result, :funnel_trend
    assert_respond_to result, :hourly_distribution
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

  # === avg_messages_per_dialog ===

  test 'avg_messages_per_dialog returns float' do
    result = DashboardStatsService.new(@tenant).call

    assert_kind_of Float, result.avg_messages_per_dialog
  end

  test 'avg_messages_per_dialog returns 0.0 when no chats with messages' do
    # Создаём тенант без чатов с сообщениями
    user = User.create!(name: 'Empty Owner', email: 'empty_avg@test.com', password: 'password123')
    empty_tenant = Tenant.create!(name: 'Empty Tenant Avg', bot_token: '888888888:ABCdefGHIjklMNOpqrsTUVwxyz', bot_username: 'empty_avg_bot', owner: user)

    result = DashboardStatsService.new(empty_tenant).call

    assert_equal 0.0, result.avg_messages_per_dialog
  end

  test 'avg_messages_per_dialog calculates correctly with one chat' do
    # Создаём тенант с одним чатом и несколькими сообщениями
    user = User.create!(name: 'Single Owner', email: 'single_avg@test.com', password: 'password123')
    tenant = Tenant.create!(name: 'Single Tenant', bot_token: '777777777:ABCdefGHIjklMNOpqrsTUVwxyz', bot_username: 'single_bot', owner: user)
    tg_user = TelegramUser.create!(username: 'single_user', first_name: 'Single')
    client = tenant.clients.create!(telegram_user: tg_user, name: 'Single Client')
    chat = tenant.chats.create!(client: client)

    # Добавляем 5 сообщений
    5.times { |i| chat.messages.create!(role: 'user', content: "Message #{i}") }

    result = DashboardStatsService.new(tenant).call

    assert_equal 5.0, result.avg_messages_per_dialog
  end

  test 'avg_messages_per_dialog calculates average across multiple chats' do
    # Создаём тенант с несколькими чатами
    user = User.create!(name: 'Multi Owner', email: 'multi_avg@test.com', password: 'password123')
    tenant = Tenant.create!(name: 'Multi Tenant', bot_token: '666666666:ABCdefGHIjklMNOpqrsTUVwxyz', bot_username: 'multi_bot', owner: user)

    # Чат 1: 4 сообщения
    tg_user1 = TelegramUser.create!(username: 'multi_user1', first_name: 'User1')
    client1 = tenant.clients.create!(telegram_user: tg_user1, name: 'Client 1')
    chat1 = tenant.chats.create!(client: client1)
    4.times { |i| chat1.messages.create!(role: 'user', content: "Chat1 Message #{i}") }

    # Чат 2: 6 сообщений
    tg_user2 = TelegramUser.create!(username: 'multi_user2', first_name: 'User2')
    client2 = tenant.clients.create!(telegram_user: tg_user2, name: 'Client 2')
    chat2 = tenant.chats.create!(client: client2)
    6.times { |i| chat2.messages.create!(role: 'user', content: "Chat2 Message #{i}") }

    result = DashboardStatsService.new(tenant).call

    # Среднее: (4 + 6) / 2 = 5.0
    assert_equal 5.0, result.avg_messages_per_dialog
  end

  test 'avg_messages_per_dialog rounds to one decimal place' do
    # Создаём тенант с чатами, дающими дробное среднее
    user = User.create!(name: 'Decimal Owner', email: 'decimal_avg@test.com', password: 'password123')
    tenant = Tenant.create!(name: 'Decimal Tenant', bot_token: '555555555:ABCdefGHIjklMNOpqrsTUVwxyz', bot_username: 'decimal_bot', owner: user)

    # Чат 1: 3 сообщения
    tg_user1 = TelegramUser.create!(username: 'decimal_user1', first_name: 'Dec1')
    client1 = tenant.clients.create!(telegram_user: tg_user1, name: 'Decimal Client 1')
    chat1 = tenant.chats.create!(client: client1)
    3.times { |i| chat1.messages.create!(role: 'user', content: "Chat1 Msg #{i}") }

    # Чат 2: 4 сообщения
    tg_user2 = TelegramUser.create!(username: 'decimal_user2', first_name: 'Dec2')
    client2 = tenant.clients.create!(telegram_user: tg_user2, name: 'Decimal Client 2')
    chat2 = tenant.chats.create!(client: client2)
    4.times { |i| chat2.messages.create!(role: 'user', content: "Chat2 Msg #{i}") }

    result = DashboardStatsService.new(tenant).call

    # Среднее: (3 + 4) / 2 = 3.5
    assert_equal 3.5, result.avg_messages_per_dialog
  end

  test 'avg_messages_per_dialog ignores chats without messages' do
    # Создаём тенант с чатом без сообщений и чатом с сообщениями
    user = User.create!(name: 'Mixed Owner', email: 'mixed_avg@test.com', password: 'password123')
    tenant = Tenant.create!(name: 'Mixed Tenant', bot_token: '444444444:ABCdefGHIjklMNOpqrsTUVwxyz', bot_username: 'mixed_bot', owner: user)

    # Чат 1: 0 сообщений (пустой)
    tg_user1 = TelegramUser.create!(username: 'mixed_user1', first_name: 'Mixed1')
    client1 = tenant.clients.create!(telegram_user: tg_user1, name: 'Mixed Client 1')
    tenant.chats.create!(client: client1)

    # Чат 2: 6 сообщений
    tg_user2 = TelegramUser.create!(username: 'mixed_user2', first_name: 'Mixed2')
    client2 = tenant.clients.create!(telegram_user: tg_user2, name: 'Mixed Client 2')
    chat2 = tenant.chats.create!(client: client2)
    6.times { |i| chat2.messages.create!(role: 'user', content: "Chat2 Msg #{i}") }

    result = DashboardStatsService.new(tenant).call

    # Только чат с сообщениями учитывается: 6 / 1 = 6.0
    assert_equal 6.0, result.avg_messages_per_dialog
  end

  test 'avg_messages_per_dialog isolates data by tenant' do
    # Tenant 1 с 2 сообщениями в 1 чате
    user1 = User.create!(name: 'Isolation Owner 1', email: 'isolation1@test.com', password: 'password123')
    tenant1 = Tenant.create!(name: 'Isolation Tenant 1', bot_token: '111111111:ISOLATEabc', bot_username: 'isolation_bot1', owner: user1)
    tg_user1 = TelegramUser.create!(username: 'isolation_user1', first_name: 'Iso1')
    client1 = tenant1.clients.create!(telegram_user: tg_user1, name: 'Isolation Client 1')
    chat1 = tenant1.chats.create!(client: client1)
    2.times { |i| chat1.messages.create!(role: 'user', content: "Tenant1 Msg #{i}") }

    # Tenant 2 с 10 сообщениями в 1 чате
    user2 = User.create!(name: 'Isolation Owner 2', email: 'isolation2@test.com', password: 'password123')
    tenant2 = Tenant.create!(name: 'Isolation Tenant 2', bot_token: '222222222:ISOLATEdef', bot_username: 'isolation_bot2', owner: user2)
    tg_user2 = TelegramUser.create!(username: 'isolation_user2', first_name: 'Iso2')
    client2 = tenant2.clients.create!(telegram_user: tg_user2, name: 'Isolation Client 2')
    chat2 = tenant2.chats.create!(client: client2)
    10.times { |i| chat2.messages.create!(role: 'user', content: "Tenant2 Msg #{i}") }

    result1 = DashboardStatsService.new(tenant1).call
    result2 = DashboardStatsService.new(tenant2).call

    # Каждый тенант видит только свои данные
    assert_equal 2.0, result1.avg_messages_per_dialog
    assert_equal 10.0, result2.avg_messages_per_dialog
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

  # === llm_costs ===

  test 'returns llm_costs in result' do
    result = DashboardStatsService.new(@tenant).call

    assert_respond_to result, :llm_costs
    assert_kind_of Hash, result.llm_costs
  end

  test 'llm_costs contains totals, by_model, by_day and chart_data' do
    result = DashboardStatsService.new(@tenant).call

    assert_includes result.llm_costs.keys, :totals
    assert_includes result.llm_costs.keys, :by_model
    assert_includes result.llm_costs.keys, :by_day
    assert_includes result.llm_costs.keys, :chart_data
  end

  test 'llm_costs totals is a Totals struct' do
    result = DashboardStatsService.new(@tenant).call

    assert_kind_of LlmCostCalculator::Totals, result.llm_costs[:totals]
    assert_respond_to result.llm_costs[:totals], :input_tokens
    assert_respond_to result.llm_costs[:totals], :output_tokens
    assert_respond_to result.llm_costs[:totals], :total_cost
  end

  test 'llm_costs by_model is an array' do
    result = DashboardStatsService.new(@tenant).call

    assert_kind_of Array, result.llm_costs[:by_model]
  end

  test 'llm_costs by_day is an array' do
    result = DashboardStatsService.new(@tenant).call

    assert_kind_of Array, result.llm_costs[:by_day]
  end

  test 'llm_costs chart_data has labels and values' do
    result = DashboardStatsService.new(@tenant).call

    assert_includes result.llm_costs[:chart_data].keys, :labels
    assert_includes result.llm_costs[:chart_data].keys, :values
    assert_kind_of Array, result.llm_costs[:chart_data][:labels]
    assert_kind_of Array, result.llm_costs[:chart_data][:values]
  end

  test 'llm_costs chart_data labels match period' do
    result = DashboardStatsService.new(@tenant, period: 7).call

    assert_equal 8, result.llm_costs[:chart_data][:labels].size
    assert_equal 8, result.llm_costs[:chart_data][:values].size
  end

  test 'llm_costs includes token and cost data from messages' do
    chat = chats(:one)
    chat.messages.destroy_all

    model = models(:one)
    chat.messages.create!(role: 'user', content: 'Test', model: model, input_tokens: 1000, output_tokens: 500)

    result = DashboardStatsService.new(@tenant).call

    assert_equal 1000, result.llm_costs[:totals].input_tokens
    assert_equal 500, result.llm_costs[:totals].output_tokens
  end

  # === funnel_trend ===

  test 'returns funnel_trend in result' do
    result = DashboardStatsService.new(@tenant).call

    assert_respond_to result, :funnel_trend
    assert_kind_of Array, result.funnel_trend
  end

  test 'funnel_trend returns WeekData structs' do
    result = DashboardStatsService.new(@tenant).call

    result.funnel_trend.each do |week_data|
      assert_kind_of DashboardStatsService::WeekData, week_data
      assert_respond_to week_data, :week_start
      assert_respond_to week_data, :week_end
      assert_respond_to week_data, :chats_count
      assert_respond_to week_data, :bookings_count
      assert_respond_to week_data, :conversion_rate
    end
  end

  test 'funnel_trend returns 4 weeks for 7-day period' do
    result = DashboardStatsService.new(@tenant, period: 7).call

    assert_equal 4, result.funnel_trend.size
  end

  test 'funnel_trend returns 8 weeks for 30-day period' do
    result = DashboardStatsService.new(@tenant, period: 30).call

    assert_equal 8, result.funnel_trend.size
  end

  test 'funnel_trend returns 12 weeks for 90-day period' do
    result = DashboardStatsService.new(@tenant, period: 90).call

    assert_equal 12, result.funnel_trend.size
  end

  test 'funnel_trend returns 8 weeks for all-time period' do
    result = DashboardStatsService.new(@tenant, period: nil).call

    assert_equal 8, result.funnel_trend.size
  end

  test 'funnel_trend weeks are ordered chronologically (oldest first)' do
    result = DashboardStatsService.new(@tenant).call

    return if result.funnel_trend.size < 2

    result.funnel_trend.each_cons(2) do |earlier, later|
      assert_operator earlier.week_start, :<, later.week_start
    end
  end

  test 'funnel_trend week_start is always a Monday' do
    result = DashboardStatsService.new(@tenant).call

    result.funnel_trend.each do |week_data|
      assert_equal 1, week_data.week_start.cwday, 'week_start should be Monday'
    end
  end

  test 'funnel_trend week_end is always a Sunday' do
    result = DashboardStatsService.new(@tenant).call

    result.funnel_trend.each do |week_data|
      assert_equal 0, week_data.week_end.wday, 'week_end should be Sunday'
    end
  end

  test 'funnel_trend counts chats and bookings correctly' do
    # Создаём чат и букинг на текущей неделе
    tg_user = TelegramUser.create!(username: 'trend_test_user', first_name: 'Trend')
    client = @tenant.clients.create!(telegram_user: tg_user, name: 'Trend Client')
    chat = @tenant.chats.create!(client: client)
    @tenant.bookings.create!(chat: chat, client: client)

    result = DashboardStatsService.new(@tenant).call
    current_week = result.funnel_trend.last

    assert_operator current_week.chats_count, :>=, 1
    assert_operator current_week.bookings_count, :>=, 1
  end

  test 'funnel_trend calculates conversion_rate correctly' do
    result = DashboardStatsService.new(@tenant).call

    result.funnel_trend.each do |week_data|
      if week_data.chats_count.positive?
        expected_rate = (week_data.bookings_count.to_f / week_data.chats_count * 100).round(1)
        assert_equal expected_rate, week_data.conversion_rate
      else
        assert_equal 0.0, week_data.conversion_rate
      end
    end
  end

  test 'funnel_trend returns zero counts for weeks without data' do
    # Создаём новый тенант без данных
    user = User.create!(name: 'Empty Trend Owner', email: 'empty_trend@test.com', password: 'password123')
    empty_tenant = Tenant.create!(name: 'Empty Trend Tenant', bot_token: '888888888:ABCdefGHIjklMNOpqrsTUVwxyz', bot_username: 'empty_trend_bot', owner: user)

    result = DashboardStatsService.new(empty_tenant).call

    result.funnel_trend.each do |week_data|
      assert_equal 0, week_data.chats_count
      assert_equal 0, week_data.bookings_count
      assert_equal 0.0, week_data.conversion_rate
    end
  end

  test 'funnel_trend isolates data by tenant' do
    # Tenant 1 с 1 чатом и 1 букингом
    user1 = User.create!(name: 'Trend Iso 1', email: 'trend_iso1@test.com', password: 'password123')
    tenant1 = Tenant.create!(name: 'Trend Iso Tenant 1', bot_token: '111111111:TRENDiso1', bot_username: 'trend_iso_bot1', owner: user1)
    tg_user1 = TelegramUser.create!(username: 'trend_iso_user1', first_name: 'TrendIso1')
    client1 = tenant1.clients.create!(telegram_user: tg_user1, name: 'Trend Iso Client 1')
    chat1 = tenant1.chats.create!(client: client1)
    tenant1.bookings.create!(chat: chat1, client: client1)

    # Tenant 2 с 1 чатом и 5 букингами
    user2 = User.create!(name: 'Trend Iso 2', email: 'trend_iso2@test.com', password: 'password123')
    tenant2 = Tenant.create!(name: 'Trend Iso Tenant 2', bot_token: '222222222:TRENDiso2', bot_username: 'trend_iso_bot2', owner: user2)
    tg_user2 = TelegramUser.create!(username: 'trend_iso_user2', first_name: 'TrendIso2')
    client2 = tenant2.clients.create!(telegram_user: tg_user2, name: 'Trend Iso Client 2')
    chat2 = tenant2.chats.create!(client: client2)
    5.times { tenant2.bookings.create!(chat: chat2, client: client2) }

    result1 = DashboardStatsService.new(tenant1).call
    result2 = DashboardStatsService.new(tenant2).call

    current_week1 = result1.funnel_trend.last
    current_week2 = result2.funnel_trend.last

    # Tenant 1 видит только свои данные (1 чат, 1 букинг)
    assert_equal 1, current_week1.chats_count
    assert_equal 1, current_week1.bookings_count

    # Tenant 2 видит только свои данные (1 чат, 5 букингов)
    assert_equal 1, current_week2.chats_count
    assert_equal 5, current_week2.bookings_count
  end

  test 'funnel_trend groups records from same week correctly' do
    # Создаём изолированный тенант
    user = User.create!(name: 'Week Group Owner', email: 'week_group@test.com', password: 'password123')
    tenant = Tenant.create!(name: 'Week Group Tenant', bot_token: '333333333:WEEKGROUP', bot_username: 'week_group_bot', owner: user)
    tg_user = TelegramUser.create!(username: 'week_group_user', first_name: 'WeekGroup')
    client = tenant.clients.create!(telegram_user: tg_user, name: 'Week Group Client')

    # Создаем чаты в начале и конце текущей недели (UTC для корректной группировки)
    # Используем середину дней чтобы избежать проблем с timezone при DATE_TRUNC
    week_start = Time.current.beginning_of_week + 1.day + 12.hours  # Вторник полдень
    week_end = Time.current.end_of_week - 1.day + 12.hours  # Суббота полдень

    chat1 = tenant.chats.create!(client: client, created_at: week_start)
    chat2 = tenant.chats.create!(client: client, created_at: week_end)
    tenant.bookings.create!(chat: chat1, client: client, created_at: week_start)

    result = DashboardStatsService.new(tenant).call
    current_week = result.funnel_trend.last

    # Оба чата должны быть в одной неделе
    assert_equal 2, current_week.chats_count
    assert_equal 1, current_week.bookings_count
    assert_equal 50.0, current_week.conversion_rate
  end

  # === hourly_distribution ===

  test 'hourly_distribution returns array of 24 hours' do
    result = DashboardStatsService.new(@tenant).call

    assert_kind_of Array, result.hourly_distribution
    assert_equal 24, result.hourly_distribution.size
  end

  test 'hourly_distribution contains hash with hour and count keys' do
    result = DashboardStatsService.new(@tenant).call

    result.hourly_distribution.each do |hour_data|
      assert_kind_of Hash, hour_data
      assert_includes hour_data.keys, :hour
      assert_includes hour_data.keys, :count
    end
  end

  test 'hourly_distribution hours are ordered 0 to 23' do
    result = DashboardStatsService.new(@tenant).call

    hours = result.hourly_distribution.map { |h| h[:hour] }
    assert_equal (0..23).to_a, hours
  end

  test 'hourly_distribution counts are non-negative integers' do
    result = DashboardStatsService.new(@tenant).call

    result.hourly_distribution.each do |hour_data|
      assert_kind_of Integer, hour_data[:count]
      assert_operator hour_data[:count], :>=, 0
    end
  end

  test 'hourly_distribution counts only user messages' do
    # Создаём изолированный тенант
    user = User.create!(name: 'Hourly User', email: 'hourly_user@test.com', password: 'password123')
    tenant = Tenant.create!(name: 'Hourly Tenant', bot_token: '444444444:HOURLYTEST', bot_username: 'hourly_test_bot', owner: user)
    tg_user = TelegramUser.create!(username: 'hourly_user', first_name: 'Hourly')
    client = tenant.clients.create!(telegram_user: tg_user, name: 'Hourly Client')
    chat = tenant.chats.create!(client: client)

    # Создаём 3 user сообщения и 2 assistant сообщения
    3.times { chat.messages.create!(role: 'user', content: 'User message') }
    2.times { chat.messages.create!(role: 'assistant', content: 'Assistant message') }

    result = DashboardStatsService.new(tenant).call
    total_count = result.hourly_distribution.sum { |h| h[:count] }

    # Должно быть 3 (только user сообщения)
    assert_equal 3, total_count
  end

  test 'hourly_distribution respects period filter' do
    # Создаём изолированный тенант
    user = User.create!(name: 'Hourly Period', email: 'hourly_period@test.com', password: 'password123')
    tenant = Tenant.create!(name: 'Hourly Period Tenant', bot_token: '555555555:HOURLYPERIOD', bot_username: 'hourly_period_bot', owner: user)
    tg_user = TelegramUser.create!(username: 'hourly_period_user', first_name: 'HourlyPeriod')
    client = tenant.clients.create!(telegram_user: tg_user, name: 'Hourly Period Client')
    chat = tenant.chats.create!(client: client)

    # Создаём сообщение сегодня
    chat.messages.create!(role: 'user', content: 'Today message')

    # Создаём сообщение 10 дней назад (вне 7-дневного периода)
    chat.messages.create!(role: 'user', content: 'Old message', created_at: 10.days.ago)

    result = DashboardStatsService.new(tenant, period: 7).call
    total_count = result.hourly_distribution.sum { |h| h[:count] }

    # Должно быть 1 (только сегодняшнее сообщение)
    assert_equal 1, total_count
  end

  test 'hourly_distribution groups messages by hour in local timezone' do
    # Создаём изолированный тенант
    user = User.create!(name: 'Hourly Group', email: 'hourly_group@test.com', password: 'password123')
    tenant = Tenant.create!(name: 'Hourly Group Tenant', bot_token: '666666666:HOURLYGROUP', bot_username: 'hourly_group_bot', owner: user)
    tg_user = TelegramUser.create!(username: 'hourly_group_user', first_name: 'HourlyGroup')
    client = tenant.clients.create!(telegram_user: tg_user, name: 'Hourly Group Client')
    chat = tenant.chats.create!(client: client)

    # Создаём сообщения в локальном времени (Time.zone)
    # Сервис группирует по локальному часу, а не UTC
    today_10am_local = Time.zone.now.beginning_of_day + 10.hours + 30.minutes
    today_2pm_local = Time.zone.now.beginning_of_day + 14.hours + 15.minutes

    2.times { chat.messages.create!(role: 'user', content: 'Morning message', created_at: today_10am_local) }
    3.times { chat.messages.create!(role: 'user', content: 'Afternoon message', created_at: today_2pm_local) }

    result = DashboardStatsService.new(tenant).call

    hour_10_count = result.hourly_distribution.find { |h| h[:hour] == 10 }[:count]
    hour_14_count = result.hourly_distribution.find { |h| h[:hour] == 14 }[:count]

    assert_equal 2, hour_10_count
    assert_equal 3, hour_14_count
  end

  test 'hourly_distribution isolates data by tenant' do
    # Tenant 1 с 2 сообщениями
    user1 = User.create!(name: 'Hourly Iso 1', email: 'hourly_iso1@test.com', password: 'password123')
    tenant1 = Tenant.create!(name: 'Hourly Iso Tenant 1', bot_token: '777777777:HOURLYiso1', bot_username: 'hourly_iso_bot1', owner: user1)
    tg_user1 = TelegramUser.create!(username: 'hourly_iso_user1', first_name: 'HourlyIso1')
    client1 = tenant1.clients.create!(telegram_user: tg_user1, name: 'Hourly Iso Client 1')
    chat1 = tenant1.chats.create!(client: client1)
    2.times { chat1.messages.create!(role: 'user', content: 'Tenant1 message') }

    # Tenant 2 с 5 сообщениями
    user2 = User.create!(name: 'Hourly Iso 2', email: 'hourly_iso2@test.com', password: 'password123')
    tenant2 = Tenant.create!(name: 'Hourly Iso Tenant 2', bot_token: '888888888:HOURLYiso2', bot_username: 'hourly_iso_bot2', owner: user2)
    tg_user2 = TelegramUser.create!(username: 'hourly_iso_user2', first_name: 'HourlyIso2')
    client2 = tenant2.clients.create!(telegram_user: tg_user2, name: 'Hourly Iso Client 2')
    chat2 = tenant2.chats.create!(client: client2)
    5.times { chat2.messages.create!(role: 'user', content: 'Tenant2 message') }

    result1 = DashboardStatsService.new(tenant1).call
    result2 = DashboardStatsService.new(tenant2).call

    total1 = result1.hourly_distribution.sum { |h| h[:count] }
    total2 = result2.hourly_distribution.sum { |h| h[:count] }

    # Каждый тенант видит только свои данные
    assert_equal 2, total1
    assert_equal 5, total2
  end

  test 'hourly_distribution returns zeros when no messages' do
    # Создаём тенант без сообщений
    user = User.create!(name: 'Empty Hourly', email: 'empty_hourly@test.com', password: 'password123')
    empty_tenant = Tenant.create!(name: 'Empty Hourly Tenant', bot_token: '999999999:EMPTYHOURLY', bot_username: 'empty_hourly_bot', owner: user)

    result = DashboardStatsService.new(empty_tenant).call

    # Все часы должны иметь count = 0
    result.hourly_distribution.each do |hour_data|
      assert_equal 0, hour_data[:count]
    end
  end

  test 'result struct includes hourly_distribution' do
    result = DashboardStatsService.new(@tenant).call

    assert_respond_to result, :hourly_distribution
  end

  # === popular_topics ===

  test 'returns popular_topics in result' do
    result = DashboardStatsService.new(@tenant).call

    assert_respond_to result, :popular_topics
    assert_kind_of Array, result.popular_topics
  end

  test 'popular_topics returns TopicData structs' do
    # Создаём тенант с чатами и топиками
    user = User.create!(name: 'Topic Owner', email: 'topic_owner@test.com', password: 'password123')
    tenant = Tenant.create!(name: 'Topic Tenant', bot_token: '444444444:TOPICtest', bot_username: 'topic_test_bot', owner: user)

    topic = ChatTopic.create!(key: 'test_topic', label: 'Test Topic')

    tg_user = TelegramUser.create!(username: 'topic_test_user', first_name: 'TopicTest')
    client = tenant.clients.create!(telegram_user: tg_user, name: 'Topic Test Client')
    tenant.chats.create!(client: client, chat_topic: topic)

    result = DashboardStatsService.new(tenant).call

    assert result.popular_topics.any?
    result.popular_topics.each do |topic_data|
      assert_kind_of DashboardStatsService::TopicData, topic_data
      assert_respond_to topic_data, :topic
      assert_respond_to topic_data, :count
      assert_respond_to topic_data, :percentage
    end
  end

  test 'popular_topics returns empty array when no classified chats' do
    # Создаём тенант без классифицированных чатов
    user = User.create!(name: 'No Topic Owner', email: 'no_topic@test.com', password: 'password123')
    tenant = Tenant.create!(name: 'No Topic Tenant', bot_token: '555555555:NOTOPICtest', bot_username: 'no_topic_bot', owner: user)

    tg_user = TelegramUser.create!(username: 'no_topic_user', first_name: 'NoTopic')
    client = tenant.clients.create!(telegram_user: tg_user, name: 'No Topic Client')
    tenant.chats.create!(client: client) # chat_topic_id = nil

    result = DashboardStatsService.new(tenant).call

    assert_empty result.popular_topics
  end

  test 'popular_topics counts chats by topic correctly' do
    user = User.create!(name: 'Count Owner', email: 'count_topics@test.com', password: 'password123')
    tenant = Tenant.create!(name: 'Count Tenant', bot_token: '666666666:COUNTtopics', bot_username: 'count_topics_bot', owner: user)

    topic1 = ChatTopic.create!(key: 'count_topic1', label: 'Count Topic 1')
    topic2 = ChatTopic.create!(key: 'count_topic2', label: 'Count Topic 2')

    # Создаём 3 чата с topic1 и 2 чата с topic2
    3.times do |i|
      tg_user = TelegramUser.create!(username: "count_user_t1_#{i}", first_name: "CountT1_#{i}")
      client = tenant.clients.create!(telegram_user: tg_user, name: "Count Client T1 #{i}")
      tenant.chats.create!(client: client, chat_topic: topic1)
    end

    2.times do |i|
      tg_user = TelegramUser.create!(username: "count_user_t2_#{i}", first_name: "CountT2_#{i}")
      client = tenant.clients.create!(telegram_user: tg_user, name: "Count Client T2 #{i}")
      tenant.chats.create!(client: client, chat_topic: topic2)
    end

    result = DashboardStatsService.new(tenant).call

    topic1_data = result.popular_topics.find { |td| td.topic.key == 'count_topic1' }
    topic2_data = result.popular_topics.find { |td| td.topic.key == 'count_topic2' }

    assert_equal 3, topic1_data.count
    assert_equal 2, topic2_data.count
  end

  test 'popular_topics calculates percentage correctly' do
    user = User.create!(name: 'Percent Owner', email: 'percent_topics@test.com', password: 'password123')
    tenant = Tenant.create!(name: 'Percent Tenant', bot_token: '777777777:PERCENTtopics', bot_username: 'percent_topics_bot', owner: user)

    topic1 = ChatTopic.create!(key: 'percent_topic1', label: 'Percent Topic 1')
    topic2 = ChatTopic.create!(key: 'percent_topic2', label: 'Percent Topic 2')

    # 3 чата с topic1, 1 чат с topic2 = 75% и 25%
    3.times do |i|
      tg_user = TelegramUser.create!(username: "percent_user_t1_#{i}", first_name: "PercentT1_#{i}")
      client = tenant.clients.create!(telegram_user: tg_user, name: "Percent Client T1 #{i}")
      tenant.chats.create!(client: client, chat_topic: topic1)
    end

    tg_user2 = TelegramUser.create!(username: 'percent_user_t2', first_name: 'PercentT2')
    client2 = tenant.clients.create!(telegram_user: tg_user2, name: 'Percent Client T2')
    tenant.chats.create!(client: client2, chat_topic: topic2)

    result = DashboardStatsService.new(tenant).call

    topic1_data = result.popular_topics.find { |td| td.topic.key == 'percent_topic1' }
    topic2_data = result.popular_topics.find { |td| td.topic.key == 'percent_topic2' }

    assert_equal 75.0, topic1_data.percentage
    assert_equal 25.0, topic2_data.percentage
  end

  test 'popular_topics sorts by count descending' do
    user = User.create!(name: 'Sort Owner', email: 'sort_topics@test.com', password: 'password123')
    tenant = Tenant.create!(name: 'Sort Tenant', bot_token: '888888888:SORTtopics', bot_username: 'sort_topics_bot', owner: user)

    topic1 = ChatTopic.create!(key: 'sort_topic1', label: 'Sort Topic 1')
    topic2 = ChatTopic.create!(key: 'sort_topic2', label: 'Sort Topic 2')
    topic3 = ChatTopic.create!(key: 'sort_topic3', label: 'Sort Topic 3')

    # Создаём: topic2 - 5 чатов, topic1 - 3 чата, topic3 - 1 чат
    5.times do |i|
      tg_user = TelegramUser.create!(username: "sort_user_t2_#{i}", first_name: "SortT2_#{i}")
      client = tenant.clients.create!(telegram_user: tg_user, name: "Sort Client T2 #{i}")
      tenant.chats.create!(client: client, chat_topic: topic2)
    end

    3.times do |i|
      tg_user = TelegramUser.create!(username: "sort_user_t1_#{i}", first_name: "SortT1_#{i}")
      client = tenant.clients.create!(telegram_user: tg_user, name: "Sort Client T1 #{i}")
      tenant.chats.create!(client: client, chat_topic: topic1)
    end

    tg_user3 = TelegramUser.create!(username: 'sort_user_t3', first_name: 'SortT3')
    client3 = tenant.clients.create!(telegram_user: tg_user3, name: 'Sort Client T3')
    tenant.chats.create!(client: client3, chat_topic: topic3)

    result = DashboardStatsService.new(tenant).call

    assert_equal 'sort_topic2', result.popular_topics[0].topic.key
    assert_equal 'sort_topic1', result.popular_topics[1].topic.key
    assert_equal 'sort_topic3', result.popular_topics[2].topic.key
  end

  test 'popular_topics limits to 10 results' do
    user = User.create!(name: 'Limit Owner', email: 'limit_topics@test.com', password: 'password123')
    tenant = Tenant.create!(name: 'Limit Tenant', bot_token: '999999999:LIMITtopics', bot_username: 'limit_topics_bot', owner: user)

    # Создаём 15 топиков с чатами
    15.times do |i|
      topic = ChatTopic.create!(key: "limit_topic_#{i}", label: "Limit Topic #{i}")
      tg_user = TelegramUser.create!(username: "limit_user_#{i}", first_name: "Limit#{i}")
      client = tenant.clients.create!(telegram_user: tg_user, name: "Limit Client #{i}")
      tenant.chats.create!(client: client, chat_topic: topic)
    end

    result = DashboardStatsService.new(tenant).call

    assert_equal 10, result.popular_topics.size
  end

  test 'popular_topics isolates data by tenant' do
    user1 = User.create!(name: 'Iso Topics 1', email: 'iso_topics1@test.com', password: 'password123')
    tenant1 = Tenant.create!(name: 'Iso Topics Tenant 1', bot_token: '111111111:ISOtopics1', bot_username: 'iso_topics_bot1', owner: user1)

    user2 = User.create!(name: 'Iso Topics 2', email: 'iso_topics2@test.com', password: 'password123')
    tenant2 = Tenant.create!(name: 'Iso Topics Tenant 2', bot_token: '222222222:ISOtopics2', bot_username: 'iso_topics_bot2', owner: user2)

    topic = ChatTopic.create!(key: 'iso_topic', label: 'Isolation Topic')

    # Tenant1: 3 чата с топиком
    3.times do |i|
      tg_user = TelegramUser.create!(username: "iso_t1_user_#{i}", first_name: "IsoT1_#{i}")
      client = tenant1.clients.create!(telegram_user: tg_user, name: "Iso T1 Client #{i}")
      tenant1.chats.create!(client: client, chat_topic: topic)
    end

    # Tenant2: 1 чат с топиком
    tg_user2 = TelegramUser.create!(username: 'iso_t2_user', first_name: 'IsoT2')
    client2 = tenant2.clients.create!(telegram_user: tg_user2, name: 'Iso T2 Client')
    tenant2.chats.create!(client: client2, chat_topic: topic)

    result1 = DashboardStatsService.new(tenant1).call
    result2 = DashboardStatsService.new(tenant2).call

    topic_data1 = result1.popular_topics.find { |td| td.topic.key == 'iso_topic' }
    topic_data2 = result2.popular_topics.find { |td| td.topic.key == 'iso_topic' }

    assert_equal 3, topic_data1.count
    assert_equal 1, topic_data2.count
  end
end
