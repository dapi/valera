require 'test_helper'

class LeadTest < ActiveSupport::TestCase
  test 'valid lead with name and phone' do
    lead = Lead.new(name: 'Иван Петров', phone: '+7 999 123 45 67')
    assert lead.valid?
  end

  test 'invalid without name' do
    lead = Lead.new(phone: '+7 999 123 45 67')
    assert_not lead.valid?
    assert lead.errors[:name].any?
  end

  test 'invalid without phone' do
    lead = Lead.new(name: 'Иван Петров')
    assert_not lead.valid?
    assert lead.errors[:phone].any?
  end

  test 'company_name is optional' do
    lead = Lead.new(name: 'Иван Петров', phone: '+7 999 123 45 67', company_name: 'АвтоМастер')
    assert lead.valid?
  end

  test 'without_manager scope returns leads with no manager assigned' do
    manager = admin_users(:manager)
    lead_with_manager = Lead.create!(name: 'С менеджером', phone: '+7 999 111 11 11', manager: manager)
    lead_without_manager = Lead.create!(name: 'Без менеджера', phone: '+7 999 222 22 22')

    result = Lead.without_manager

    assert_includes result, lead_without_manager
    assert_not_includes result, lead_with_manager
  end
end
