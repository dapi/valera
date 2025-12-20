# frozen_string_literal: true

require 'test_helper'

class SystemPromptServiceTest < ActiveSupport::TestCase
  teardown do
    Current.tenant = nil
  end

  test 'uses ApplicationConfig when no tenant' do
    Current.tenant = nil

    prompt = SystemPromptService.system_prompt

    assert_includes prompt, ApplicationConfig.company_info
    assert_includes prompt, ApplicationConfig.price_list
  end

  test 'uses tenant system_prompt when available' do
    tenant = tenants(:one)
    tenant.update!(
      system_prompt: 'Tenant prompt with {{COMPANY_INFO}} and {{PRICE_LIST}}',
      company_info: 'Tenant Company Info',
      price_list: 'Tenant Price List'
    )
    Current.tenant = tenant

    prompt = SystemPromptService.system_prompt

    assert_includes prompt, 'Tenant Company Info'
    assert_includes prompt, 'Tenant Price List'
  end

  test 'falls back to ApplicationConfig for empty tenant fields' do
    tenant = tenants(:one)
    tenant.update!(system_prompt: nil, company_info: nil, price_list: nil)
    Current.tenant = tenant

    prompt = SystemPromptService.system_prompt

    assert_includes prompt, ApplicationConfig.company_info
    assert_includes prompt, ApplicationConfig.price_list
  end

  test 'includes current time when placeholder present' do
    tenant = tenants(:one)
    tenant.update!(system_prompt: 'Current time: {{CURRENT_TIME}}')
    Current.tenant = tenant

    prompt = SystemPromptService.system_prompt

    # Проверяем что время подставляется (формат dd.mm.yyyy HH:MM)
    assert_match(/\d{2}\.\d{2}\.\d{4} \d{2}:\d{2}/, prompt)
  end
end
