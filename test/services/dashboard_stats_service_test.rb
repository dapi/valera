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

  test 'avg_messages_per_dialog returns Float' do
    result = DashboardStatsService.new(@tenant).call

    assert_kind_of Float, result.avg_messages_per_dialog
  end

  test 'avg_messages_per_dialog returns 0.0 when no chats with messages' do
    user = User.create!(name: 'Empty Owner', email: 'empty_avg@test.com', password: 'password123')
    empty_tenant = Tenant.create!(name: 'Empty Tenant', bot_token: '888888888:ABCdefGHIjklMNOpqrsTUVwxyz', bot_username: 'empty_avg_bot', owner: user)

    result = DashboardStatsService.new(empty_tenant).call

    assert_equal 0.0, result.avg_messages_per_dialog
  end

  test 'avg_messages_per_dialog calculates correctly with one chat' do
    user = User.create!(name: 'Single Owner', email: 'single_avg@test.com', password: 'password123')
    single_tenant = Tenant.create!(name: 'Single Tenant', bot_token: '777777777:ABCdefGHIjklMNOpqrsTUVwxyz', bot_username: 'single_avg_bot', owner: user)

    tg_user = TelegramUser.create!(username: 'single_user', first_name: 'Single')
    client = single_tenant.clients.create!(telegram_user: tg_user, name: 'Single Client')
    chat = single_tenant.chats.create!(client: client, telegram_user: tg_user)
    5.times { chat.messages.create!(role: 'user', content: 'Test') }

    result = DashboardStatsService.new(single_tenant).call

    assert_equal 5.0, result.avg_messages_per_dialog
  end

  test 'avg_messages_per_dialog calculates correctly with multiple chats' do
    user = User.create!(name: 'Multi Owner', email: 'multi_avg@test.com', password: 'password123')
    multi_tenant = Tenant.create!(name: 'Multi Tenant', bot_token: '666666666:ABCdefGHIjklMNOpqrsTUVwxyz', bot_username: 'multi_avg_bot', owner: user)

    tg_user1 = TelegramUser.create!(username: 'multi_user1', first_name: 'Multi1')
    client1 = multi_tenant.clients.create!(telegram_user: tg_user1, name: 'Multi Client 1')
    chat1 = multi_tenant.chats.create!(client: client1, telegram_user: tg_user1)
    3.times { chat1.messages.create!(role: 'user', content: 'Test') }

    tg_user2 = TelegramUser.create!(username: 'multi_user2', first_name: 'Multi2')
    client2 = multi_tenant.clients.create!(telegram_user: tg_user2, name: 'Multi Client 2')
    chat2 = multi_tenant.chats.create!(client: client2, telegram_user: tg_user2)
    7.times { chat2.messages.create!(role: 'user', content: 'Test') }

    result = DashboardStatsService.new(multi_tenant).call

    # (3 + 7) / 2 = 5.0
    assert_equal 5.0, result.avg_messages_per_dialog
  end

  test 'avg_messages_per_dialog excludes chats without messages' do
    user = User.create!(name: 'Mix Owner', email: 'mix_avg@test.com', password: 'password123')
    mix_tenant = Tenant.create!(name: 'Mix Tenant', bot_token: '555555555:ABCdefGHIjklMNOpqrsTUVwxyz', bot_username: 'mix_avg_bot', owner: user)

    # Чат с сообщениями
    tg_user1 = TelegramUser.create!(username: 'mix_user1', first_name: 'Mix1')
    client1 = mix_tenant.clients.create!(telegram_user: tg_user1, name: 'Mix Client 1')
    chat1 = mix_tenant.chats.create!(client: client1, telegram_user: tg_user1)
    10.times { chat1.messages.create!(role: 'user', content: 'Test') }

    # Чат без сообщений (не должен учитываться)
    tg_user2 = TelegramUser.create!(username: 'mix_user2', first_name: 'Mix2')
    client2 = mix_tenant.clients.create!(telegram_user: tg_user2, name: 'Mix Client 2')
    mix_tenant.chats.create!(client: client2, telegram_user: tg_user2)

    result = DashboardStatsService.new(mix_tenant).call

    # Только 1 чат с 10 сообщениями учитывается
    assert_equal 10.0, result.avg_messages_per_dialog
  end

  test 'avg_messages_per_dialog rounds to one decimal place' do
    user = User.create!(name: 'Round Owner', email: 'round_avg@test.com', password: 'password123')
    round_tenant = Tenant.create!(name: 'Round Tenant', bot_token: '444444444:ABCdefGHIjklMNOpqrsTUVwxyz', bot_username: 'round_avg_bot', owner: user)

    tg_user1 = TelegramUser.create!(username: 'round_user1', first_name: 'Round1')
    client1 = round_tenant.clients.create!(telegram_user: tg_user1, name: 'Round Client 1')
    chat1 = round_tenant.chats.create!(client: client1, telegram_user: tg_user1)
    3.times { chat1.messages.create!(role: 'user', content: 'Test') }

    tg_user2 = TelegramUser.create!(username: 'round_user2', first_name: 'Round2')
    client2 = round_tenant.clients.create!(telegram_user: tg_user2, name: 'Round Client 2')
    chat2 = round_tenant.chats.create!(client: client2, telegram_user: tg_user2)
    5.times { chat2.messages.create!(role: 'user', content: 'Test') }

    tg_user3 = TelegramUser.create!(username: 'round_user3', first_name: 'Round3')
    client3 = round_tenant.clients.create!(telegram_user: tg_user3, name: 'Round Client 3')
    chat3 = round_tenant.chats.create!(client: client3, telegram_user: tg_user3)
    2.times { chat3.messages.create!(role: 'user', content: 'Test') }

    result = DashboardStatsService.new(round_tenant).call

    # (3 + 5 + 2) / 3 = 3.333... -> 3.3
    assert_equal 3.3, result.avg_messages_per_dialog
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
end
