# frozen_string_literal: true

require 'test_helper'

class PasswordLoginRateLimitTest < ActionDispatch::IntegrationTest
  def with_isolated_rate_store
    memory = ActiveSupport::Cache::MemoryStore.new
    captured_store = AuthController.cache_store
    assert_same captured_store, Tenants::SessionsController.cache_store
    original = captured_store.method(:increment)
    captured_store.define_singleton_method(:increment) { |*args, **options| memory.increment(*args, **options) }
    yield
  ensure
    captured_store.define_singleton_method(:increment, original) if original
  end

  test 'account limit is shared across main and tenant domains and normalizes email' do
    with_isolated_rate_store do
      ApplicationConfig.login_account_attempts.times do |attempt|
        host! attempt.even? ? ApplicationConfig.host : "#{tenants(:one).key}.#{ApplicationConfig.host}"
        path = attempt.even? ? '/login' : '/session'
        post path, params: { email: attempt.even? ? ' Review@Example.invalid ' : 'review@example.invalid', password: 'wrong' },
                   headers: { 'REMOTE_ADDR' => "192.0.2.#{attempt + 1}" }
        assert_response :unprocessable_entity
      end
      host! ApplicationConfig.host
      post '/login', params: { email: 'review@example.invalid', password: 'wrong' }, headers: { 'REMOTE_ADDR' => '192.0.2.99' }
      assert_response :too_many_requests
      assert response.headers['Retry-After'].present?
    end
  end

  test 'ip limit blocks attempts across different accounts' do
    with_isolated_rate_store do
      host! ApplicationConfig.host
      ApplicationConfig.login_ip_attempts.times do |attempt|
        post '/login', params: { email: "review#{attempt}@example.invalid", password: 'wrong' }
        assert_response :unprocessable_entity
      end
      post '/login', params: { email: 'last@example.invalid', password: 'wrong' }
      assert_response :too_many_requests
    end
  end
end
