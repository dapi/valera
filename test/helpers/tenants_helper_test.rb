# frozen_string_literal: true

require 'test_helper'

class TenantsHelperTest < ActionView::TestCase
  include TenantsHelper

  test 'masked_bot_token returns nil for blank token' do
    assert_nil masked_bot_token(nil)
    assert_nil masked_bot_token('')
  end

  test 'masked_bot_token returns original for invalid format' do
    assert_equal 'invalid', masked_bot_token('invalid')
    assert_equal '123:ab', masked_bot_token('123:ab')
  end

  test 'masked_bot_token masks token correctly' do
    token = '123456789:ABCdefGHIjklMNOpqrs'
    result = masked_bot_token(token)

    assert_equal '123456789:AB...rs', result
  end

  test 'masked_bot_token works with short secrets' do
    token = '123:abcd'
    result = masked_bot_token(token)

    assert_equal '123:ab...cd', result
  end
end
