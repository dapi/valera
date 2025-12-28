# frozen_string_literal: true

require 'test_helper'

class TopicClassifierConfigTest < ActiveSupport::TestCase
  setup do
    # Сбрасываем singleton для изоляции тестов
    TopicClassifierConfig.instance_variable_set(:@instance, nil)
  end

  teardown do
    TopicClassifierConfig.instance_variable_set(:@instance, nil)
  end

  test 'has default inactivity_hours' do
    config = TopicClassifierConfig.new

    assert_equal 24, config.inactivity_hours
  end

  test 'model_with_fallback returns model when set' do
    config = TopicClassifierConfig.new
    # anyway_config использует другой способ хранения значений
    config.stubs(:model).returns('custom-model')

    assert_equal 'custom-model', config.model_with_fallback
  end

  test 'model_with_fallback returns ApplicationConfig.llm_model when model is nil' do
    config = TopicClassifierConfig.new
    config.stubs(:model).returns(nil)

    assert_equal ApplicationConfig.llm_model, config.model_with_fallback
  end

  test 'model_with_fallback returns ApplicationConfig.llm_model when model is blank' do
    config = TopicClassifierConfig.new
    config.stubs(:model).returns('')

    assert_equal ApplicationConfig.llm_model, config.model_with_fallback
  end

  test 'provider delegates to ApplicationConfig' do
    config = TopicClassifierConfig.new

    assert_equal ApplicationConfig.llm_provider, config.provider
  end

  test 'class methods delegate to singleton instance' do
    assert_equal 24, TopicClassifierConfig.inactivity_hours
    assert_equal ApplicationConfig.llm_provider, TopicClassifierConfig.provider
  end

  test 'inactivity_hours coerces to integer' do
    config = TopicClassifierConfig.new
    # anyway_config coerces on load, test the type
    assert_kind_of Integer, config.inactivity_hours
  end
end
