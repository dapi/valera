# frozen_string_literal: true

require 'test_helper'

class LlmCostCalculatorTest < ActiveSupport::TestCase
  setup do
    @tenant = tenants(:one)
    @chat = chats(:one)
    @model = models(:one)
  end

  test 'raises error when tenant is nil' do
    assert_raises(ArgumentError) do
      LlmCostCalculator.new(nil)
    end
  end

  # === calculate_totals ===

  test 'calculate_totals returns Totals struct' do
    result = LlmCostCalculator.new(@tenant).calculate_totals

    assert_kind_of LlmCostCalculator::Totals, result
    assert_respond_to result, :input_tokens
    assert_respond_to result, :output_tokens
    assert_respond_to result, :total_tokens
    assert_respond_to result, :input_cost
    assert_respond_to result, :output_cost
    assert_respond_to result, :total_cost
  end

  test 'calculate_totals sums tokens from messages' do
    # Очищаем существующие сообщения
    @chat.messages.destroy_all

    # Создаём сообщения с токенами
    @chat.messages.create!(role: 'user', content: 'Test 1', model: @model, input_tokens: 100, output_tokens: 0)
    @chat.messages.create!(role: 'assistant', content: 'Response 1', model: @model, input_tokens: 0, output_tokens: 50)
    @chat.messages.create!(role: 'user', content: 'Test 2', model: @model, input_tokens: 200, output_tokens: 0)
    @chat.messages.create!(role: 'assistant', content: 'Response 2', model: @model, input_tokens: 0, output_tokens: 100)

    result = LlmCostCalculator.new(@tenant).calculate_totals

    assert_equal 300, result.input_tokens
    assert_equal 150, result.output_tokens
    assert_equal 450, result.total_tokens
  end

  test 'calculate_totals calculates costs using model pricing' do
    @chat.messages.destroy_all

    # Model one: $30/M input, $60/M output
    @chat.messages.create!(role: 'user', content: 'Test', model: @model, input_tokens: 1_000_000, output_tokens: 0)
    @chat.messages.create!(role: 'assistant', content: 'Response', model: @model, input_tokens: 0, output_tokens: 1_000_000)

    result = LlmCostCalculator.new(@tenant).calculate_totals

    assert_in_delta 30.0, result.input_cost, 0.000001
    assert_in_delta 60.0, result.output_cost, 0.000001
    assert_in_delta 90.0, result.total_cost, 0.000001
  end

  test 'calculate_totals returns zeros for tenant without messages' do
    @chat.messages.destroy_all

    result = LlmCostCalculator.new(@tenant).calculate_totals

    assert_equal 0, result.input_tokens
    assert_equal 0, result.output_tokens
    assert_equal 0, result.total_tokens
    assert_equal 0.0, result.input_cost
    assert_equal 0.0, result.output_cost
    assert_equal 0.0, result.total_cost
  end

  test 'calculate_totals respects period parameter' do
    @chat.messages.destroy_all

    # Сообщение в периоде
    @chat.messages.create!(role: 'user', content: 'Recent', model: @model, input_tokens: 100, output_tokens: 0)

    # Сообщение вне периода (31 день назад)
    old_message = @chat.messages.create!(role: 'user', content: 'Old', model: @model, input_tokens: 500, output_tokens: 0)
    old_message.update_column(:created_at, 31.days.ago)

    result = LlmCostCalculator.new(@tenant, period: 30).calculate_totals

    assert_equal 100, result.input_tokens
  end

  test 'calculate_totals respects start_date and end_date' do
    @chat.messages.destroy_all

    # Создаём сообщения в разные даты
    msg1 = @chat.messages.create!(role: 'user', content: 'Msg 1', model: @model, input_tokens: 100, output_tokens: 0)
    msg1.update_column(:created_at, 10.days.ago)

    msg2 = @chat.messages.create!(role: 'user', content: 'Msg 2', model: @model, input_tokens: 200, output_tokens: 0)
    msg2.update_column(:created_at, 5.days.ago)

    msg3 = @chat.messages.create!(role: 'user', content: 'Msg 3', model: @model, input_tokens: 300, output_tokens: 0)
    msg3.update_column(:created_at, 1.day.ago)

    result = LlmCostCalculator.new(@tenant, start_date: 7.days.ago.to_date, end_date: 2.days.ago.to_date).calculate_totals

    assert_equal 200, result.input_tokens
  end

  # === calculate_by_model ===

  test 'calculate_by_model returns array of ModelStats' do
    result = LlmCostCalculator.new(@tenant).calculate_by_model

    assert_kind_of Array, result
    result.each do |stats|
      assert_kind_of LlmCostCalculator::ModelStats, stats
    end
  end

  test 'calculate_by_model groups by model' do
    @chat.messages.destroy_all

    model_one = models(:one)
    model_two = models(:two)

    @chat.messages.create!(role: 'user', content: 'Test 1', model: model_one, input_tokens: 100, output_tokens: 50)
    @chat.messages.create!(role: 'user', content: 'Test 2', model: model_two, input_tokens: 200, output_tokens: 100)

    result = LlmCostCalculator.new(@tenant).calculate_by_model

    assert_equal 2, result.size

    model_one_stats = result.find { |s| s.model_id == 'gpt-4' }
    model_two_stats = result.find { |s| s.model_id == 'claude-3-sonnet' }

    assert_not_nil model_one_stats
    assert_not_nil model_two_stats

    assert_equal 100, model_one_stats.input_tokens
    assert_equal 50, model_one_stats.output_tokens
    assert_equal 'GPT-4', model_one_stats.model_name
    assert_equal 'openai', model_one_stats.provider

    assert_equal 200, model_two_stats.input_tokens
    assert_equal 100, model_two_stats.output_tokens
  end

  test 'calculate_by_model includes pricing info' do
    @chat.messages.destroy_all
    @chat.messages.create!(role: 'user', content: 'Test', model: @model, input_tokens: 100, output_tokens: 50)

    result = LlmCostCalculator.new(@tenant).calculate_by_model

    assert_equal 1, result.size
    stats = result.first

    assert_equal 30.0, stats.input_price_per_million
    assert_equal 60.0, stats.output_price_per_million
  end

  test 'calculate_by_model calculates costs correctly' do
    @chat.messages.destroy_all

    # Model one: $30/M input, $60/M output
    @chat.messages.create!(role: 'user', content: 'Test', model: @model, input_tokens: 1000, output_tokens: 500)

    result = LlmCostCalculator.new(@tenant).calculate_by_model
    stats = result.first

    # 1000 tokens * $30/M = $0.03
    # 500 tokens * $60/M = $0.03
    assert_in_delta 0.03, stats.input_cost, 0.000001
    assert_in_delta 0.03, stats.output_cost, 0.000001
    assert_in_delta 0.06, stats.total_cost, 0.000001
  end

  test 'calculate_by_model sorts by total_cost descending' do
    @chat.messages.destroy_all

    model_cheap = models(:deepseek)  # $1/M input, $2/M output
    model_expensive = models(:one)   # $30/M input, $60/M output

    @chat.messages.create!(role: 'user', content: 'Cheap', model: model_cheap, input_tokens: 1000, output_tokens: 500)
    @chat.messages.create!(role: 'user', content: 'Expensive', model: model_expensive, input_tokens: 1000, output_tokens: 500)

    result = LlmCostCalculator.new(@tenant).calculate_by_model

    assert_equal 2, result.size
    assert_operator result[0].total_cost, :>, result[1].total_cost
    assert_equal 'gpt-4', result[0].model_id
  end

  # === calculate_by_day ===

  test 'calculate_by_day returns array of DayStats' do
    result = LlmCostCalculator.new(@tenant, period: 7).calculate_by_day

    assert_kind_of Array, result
    result.each do |stats|
      assert_kind_of LlmCostCalculator::DayStats, stats
    end
  end

  test 'calculate_by_day returns stats for each day in period' do
    result = LlmCostCalculator.new(@tenant, period: 7).calculate_by_day

    assert_equal 8, result.size # 7 days ago + today = 8 days
    assert_equal 7.days.ago.to_date, result.first.date
    assert_equal Date.current, result.last.date
  end

  test 'calculate_by_day fills missing days with zeros' do
    @chat.messages.destroy_all

    result = LlmCostCalculator.new(@tenant, period: 7).calculate_by_day

    result.each do |stats|
      assert_equal 0, stats.input_tokens
      assert_equal 0, stats.output_tokens
      assert_equal 0, stats.total_tokens
      assert_equal 0.0, stats.input_cost
      assert_equal 0.0, stats.output_cost
      assert_equal 0.0, stats.total_cost
    end
  end

  test 'calculate_by_day groups tokens and costs by day' do
    @chat.messages.destroy_all

    # Создаём сообщения в разные дни
    yesterday_msg = @chat.messages.create!(role: 'user', content: 'Yesterday', model: @model, input_tokens: 100, output_tokens: 50)
    yesterday_msg.update_column(:created_at, 1.day.ago)

    today_msg = @chat.messages.create!(role: 'user', content: 'Today', model: @model, input_tokens: 200, output_tokens: 100)

    result = LlmCostCalculator.new(@tenant, period: 7).calculate_by_day

    yesterday_stats = result.find { |s| s.date == 1.day.ago.to_date }
    today_stats = result.find { |s| s.date == Date.current }

    assert_equal 100, yesterday_stats.input_tokens
    assert_equal 50, yesterday_stats.output_tokens

    assert_equal 200, today_stats.input_tokens
    assert_equal 100, today_stats.output_tokens
  end

  test 'calculate_by_day calculates costs correctly for each day' do
    @chat.messages.destroy_all

    # Model one: $30/M input, $60/M output
    msg = @chat.messages.create!(role: 'user', content: 'Test', model: @model, input_tokens: 1_000_000, output_tokens: 1_000_000)

    result = LlmCostCalculator.new(@tenant, period: 1).calculate_by_day
    today_stats = result.find { |s| s.date == Date.current }

    assert_in_delta 30.0, today_stats.input_cost, 0.000001
    assert_in_delta 60.0, today_stats.output_cost, 0.000001
    assert_in_delta 90.0, today_stats.total_cost, 0.000001
  end

  # === Isolation ===

  test 'isolates data by tenant' do
    tenant_one = tenants(:one)
    tenant_two = tenants(:two)

    chat_one = chats(:one)
    chat_two = chats(:two)

    chat_one.messages.destroy_all
    chat_two.messages.destroy_all

    model = models(:one)

    chat_one.messages.create!(role: 'user', content: 'Tenant 1', model: model, input_tokens: 100, output_tokens: 0)
    chat_two.messages.create!(role: 'user', content: 'Tenant 2', model: model, input_tokens: 500, output_tokens: 0)

    result_one = LlmCostCalculator.new(tenant_one).calculate_totals
    result_two = LlmCostCalculator.new(tenant_two).calculate_totals

    assert_equal 100, result_one.input_tokens
    assert_equal 500, result_two.input_tokens
  end

  # === Edge cases ===

  test 'handles messages without model_id' do
    @chat.messages.destroy_all
    @chat.messages.create!(role: 'user', content: 'No model', model: nil, input_tokens: 100, output_tokens: 0)

    result = LlmCostCalculator.new(@tenant).calculate_totals

    assert_equal 0, result.input_tokens # Should be excluded
  end

  test 'handles messages without input_tokens' do
    @chat.messages.destroy_all
    @chat.messages.create!(role: 'user', content: 'No tokens', model: @model, input_tokens: nil, output_tokens: nil)

    result = LlmCostCalculator.new(@tenant).calculate_totals

    assert_equal 0, result.input_tokens
  end

  test 'handles model with empty pricing' do
    @chat.messages.destroy_all

    # Создаём модель без pricing
    model_no_pricing = Model.create!(
      provider: 'test',
      model_id: 'test-no-pricing',
      name: 'Test No Pricing',
      pricing: {}
    )

    @chat.messages.create!(role: 'user', content: 'Test', model: model_no_pricing, input_tokens: 1000, output_tokens: 500)

    result = LlmCostCalculator.new(@tenant).calculate_by_model
    stats = result.first

    assert_equal 0.0, stats.input_cost
    assert_equal 0.0, stats.output_cost
    assert_equal 0.0, stats.total_cost
  end

  test 'handles model with nil pricing' do
    @chat.messages.destroy_all

    model_nil_pricing = Model.create!(
      provider: 'test',
      model_id: 'test-nil-pricing',
      name: 'Test Nil Pricing',
      pricing: nil
    )

    @chat.messages.create!(role: 'user', content: 'Test', model: model_nil_pricing, input_tokens: 1000, output_tokens: 500)

    result = LlmCostCalculator.new(@tenant).calculate_by_model
    stats = result.first

    assert_equal 0.0, stats.input_cost
    assert_equal 0.0, stats.output_cost
    assert_equal 0.0, stats.total_cost
  end

  test 'handles model with partial pricing structure' do
    @chat.messages.destroy_all

    model_partial = Model.create!(
      provider: 'test',
      model_id: 'test-partial-pricing',
      name: 'Test Partial Pricing',
      pricing: { text_tokens: {} }
    )

    @chat.messages.create!(role: 'user', content: 'Test', model: model_partial, input_tokens: 1000, output_tokens: 500)

    result = LlmCostCalculator.new(@tenant).calculate_by_model
    stats = result.first

    assert_equal 0.0, stats.input_cost
    assert_equal 0.0, stats.output_cost
  end

  test 'calculate_by_day aggregates costs from multiple models on same day' do
    @chat.messages.destroy_all

    model_expensive = models(:one)   # $30/M input
    model_cheap = models(:deepseek)  # $1/M input

    @chat.messages.create!(role: 'user', content: 'Expensive', model: model_expensive, input_tokens: 1_000_000, output_tokens: 0)
    @chat.messages.create!(role: 'user', content: 'Cheap', model: model_cheap, input_tokens: 1_000_000, output_tokens: 0)

    result = LlmCostCalculator.new(@tenant, period: 1).calculate_by_day
    today_stats = result.find { |s| s.date == Date.current }

    # $30 + $1 = $31 input cost
    assert_in_delta 31.0, today_stats.input_cost, 0.000001
  end
end
