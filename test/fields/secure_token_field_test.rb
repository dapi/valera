# frozen_string_literal: true

require 'test_helper'
require 'administrate/field/base'
require_relative '../../app/fields/secure_token_field'

class SecureTokenFieldTest < ActiveSupport::TestCase
  def create_field(data)
    SecureTokenField.new(:bot_token, data, :show)
  end

  test 'masked_value returns nil for blank data' do
    field = create_field(nil)
    assert_nil field.masked_value

    field = create_field('')
    assert_nil field.masked_value
  end

  test 'masked_value returns masked format for valid token' do
    # Telegram bot token format: bot_id:secret
    field = create_field('123456789:ABCdefGHIjklMNOpqrSTUvwxYZ')
    assert_equal '123456789:AB...YZ', field.masked_value
  end

  test 'masked_value returns original for short secrets' do
    # Secret too short to mask meaningfully
    field = create_field('123:abc')
    assert_equal '123:abc', field.masked_value
  end

  test 'masked_value handles token without colon' do
    field = create_field('invalid_token')
    assert_equal 'invalid_token', field.masked_value
  end

  test 'new_token_attribute returns correct symbol' do
    field = create_field('123:secret')
    assert_equal :new_bot_token, field.new_token_attribute
  end

  test 'token_set? returns true when data present' do
    field = create_field('123:secret')
    assert field.token_set?
  end

  test 'token_set? returns false when data blank' do
    field = create_field(nil)
    refute field.token_set?

    field = create_field('')
    refute field.token_set?
  end

  test 'to_s returns masked value' do
    field = create_field('123456789:ABCdefGHI')
    assert_equal '123456789:AB...HI', field.to_s
  end
end
