# frozen_string_literal: true

require 'test_helper'

class ClientResolverTest < ActiveSupport::TestCase
  setup do
    @tenant = tenants(:one)
    @telegram_user = telegram_users(:one)
    @existing_client = clients(:one)
  end

  test 'resolve returns existing client' do
    client = ClientResolver.resolve(tenant: @tenant, telegram_user: @telegram_user)

    assert_equal @existing_client, client
  end

  test 'resolve creates new client when not exists' do
    new_tenant = Tenant.create!(
      name: 'New Service',
      bot_token: 'resolver_test_token_1',
      bot_username: 'resolver_bot'
    )

    assert_difference 'Client.count', 1 do
      client = ClientResolver.resolve(tenant: new_tenant, telegram_user: @telegram_user)

      assert client.persisted?
      assert_equal new_tenant, client.tenant
      assert_equal @telegram_user, client.telegram_user
      assert_equal @telegram_user.name, client.name
    end
  end

  test 'find returns existing client without creating' do
    resolver = ClientResolver.new(tenant: @tenant, telegram_user: @telegram_user)

    assert_no_difference 'Client.count' do
      client = resolver.find
      assert_equal @existing_client, client
    end
  end

  test 'find returns nil when client does not exist' do
    new_tenant = Tenant.create!(
      name: 'New Service',
      bot_token: 'resolver_test_token_2',
      bot_username: 'resolver_bot'
    )

    resolver = ClientResolver.new(tenant: new_tenant, telegram_user: @telegram_user)

    assert_no_difference 'Client.count' do
      assert_nil resolver.find
    end
  end

  test 'exists? returns true for existing client' do
    resolver = ClientResolver.new(tenant: @tenant, telegram_user: @telegram_user)
    assert resolver.exists?
  end

  test 'exists? returns false when client does not exist' do
    new_tenant = Tenant.create!(
      name: 'New Service',
      bot_token: 'resolver_test_token_3',
      bot_username: 'resolver_bot'
    )

    resolver = ClientResolver.new(tenant: new_tenant, telegram_user: @telegram_user)
    assert_not resolver.exists?
  end

  test 'same telegram_user can be client of different tenants' do
    other_tenant = tenants(:two)
    other_telegram_user = telegram_users(:two)

    # Создаем клиента в другом тенанте с тем же telegram_user
    new_client = ClientResolver.resolve(tenant: other_tenant, telegram_user: @telegram_user)

    assert new_client.persisted?
    assert_equal other_tenant, new_client.tenant
    assert_equal @telegram_user, new_client.telegram_user
    assert_not_equal @existing_client, new_client
  end
end
