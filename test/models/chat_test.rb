# frozen_string_literal: true

require 'test_helper'

class ChatTest < ActiveSupport::TestCase
  test 'fixture is valid and persisted' do
    chat = chats(:one)
    assert chat.valid?
    assert chat.persisted?
  end

  test 'new chat accepts a gateway model alias missing from the registry' do
    ApplicationConfig.stubs(:llm_provider).returns('openai')
    ApplicationConfig.stubs(:llm_model).returns('kimi-subscription')

    chat = Chat.create!(tenant: tenants(:one), client: clients(:one))

    assert_equal 'kimi-subscription', chat.model_id
    assert_equal 'openai', chat.provider.to_s
  end
end
