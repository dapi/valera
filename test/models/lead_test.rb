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
end
