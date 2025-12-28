# frozen_string_literal: true

# Сервис для расчета расходов на LLM по тенанту
#
# Вычисляет стоимость использования LLM на основе
# input/output токенов и цен моделей.
#
# @example Расчет общих расходов
#   calculator = LlmCostCalculator.new(tenant, period: 30)
#   totals = calculator.calculate_totals
#   totals.input_tokens  #=> 150000
#   totals.total_cost    #=> 0.45
#
# @example Расчет по моделям
#   by_model = calculator.calculate_by_model
#   by_model.each { |m| puts "#{m.model_name}: $#{m.total_cost}" }
#
# @example Расчет по дням для графика
#   by_day = calculator.calculate_by_day
#   by_day.each { |d| puts "#{d.date}: $#{d.total_cost}" }
#
# @see DashboardStatsService
class LlmCostCalculator
  include ErrorLogger
  # Результат общего расчета токенов и стоимости
  Totals = Struct.new(
    :input_tokens,
    :output_tokens,
    :total_tokens,
    :input_cost,
    :output_cost,
    :total_cost,
    keyword_init: true
  )

  # Статистика по конкретной модели
  ModelStats = Struct.new(
    :model_id,
    :model_name,
    :provider,
    :input_tokens,
    :output_tokens,
    :total_tokens,
    :input_price_per_million,
    :output_price_per_million,
    :input_cost,
    :output_cost,
    :total_cost,
    keyword_init: true
  )

  # Статистика по дню
  DayStats = Struct.new(
    :date,
    :input_tokens,
    :output_tokens,
    :total_tokens,
    :input_cost,
    :output_cost,
    :total_cost,
    keyword_init: true
  )

  MILLION = 1_000_000.0

  # @param tenant [Tenant] тенант для которого рассчитывается стоимость
  # @param period [Integer] период в днях (по умолчанию 30)
  # @param start_date [Date, nil] начальная дата (если nil, вычисляется от period)
  # @param end_date [Date, nil] конечная дата (если nil, используется сегодня)
  def initialize(tenant, period: 30, start_date: nil, end_date: nil)
    raise ArgumentError, 'tenant is required' if tenant.nil?

    @tenant = tenant
    @period = period
    @start_date = start_date || period.days.ago.to_date
    @end_date = end_date || Date.current
  end

  # Рассчитывает общие расходы на LLM за период
  #
  # @return [Totals] общая статистика токенов и стоимости
  def calculate_totals
    # Рассчитываем стоимость через детализацию по моделям
    by_model = calculate_by_model

    input_tokens = by_model.sum(&:input_tokens)
    output_tokens = by_model.sum(&:output_tokens)
    input_cost = by_model.sum(&:input_cost)
    output_cost = by_model.sum(&:output_cost)

    Totals.new(
      input_tokens: input_tokens,
      output_tokens: output_tokens,
      total_tokens: input_tokens + output_tokens,
      input_cost: input_cost.round(6),
      output_cost: output_cost.round(6),
      total_cost: (input_cost + output_cost).round(6)
    )
  end

  # Рассчитывает расходы с разбивкой по моделям
  #
  # @return [Array<ModelStats>] статистика по каждой модели
  def calculate_by_model
    data = messages_with_pricing
      .joins(:model)
      .group('models.id', 'models.model_id', 'models.name', 'models.provider', 'models.pricing')
      .pluck(
        'models.id',
        'models.model_id',
        'models.name',
        'models.provider',
        'models.pricing',
        Arel.sql('SUM(messages.input_tokens)'),
        Arel.sql('SUM(messages.output_tokens)')
      )

    data.map do |row|
      _model_db_id, model_id, model_name, provider, pricing_json, row_input_tokens, row_output_tokens = row

      input_tokens = row_input_tokens.to_i
      output_tokens = row_output_tokens.to_i

      prices = extract_prices(pricing_json)
      input_price = prices[:input]
      output_price = prices[:output]

      input_cost = calculate_cost(input_tokens, input_price)
      output_cost = calculate_cost(output_tokens, output_price)

      ModelStats.new(
        model_id: model_id,
        model_name: model_name,
        provider: provider,
        input_tokens: input_tokens,
        output_tokens: output_tokens,
        total_tokens: input_tokens + output_tokens,
        input_price_per_million: input_price,
        output_price_per_million: output_price,
        input_cost: input_cost.round(6),
        output_cost: output_cost.round(6),
        total_cost: (input_cost + output_cost).round(6)
      )
    end.sort_by { |stats| -stats.total_cost }
  end

  # Рассчитывает расходы с разбивкой по дням
  #
  # @return [Array<DayStats>] статистика по каждому дню
  def calculate_by_day
    # Сначала собираем данные по дням и моделям для правильного расчета стоимости
    data = messages_with_pricing
      .joins(:model)
      .group(Arel.sql('DATE(messages.created_at)'), 'models.pricing')
      .pluck(
        Arel.sql('DATE(messages.created_at)'),
        'models.pricing',
        Arel.sql('SUM(messages.input_tokens)'),
        Arel.sql('SUM(messages.output_tokens)')
      )

    # Группируем по дате и суммируем
    daily_data = Hash.new { |h, k| h[k] = { input_tokens: 0, output_tokens: 0, input_cost: 0.0, output_cost: 0.0 } }

    data.each do |row|
      date, pricing_json, row_input_tokens, row_output_tokens = row
      tokens_in = row_input_tokens.to_i
      tokens_out = row_output_tokens.to_i

      prices = extract_prices(pricing_json)
      input_cost = calculate_cost(tokens_in, prices[:input])
      output_cost = calculate_cost(tokens_out, prices[:output])

      daily_data[date][:input_tokens] += tokens_in
      daily_data[date][:output_tokens] += tokens_out
      daily_data[date][:input_cost] += input_cost
      daily_data[date][:output_cost] += output_cost
    end

    # Заполняем все дни в периоде (включая дни без данных)
    (@start_date..@end_date).map do |date|
      day = daily_data[date]
      input_tokens = day[:input_tokens]
      output_tokens = day[:output_tokens]
      input_cost = day[:input_cost]
      output_cost = day[:output_cost]

      DayStats.new(
        date: date,
        input_tokens: input_tokens,
        output_tokens: output_tokens,
        total_tokens: input_tokens + output_tokens,
        input_cost: input_cost.round(6),
        output_cost: output_cost.round(6),
        total_cost: (input_cost + output_cost).round(6)
      )
    end
  end

  private

  attr_reader :tenant, :period, :start_date, :end_date

  def messages_with_pricing
    Message
      .joins(chat: :tenant)
      .where(chats: { tenant_id: tenant.id })
      .where(created_at: start_date.beginning_of_day..end_date.end_of_day)
      .where.not(model_id: nil)
      .where.not(input_tokens: nil)
  end

  def extract_prices(pricing_json)
    return { input: 0.0, output: 0.0 } if pricing_json.blank?

    pricing = parse_pricing_json(pricing_json)
    return { input: 0.0, output: 0.0 } unless pricing.is_a?(Hash)

    pricing = pricing.deep_symbolize_keys

    # Структура pricing: { text_tokens: { standard: { input_per_million: X, output_per_million: Y } } }
    text_tokens = pricing.dig(:text_tokens, :standard) || {}

    {
      input: text_tokens[:input_per_million].to_f,
      output: text_tokens[:output_per_million].to_f
    }
  end

  def parse_pricing_json(pricing_json)
    return pricing_json unless pricing_json.is_a?(String)

    JSON.parse(pricing_json)
  rescue JSON::ParserError => e
    log_error(e, {
      service: self.class.name,
      action: 'parse_pricing_json',
      pricing_preview: pricing_json.to_s[0..100]
    })
    nil
  end

  def calculate_cost(tokens, price_per_million)
    return 0.0 if tokens.nil? || tokens.zero? || price_per_million.nil? || price_per_million.zero?

    (tokens.to_f * price_per_million) / MILLION
  end
end
