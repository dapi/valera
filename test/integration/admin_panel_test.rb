# frozen_string_literal: true

require 'test_helper'

class AdminPanelTest < ActionDispatch::IntegrationTest
  test 'time format translation exists for ru locale without raising' do
    # Use raise: true to ensure translations actually exist (not just fallback)
    assert_nothing_raised do
      I18n.t('time.formats.default', locale: :ru, raise: true)
    end
  end

  test 'date format translation exists for ru locale without raising' do
    assert_nothing_raised do
      I18n.t('date.formats.default', locale: :ru, raise: true)
    end
  end
end
