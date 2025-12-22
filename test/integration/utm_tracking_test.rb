# frozen_string_literal: true

require 'test_helper'

class UtmTrackingIntegrationTest < ActionDispatch::IntegrationTest
  test 'lead form accepts UTM params and saves them' do
    assert_difference 'Lead.count', 1 do
      post leads_path, params: {
        lead: {
          name: 'Тест UTM',
          phone: '+7 999 123-45-67',
          utm_source: 'yandex',
          utm_medium: 'cpc',
          utm_campaign: 'autosrv'
        }
      }
    end

    lead = Lead.last
    assert_equal 'Тест UTM', lead.name
    assert_equal '+7 999 123-45-67', lead.phone
    assert_equal 'yandex', lead.utm_source
    assert_equal 'cpc', lead.utm_medium
    assert_equal 'autosrv', lead.utm_campaign
  end

  test 'lead form works without UTM params' do
    assert_difference 'Lead.count', 1 do
      post leads_path, params: {
        lead: {
          name: 'Тест без UTM',
          phone: '+7 999 987-65-43'
        }
      }
    end

    lead = Lead.last
    assert_equal 'Тест без UTM', lead.name
    assert_nil lead.utm_source
    assert_nil lead.utm_medium
    assert_nil lead.utm_campaign
  end

  test 'lead form accepts partial UTM params' do
    assert_difference 'Lead.count', 1 do
      post leads_path, params: {
        lead: {
          name: 'Тест частичный UTM',
          phone: '+7 999 555-66-77',
          utm_source: 'google'
        }
      }
    end

    lead = Lead.last
    assert_equal 'google', lead.utm_source
    assert_nil lead.utm_medium
    assert_nil lead.utm_campaign
  end

  test 'landing page renders with UTM hidden fields' do
    get root_path

    assert_response :success
    assert_select 'input[name="lead[utm_source]"][type="hidden"]'
    assert_select 'input[name="lead[utm_medium]"][type="hidden"]'
    assert_select 'input[name="lead[utm_campaign]"][type="hidden"]'
  end
end
