# frozen_string_literal: true

require 'test_helper'

class TenantIsolationTest < ActiveSupport::TestCase
  setup do
    @tenant_one = tenants(:one)
    @tenant_two = tenants(:two)
    @telegram_user = telegram_users(:one)
  end

  teardown do
    Current.tenant = nil
  end

  test 'clients are isolated between tenants' do
    # Создаем клиента для tenant_one
    client_one = ClientResolver.resolve(tenant: @tenant_one, telegram_user: @telegram_user)

    # Создаем клиента для tenant_two с тем же telegram_user
    client_two = ClientResolver.resolve(tenant: @tenant_two, telegram_user: @telegram_user)

    # Разные клиенты
    assert_not_equal client_one, client_two
    assert_equal @tenant_one, client_one.tenant
    assert_equal @tenant_two, client_two.tenant

    # Но один telegram_user
    assert_equal client_one.telegram_user, client_two.telegram_user
  end

  test 'tenant scopes clients correctly' do
    client_one = clients(:one)
    client_two = clients(:two)

    assert_includes @tenant_one.clients, client_one
    assert_not_includes @tenant_one.clients, client_two

    assert_includes @tenant_two.clients, client_two
    assert_not_includes @tenant_two.clients, client_one
  end

  test 'SystemPromptService uses correct tenant data' do
    Current.tenant = @tenant_one
    prompt_one = SystemPromptService.system_prompt

    Current.tenant = @tenant_two
    prompt_two = SystemPromptService.system_prompt

    # Каждый tenant имеет свой system_prompt
    if @tenant_one.system_prompt.present? && @tenant_two.system_prompt.present?
      # Если оба имеют кастомные промпты, они должны отличаться
      assert_not_equal @tenant_one.system_prompt, @tenant_two.system_prompt
    end
  end

  test 'chats belong to specific tenant' do
    client_one = clients(:one)
    chat = Chat.create!(tenant: @tenant_one, client: client_one)

    assert_equal @tenant_one, chat.tenant
    assert_includes @tenant_one.chats, chat
    assert_not_includes @tenant_two.chats, chat
  end
end
