# frozen_string_literal: true

require 'test_helper'

module Tenants
  class ChatsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @tenant = tenants(:one)
      @owner = @tenant.owner
      @owner.update!(password: 'password123')
      @chat = chats(:one)
    end

    test 'redirects to login when not authenticated' do
      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      get '/chats'

      assert_redirected_to '/session/new'
    end

    test 'shows chats list when authenticated' do
      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      post '/session', params: { email: @owner.email, password: 'password123' }

      get '/chats'

      assert_response :success
      assert_select 'h1', /Чаты/
    end

    test 'displays chat in the list' do
      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      post '/session', params: { email: @owner.email, password: 'password123' }

      get '/chats'

      assert_response :success
      assert_select 'a[href=?]', tenant_chat_path(@chat)
    end

    test 'shows chat detail page' do
      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      post '/session', params: { email: @owner.email, password: 'password123' }

      get "/chats/#{@chat.id}"

      assert_response :success
      assert_select 'h1', /Чаты/
    end

    test 'shows client name in chat header' do
      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      post '/session', params: { email: @owner.email, password: 'password123' }

      get "/chats/#{@chat.id}"

      assert_response :success
      assert_select 'a', text: @chat.client.display_name
    end

    test 'sorts by last_message_at by default' do
      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      post '/session', params: { email: @owner.email, password: 'password123' }

      get '/chats'

      assert_response :success
      assert_select 'select[name=sort] option[selected][value=last_message_at]'
    end

    test 'sorts by created_at when requested' do
      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      post '/session', params: { email: @owner.email, password: 'password123' }

      get '/chats', params: { sort: 'created_at' }

      assert_response :success
      assert_select 'select[name=sort] option[selected][value=created_at]'
    end

    test 'returns 404 for chat from another tenant' do
      other_chat = chats(:two)
      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      post '/session', params: { email: @owner.email, password: 'password123' }

      get "/chats/#{other_chat.id}"

      assert_response :not_found
    end

    test 'navigation includes chats link' do
      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      post '/session', params: { email: @owner.email, password: 'password123' }

      get '/'

      assert_response :success
      assert_select 'a[href=?]', tenant_chats_path, text: 'Чаты'
    end

    test 'index shows all messages for selected chat' do
      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      post '/session', params: { email: @owner.email, password: 'password123' }

      get '/chats'

      assert_response :success
      # Проверяем что показаны все сообщения чата по содержимому
      assert_match 'Hello, I need help with my car', response.body
      assert_match 'I can help you with car maintenance', response.body
    end

    test 'show displays all messages for chat' do
      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      post '/session', params: { email: @owner.email, password: 'password123' }

      get "/chats/#{@chat.id}"

      assert_response :success
      # Проверяем наличие сообщений пользователя и ассистента по содержимому
      assert_match 'Hello, I need help with my car', response.body
      assert_match 'I can help you with car maintenance', response.body
    end

    test 'limits messages to max_chat_messages_display config' do
      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      post '/session', params: { email: @owner.email, password: 'password123' }

      # Мокаем конфигурацию с лимитом в 1 сообщение
      ApplicationConfig.stubs(:max_chat_messages_display).returns(1)

      get "/chats/#{@chat.id}"

      assert_response :success
      # При лимите 1 показывается только последнее (assistant) сообщение
      assert_match 'I can help you with car maintenance', response.body
      assert_no_match(/Hello, I need help with my car/, response.body)
    end

    # === Takeover Tests ===

    test 'takeover changes chat to manager_mode' do
      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      post '/session', params: { email: @owner.email, password: 'password123' }

      # Mock Telegram API
      mock_bot_client = mock('bot_client')
      mock_bot_client.stubs(:send_message).returns(true)
      Tenant.any_instance.stubs(:bot_client).returns(mock_bot_client)

      post "/chats/#{@chat.id}/takeover", headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

      assert_response :success
      @chat.reload
      assert @chat.manager_mode?
      assert_equal @owner.id, @chat.taken_by_id
    end

    test 'takeover returns turbo_stream response' do
      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      post '/session', params: { email: @owner.email, password: 'password123' }

      mock_bot_client = mock('bot_client')
      mock_bot_client.stubs(:send_message).returns(true)
      Tenant.any_instance.stubs(:bot_client).returns(mock_bot_client)

      post "/chats/#{@chat.id}/takeover", headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

      assert_response :success
      assert_match 'turbo-stream', response.content_type
    end

    test 'takeover returns error if already taken' do
      @chat.update!(mode: :manager_mode, taken_by: @owner, taken_at: Time.current)

      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      post '/session', params: { email: @owner.email, password: 'password123' }

      post "/chats/#{@chat.id}/takeover", headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

      assert_response :success
      assert_match 'turbo-stream', response.content_type
      assert_match 'flash', response.body
    end

    # === Release Tests ===

    test 'release changes chat back to ai_mode' do
      @chat.update!(mode: :manager_mode, taken_by: @owner, taken_at: Time.current)

      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      post '/session', params: { email: @owner.email, password: 'password123' }

      mock_bot_client = mock('bot_client')
      mock_bot_client.stubs(:send_message).returns(true)
      Tenant.any_instance.stubs(:bot_client).returns(mock_bot_client)

      post "/chats/#{@chat.id}/release", headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

      assert_response :success
      @chat.reload
      assert @chat.ai_mode?
      assert_nil @chat.taken_by_id
    end

    test 'release returns turbo_stream response' do
      @chat.update!(mode: :manager_mode, taken_by: @owner, taken_at: Time.current)

      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      post '/session', params: { email: @owner.email, password: 'password123' }

      mock_bot_client = mock('bot_client')
      mock_bot_client.stubs(:send_message).returns(true)
      Tenant.any_instance.stubs(:bot_client).returns(mock_bot_client)

      post "/chats/#{@chat.id}/release", headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

      assert_response :success
      assert_match 'turbo-stream', response.content_type
    end

    test 'release returns error if not in manager_mode' do
      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      post '/session', params: { email: @owner.email, password: 'password123' }

      post "/chats/#{@chat.id}/release", headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

      assert_response :success
      assert_match 'flash', response.body
    end

    test 'release returns error if taken by different user' do
      # Create operator user (not owner, not admin)
      operator_user = users(:two)
      operator_user.update!(password: 'password123')
      TenantMembership.where(tenant: @tenant, user: operator_user).destroy_all
      TenantMembership.create!(tenant: @tenant, user: operator_user, role: :operator)

      # Chat is taken by another user (owner)
      @chat.update!(mode: :manager_mode, taken_by: @owner, taken_at: Time.current)

      # Login as operator (not the one who took the chat, not admin)
      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      post '/session', params: { email: operator_user.email, password: 'password123' }

      post "/chats/#{@chat.id}/release", headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

      assert_response :success
      assert_match 'flash', response.body
      # Chat should still be in manager_mode
      @chat.reload
      assert @chat.manager_mode?
    end

    # === Send Message Tests ===

    test 'send_message creates message when in manager_mode' do
      @chat.update!(mode: :manager_mode, taken_by: @owner, taken_at: Time.current)

      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      post '/session', params: { email: @owner.email, password: 'password123' }

      mock_bot_client = mock('bot_client')
      mock_bot_client.stubs(:send_message).returns(true)
      Tenant.any_instance.stubs(:bot_client).returns(mock_bot_client)

      assert_difference -> { @chat.messages.count }, 1 do
        post "/chats/#{@chat.id}/send_message", params: { text: 'Hello from manager' }
      end

      message = @chat.messages.last
      assert_equal 'Hello from manager', message.content
      assert_equal 'manager', message.sender_type
    end

    test 'send_message returns turbo_stream response' do
      @chat.update!(mode: :manager_mode, taken_by: @owner, taken_at: Time.current)

      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      post '/session', params: { email: @owner.email, password: 'password123' }

      mock_bot_client = mock('bot_client')
      mock_bot_client.stubs(:send_message).returns(true)
      Tenant.any_instance.stubs(:bot_client).returns(mock_bot_client)

      post "/chats/#{@chat.id}/send_message",
           params: { text: 'Hello from manager' },
           headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

      assert_response :success
      assert_match 'turbo-stream', response.content_type
    end

    test 'send_message returns error for empty message' do
      @chat.update!(mode: :manager_mode, taken_by: @owner, taken_at: Time.current)

      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      post '/session', params: { email: @owner.email, password: 'password123' }

      post "/chats/#{@chat.id}/send_message",
           params: { text: '' },
           headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

      assert_response :success
      assert_match 'flash', response.body
    end

    test 'send_message returns error if not in manager_mode' do
      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      post '/session', params: { email: @owner.email, password: 'password123' }

      post "/chats/#{@chat.id}/send_message",
           params: { text: 'Hello' },
           headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

      assert_response :success
      assert_match 'flash', response.body
    end

    test 'send_message returns error if taken by different user' do
      other_user = users(:two)
      @chat.update!(mode: :manager_mode, taken_by: other_user, taken_at: Time.current)

      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      post '/session', params: { email: @owner.email, password: 'password123' }

      post "/chats/#{@chat.id}/send_message",
           params: { text: 'Hello' },
           headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

      assert_response :success
      assert_match 'flash', response.body
    end
  end
end
