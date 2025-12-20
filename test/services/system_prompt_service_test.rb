# frozen_string_literal: true

require 'test_helper'

class SystemPromptServiceTest < ActiveSupport::TestCase
  setup do
    @tenant = tenants(:one)
  end

  test 'raises error when tenant is nil' do
    assert_raises(ArgumentError) do
      SystemPromptService.new(nil)
    end
  end

  test 'uses tenant system_prompt' do
    @tenant.update!(
      system_prompt: 'Tenant prompt with {{COMPANY_INFO}} and {{PRICE_LIST}}',
      company_info: 'Tenant Company Info',
      price_list: 'Tenant Price List'
    )

    service = SystemPromptService.new(@tenant)
    prompt = service.system_prompt

    assert_includes prompt, 'Tenant Company Info'
    assert_includes prompt, 'Tenant Price List'
  end

  test 'returns empty string for blank tenant fields' do
    @tenant.update!(system_prompt: '', company_info: nil, price_list: nil)

    service = SystemPromptService.new(@tenant)
    prompt = service.system_prompt

    # Пустые поля заменяются на пустые строки
    assert_equal '', prompt
  end

  test 'includes current time when placeholder present' do
    @tenant.update!(system_prompt: 'Current time: {{CURRENT_TIME}}')

    service = SystemPromptService.new(@tenant)
    prompt = service.system_prompt

    # Проверяем что время подставляется (формат dd.mm.yyyy HH:MM)
    assert_match(/\d{2}\.\d{2}\.\d{4} \d{2}:\d{2}/, prompt)
  end
end
