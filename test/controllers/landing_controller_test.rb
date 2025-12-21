require 'test_helper'

class LandingControllerTest < ActionDispatch::IntegrationTest
  test 'should get landing page' do
    get root_url
    assert_response :success
    assert_select 'h1', /AI-ассистент/
  end

  test 'should create lead with valid params' do
    assert_difference('Lead.count') do
      post leads_url, params: {
        lead: {
          name: 'Иван Петров',
          phone: '+7 999 123 45 67'
        }
      }
    end

    assert_redirected_to root_url
    lead = Lead.last
    assert_equal 'Иван Петров', lead.name
    assert_equal 'landing_page', lead.source
  end

  test 'should not create lead with invalid params' do
    assert_no_difference('Lead.count') do
      post leads_url, params: {
        lead: {
          name: '',
          phone: ''
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test 'should save utm params' do
    post leads_url, params: {
      lead: {
        name: 'Иван Петров',
        phone: '+7 999 123 45 67'
      },
      utm_source: 'yandex',
      utm_medium: 'cpc',
      utm_campaign: 'landing'
    }

    lead = Lead.last
    assert_equal 'yandex', lead.utm_source
    assert_equal 'cpc', lead.utm_medium
    assert_equal 'landing', lead.utm_campaign
  end
end
