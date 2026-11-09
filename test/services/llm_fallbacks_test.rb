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

  test 'reports a fallback to GlitchTip as a warning with the models involved' do
    error = RubyLLM::UnauthorizedError.new('subscription session expired')
    fallback = stub(from: stub(id: 'kimi-subscription'), to: stub(id: 'deepseek-v4-flash'), attempt: 2, error: error)
    Sentry.expects(:capture_exception).with(
      error,
      level: :warning,
      fingerprint: [ 'llm-fallback-kimi-subscription-RubyLLM::UnauthorizedError' ],
      contexts: { llm_fallback: { from: 'kimi-subscription', to: 'deepseek-v4-flash',
                                attempt: 2, error_class: 'RubyLLM::UnauthorizedError' } }
    )

    LlmFallbacks.report(fallback)
  end
end
