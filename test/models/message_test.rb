# frozen_string_literal: true

require 'test_helper'

class MessageTest < ActiveSupport::TestCase
  test 'fixture is valid and persisted' do
    message = messages(:one)
    assert message.valid?
    assert message.persisted?
  end
end
