# frozen_string_literal: true

require 'test_helper'

class TenantWebhookServiceTest < ActiveSupport::TestCase
  setup do
    @tenant = tenants(:one)
    @service = TenantWebhookService.new(@tenant)
  end

  # setup_webhook tests

  test 'setup_webhook calls Telegram API with correct parameters' do
    expected_url = @tenant.webhook_url

    mock_client = mock('Telegram::Bot::Client')
    mock_client.expects(:set_webhook).with(
      url: expected_url,
      secret_token: @tenant.webhook_secret
    ).returns({ 'ok' => true })

    Telegram::Bot::Client.stubs(:new)
                         .with(@tenant.bot_token, @tenant.bot_username)
                         .returns(mock_client)

    result = @service.setup_webhook

    assert_equal({ 'ok' => true }, result)
  end

  test 'setup_webhook raises TelegramApiError on API failure' do
    mock_client = mock('Telegram::Bot::Client')
    mock_client.expects(:set_webhook).raises(Telegram::Bot::Error.new('API error'))

    Telegram::Bot::Client.stubs(:new).returns(mock_client)

    error = assert_raises(TenantWebhookService::TelegramApiError) do
      @service.setup_webhook
    end

    assert_match(/setup_webhook failed/, error.message)
    assert_match(@tenant.key, error.message)
  end

  # remove_webhook tests

  test 'remove_webhook calls Telegram API' do
    mock_client = mock('Telegram::Bot::Client')
    mock_client.expects(:delete_webhook).returns({ 'ok' => true })

    Telegram::Bot::Client.stubs(:new).returns(mock_client)

    result = TenantWebhookService.new(@tenant).remove_webhook

    assert_equal({ 'ok' => true }, result)
  end

  test 'remove_webhook raises TelegramApiError on API failure' do
    mock_client = mock('Telegram::Bot::Client')
    mock_client.expects(:delete_webhook).raises(Telegram::Bot::Error.new('API error'))

    Telegram::Bot::Client.stubs(:new).returns(mock_client)

    error = assert_raises(TenantWebhookService::TelegramApiError) do
      TenantWebhookService.new(@tenant).remove_webhook
    end

    assert_match(/remove_webhook failed/, error.message)
  end

  # webhook_info tests

  test 'webhook_info returns current webhook info' do
    webhook_data = {
      'url' => "https://example.com/telegram/webhook/#{@tenant.key}",
      'has_custom_certificate' => false,
      'pending_update_count' => 0
    }

    mock_client = mock('Telegram::Bot::Client')
    mock_client.expects(:get_webhook_info).returns(webhook_data)

    Telegram::Bot::Client.stubs(:new).returns(mock_client)

    result = TenantWebhookService.new(@tenant).webhook_info

    assert_equal webhook_data, result
  end

  test 'webhook_info raises TelegramApiError on API failure' do
    mock_client = mock('Telegram::Bot::Client')
    mock_client.expects(:get_webhook_info).raises(Telegram::Bot::Error.new('API error'))

    Telegram::Bot::Client.stubs(:new).returns(mock_client)

    error = assert_raises(TenantWebhookService::TelegramApiError) do
      TenantWebhookService.new(@tenant).webhook_info
    end

    assert_match(/webhook_info failed/, error.message)
  end
end
