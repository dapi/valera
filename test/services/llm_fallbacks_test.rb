# frozen_string_literal: true

require 'test_helper'

class LlmFallbacksTest < ActiveSupport::TestCase
  test 'returns no fallbacks when not configured' do
    ApplicationConfig.stubs(:llm_fallback_model).returns(nil)
    ApplicationConfig.stubs(:llm_fallback_provider).returns(nil)

    assert_empty LlmFallbacks.models
  end

  test 'builds the configured fallback model with its provider' do
    ApplicationConfig.stubs(:llm_fallback_model).returns('deepseek-v4-flash')
    ApplicationConfig.stubs(:llm_fallback_provider).returns('deepseek')

    fallback = LlmFallbacks.models.sole

    assert_equal 'deepseek-v4-flash', fallback.id
    assert_equal 'deepseek', fallback.provider.to_s
  end

  test 'falls back on expired subscription authorization as well as transient errors' do
    assert_includes LlmFallbacks::ERRORS, RubyLLM::UnauthorizedError
    assert_includes LlmFallbacks::ERRORS, RubyLLM::RateLimitError
    assert_includes LlmFallbacks::ERRORS, Faraday::ConnectionFailed
  end
end
