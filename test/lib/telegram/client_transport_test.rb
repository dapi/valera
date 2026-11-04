# frozen_string_literal: true

require 'test_helper'

class Telegram::ClientTransportTest < ActiveSupport::TestCase
  test 'configures transport for platform and dynamically created tenant bots' do
    ApplicationConfig.stubs(:telegram_api_proxy_url).returns('http://127.0.0.1:8119')

    Telegram::Bot::ClientStub.stub_all!(false) do
      [ Telegram::Bot::Client.new(token: '123:platform'),
        Telegram::Bot::Client.new('456:tenant', 'tenant_bot') ].each do |bot|
        assert_equal 'http://127.0.0.1:8119', bot.client.proxy.to_s
        assert_equal 10, bot.client.connect_timeout
        assert_equal 30, bot.client.send_timeout
        assert_equal 30, bot.client.receive_timeout
      end
    end
  end

  test 'works without an explicit Telegram proxy' do
    ApplicationConfig.stubs(:telegram_api_proxy_url).returns(nil)

    Telegram::Bot::ClientStub.stub_all!(false) do
      bot = Telegram::Bot::Client.new('123:direct')
      assert_equal 10, bot.client.connect_timeout
    end
  end
end
