# frozen_string_literal: true

require 'test_helper'

class LeadNotificationJobTest < ActiveJob::TestCase
  setup do
    @lead = leads(:one)
  end

  test 'does nothing if lead not found' do
    assert_nothing_raised do
      LeadNotificationJob.perform_now(999_999)
    end
  end

  test 'does nothing if platform_admin_chat_id is blank' do
    # platform_admin_chat_id по умолчанию nil в тестах
    assert_nothing_raised do
      LeadNotificationJob.perform_now(@lead.id)
    end
  end

  test 'build_message includes lead data' do
    job = LeadNotificationJob.new

    message = job.send(:build_message, @lead)

    assert_includes message, @lead.name
    assert_includes message, @lead.phone
    assert_includes message, "/leads/#{@lead.id}"
  end

  test 'admin_lead_url generates correct url' do
    job = LeadNotificationJob.new

    url = job.send(:admin_lead_url, @lead)

    assert_includes url, "/leads/#{@lead.id}"
  end
end
