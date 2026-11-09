# frozen_string_literal: true

require 'test_helper'

class ErrorLoggerTest < ActiveSupport::TestCase
  class Reporter
    include ErrorLogger
  end

  test 'reports rescued errors with structured context to GlitchTip' do
    error = RuntimeError.new('test failure')
    Sentry.expects(:capture_exception).with(error, extra: { operation: 'test' })

    Reporter.log_error_with_backtrace(error, operation: 'test')
  end

  test 'captures CSRF failures for login diagnostics' do
    assert_not_includes Sentry.configuration.excluded_exceptions, 'ActionController::InvalidAuthenticityToken'
  end

  test 'scrubs request user and breadcrumbs before transmission' do
    event = Sentry::ErrorEvent.new(configuration: Sentry.configuration)
    event.rack_env = { 'REQUEST_METHOD' => 'POST', 'PATH_INFO' => '/session' }
    event.request.data = { password: 'synthetic-password' }
    event.user = { email: 'synthetic@example.test' }
    event.breadcrumbs = Sentry::BreadcrumbBuffer.new

    result = Sentry.configuration.before_send.call(event, {})

    assert_nil result.request.data
    assert_nil result.request.query_string
    assert_nil result.request.cookies
    assert_empty result.request.headers
    assert_empty result.request.env
    assert_nil result.user
    assert_nil result.breadcrumbs
  end
end
