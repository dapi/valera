# frozen_string_literal: true

require 'test_helper'

class ApplicationHelperTest < ActionView::TestCase
  include ApplicationHelper

  # === hourly_distribution_chart_data ===

  test 'hourly_distribution_chart_data returns JSON with labels and values' do
    data = [
      { hour: 0, count: 5 },
      { hour: 9, count: 10 },
      { hour: 23, count: 3 }
    ]

    result = JSON.parse(hourly_distribution_chart_data(data))

    assert_equal %w[00:00 09:00 23:00], result['labels']
    assert_equal [ 5, 10, 3 ], result['values']
  end

  test 'hourly_distribution_chart_data formats hours with leading zeros' do
    data = [
      { hour: 0, count: 1 },
      { hour: 5, count: 2 },
      { hour: 12, count: 3 }
    ]

    result = JSON.parse(hourly_distribution_chart_data(data))

    assert_equal '00:00', result['labels'][0]
    assert_equal '05:00', result['labels'][1]
    assert_equal '12:00', result['labels'][2]
  end

  test 'hourly_distribution_chart_data handles empty array' do
    result = JSON.parse(hourly_distribution_chart_data([]))

    assert_equal [], result['labels']
    assert_equal [], result['values']
  end

  test 'hourly_distribution_chart_data handles full 24 hours' do
    data = (0..23).map { |hour| { hour: hour, count: hour * 10 } }

    result = JSON.parse(hourly_distribution_chart_data(data))

    assert_equal 24, result['labels'].length
    assert_equal 24, result['values'].length
    assert_equal '00:00', result['labels'].first
    assert_equal '23:00', result['labels'].last
    assert_equal 0, result['values'].first
    assert_equal 230, result['values'].last
  end

  test 'hourly_distribution_chart_data returns valid JSON string' do
    data = [ { hour: 12, count: 100 } ]

    result = hourly_distribution_chart_data(data)

    assert_kind_of String, result
    assert_nothing_raised { JSON.parse(result) }
  end

  test 'hourly_distribution_chart_data preserves zero counts' do
    data = [
      { hour: 0, count: 0 },
      { hour: 12, count: 0 },
      { hour: 23, count: 0 }
    ]

    result = JSON.parse(hourly_distribution_chart_data(data))

    assert_equal [ 0, 0, 0 ], result['values']
  end
end
