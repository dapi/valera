# frozen_string_literal: true

require 'test_helper'

module Tenants
  module Chats
    class ManagerControllerTest < ActionDispatch::IntegrationTest
      setup do
        @tenant = tenants(:one)
        @owner = @tenant.owner
        @owner.update!(password: 'password123')
        @chat = chats(:one)

        # Mock telegram bot client for all tenants
        @mock_bot_client = mock('bot_client')
        Tenant.any_instance.stubs(:bot_client).returns(@mock_bot_client)

        # Login
        host! "#{@tenant.key}.#{ApplicationConfig.host}"
        post '/session', params: { email: @owner.email, password: 'password123' }
      end

      # === Authentication Tests ===

      test 'redirects to login when not authenticated for takeover' do
        reset!
        host! "#{@tenant.key}.#{ApplicationConfig.host}"

        post "/chats/#{@chat.id}/manager/takeover"

        assert_redirected_to '/session/new'
      end

      test 'redirects to login when not authenticated for release' do
        reset!
        host! "#{@tenant.key}.#{ApplicationConfig.host}"

        post "/chats/#{@chat.id}/manager/release"

        assert_redirected_to '/session/new'
      end

      test 'redirects to login when not authenticated for messages' do
        reset!
        host! "#{@tenant.key}.#{ApplicationConfig.host}"

        post "/chats/#{@chat.id}/manager/messages", params: { message: { content: 'test' } }

        assert_redirected_to '/session/new'
      end

      # === Takeover Tests ===

      test 'takeover succeeds with valid chat' do
        @mock_bot_client.stubs(:send_message).returns({ 'result' => { 'message_id' => 123 } })

        post "/chats/#{@chat.id}/manager/takeover"

        assert_response :success
        json = JSON.parse(response.body)
        assert json['success']
        assert json['chat']['manager_active']
        assert_not_nil json['active_until']
      end

      test 'takeover returns json with chat data' do
        @mock_bot_client.stubs(:send_message).returns({ 'result' => { 'message_id' => 123 } })

        post "/chats/#{@chat.id}/manager/takeover"

        json = JSON.parse(response.body)
        assert_includes json.keys, 'chat'
        assert_includes json['chat'].keys, 'id'
        assert_includes json['chat'].keys, 'manager_active'
        assert_includes json['chat'].keys, 'manager_user_id'
      end

      test 'takeover with custom timeout_minutes' do
        @mock_bot_client.stubs(:send_message).returns({ 'result' => { 'message_id' => 123 } })

        freeze_time do
          post "/chats/#{@chat.id}/manager/takeover", params: { timeout_minutes: 60 }

          json = JSON.parse(response.body)
          assert json['success']
          expected_time = 60.minutes.from_now.as_json
          assert_equal expected_time, json['active_until']
        end
      end

      test 'takeover without notification' do
        @mock_bot_client.expects(:send_message).never

        post "/chats/#{@chat.id}/manager/takeover", params: { notify_client: false }

        json = JSON.parse(response.body)
        assert json['success']
        assert_nil json['notification_sent']
      end

      test 'takeover fails for already taken chat' do
        @chat.takeover_by_manager!(@owner)

        post "/chats/#{@chat.id}/manager/takeover"

        assert_response :unprocessable_entity
        json = JSON.parse(response.body)
        assert_not json['success']
        assert_equal 'Chat is already in manager mode', json['error']
      end

      test 'takeover returns 404 for chat from another tenant' do
        other_chat = chats(:two)

        post "/chats/#{other_chat.id}/manager/takeover"

        assert_response :not_found
      end

      # === Release Tests ===

      test 'release succeeds for manager-controlled chat' do
        @mock_bot_client.stubs(:send_message).returns({ 'result' => { 'message_id' => 123 } })
        @chat.takeover_by_manager!(@owner)

        post "/chats/#{@chat.id}/manager/release"

        assert_response :success
        json = JSON.parse(response.body)
        assert json['success']
        assert_not json['chat']['manager_active']
      end

      test 'release without notification' do
        @chat.takeover_by_manager!(@owner)
        @mock_bot_client.expects(:send_message).never

        post "/chats/#{@chat.id}/manager/release", params: { notify_client: false }

        json = JSON.parse(response.body)
        assert json['success']
        assert_nil json['notification_sent']
      end

      test 'release returns 404 for chat from another tenant' do
        other_chat = chats(:two)

        post "/chats/#{other_chat.id}/manager/release"

        assert_response :not_found
      end

      test 'release fails for bot-controlled chat' do
        # Chat is NOT in manager mode (default state)
        assert_not @chat.manager_mode?

        post "/chats/#{@chat.id}/manager/release"

        assert_response :unprocessable_entity
        json = JSON.parse(response.body)
        assert_not json['success']
        assert_equal 'Chat is not in manager mode', json['error']
      end

      # === Messages Tests ===

      test 'create_message succeeds for manager-controlled chat' do
        @mock_bot_client.stubs(:send_message).returns({ 'result' => { 'message_id' => 123 } })
        @chat.takeover_by_manager!(@owner)

        post "/chats/#{@chat.id}/manager/messages",
             params: { message: { content: 'Hello from manager!' } }

        assert_response :created
        json = JSON.parse(response.body)
        assert json['success']
        assert_equal 'Hello from manager!', json['message']['content']
        assert_equal 'manager', json['message']['role']
      end

      test 'create_message returns message data' do
        @mock_bot_client.stubs(:send_message).returns({ 'result' => { 'message_id' => 123 } })
        @chat.takeover_by_manager!(@owner)

        post "/chats/#{@chat.id}/manager/messages",
             params: { message: { content: 'Test message' } }

        json = JSON.parse(response.body)
        assert_includes json['message'].keys, 'id'
        assert_includes json['message'].keys, 'role'
        assert_includes json['message'].keys, 'content'
        assert_includes json['message'].keys, 'created_at'
      end

      test 'create_message fails without content' do
        @chat.takeover_by_manager!(@owner)

        post "/chats/#{@chat.id}/manager/messages",
             params: { message: { content: '' } }

        assert_response :unprocessable_entity
        json = JSON.parse(response.body)
        assert_not json['success']
        assert_equal 'Content is required', json['error']
      end

      test 'create_message fails for bot-controlled chat' do
        post "/chats/#{@chat.id}/manager/messages",
             params: { message: { content: 'Hello!' } }

        assert_response :unprocessable_entity
        json = JSON.parse(response.body)
        assert_not json['success']
        assert_equal 'Chat is not in manager mode', json['error']
      end

      test 'create_message fails for non-active manager' do
        other_user = users(:two)
        @chat.takeover_by_manager!(other_user)

        post "/chats/#{@chat.id}/manager/messages",
             params: { message: { content: 'Hello!' } }

        assert_response :unprocessable_entity
        json = JSON.parse(response.body)
        assert_not json['success']
        assert_equal 'User is not the active manager', json['error']
      end

      test 'create_message returns 404 for chat from another tenant' do
        other_chat = chats(:two)

        post "/chats/#{other_chat.id}/manager/messages",
             params: { message: { content: 'Hello!' } }

        assert_response :not_found
      end

      # === Member Access Tests ===

      test 'tenant member can access takeover' do
        member = users(:operator_user)
        member.update!(password: 'password123')

        reset!
        host! "#{@tenant.key}.#{ApplicationConfig.host}"
        post '/session', params: { email: member.email, password: 'password123' }

        @mock_bot_client.stubs(:send_message).returns({ 'result' => { 'message_id' => 123 } })

        post "/chats/#{@chat.id}/manager/takeover"

        assert_response :success
        json = JSON.parse(response.body)
        assert json['success']
      end

      test 'tenant member can send messages as manager' do
        member = users(:operator_user)
        member.update!(password: 'password123')

        reset!
        host! "#{@tenant.key}.#{ApplicationConfig.host}"
        post '/session', params: { email: member.email, password: 'password123' }

        @mock_bot_client.stubs(:send_message).returns({ 'result' => { 'message_id' => 123 } })
        @chat.takeover_by_manager!(member)

        post "/chats/#{@chat.id}/manager/messages",
             params: { message: { content: 'Message from member' } }

        assert_response :created
      end

      # === Viewer Role Tests ===

      test 'viewer can access takeover endpoint' do
        viewer = users(:viewer_user_one)
        viewer.update!(password: 'password123')

        reset!
        host! "#{@tenant.key}.#{ApplicationConfig.host}"
        post '/session', params: { email: viewer.email, password: 'password123' }

        @mock_bot_client.stubs(:send_message).returns({ 'result' => { 'message_id' => 123 } })

        post "/chats/#{@chat.id}/manager/takeover"

        assert_response :success
        json = JSON.parse(response.body)
        assert json['success']
      end

      # === Release Authorization Tests ===

      test 'release fails when different user tries to release' do
        other_user = users(:two)
        @chat.takeover_by_manager!(other_user)

        # Current user (@owner) tries to release chat taken by other_user
        post "/chats/#{@chat.id}/manager/release"

        assert_response :unprocessable_entity
        json = JSON.parse(response.body)
        assert_not json['success']
        assert_equal 'User is not authorized to release this chat', json['error']
      end

      # === Timeout Expiry Tests ===

      test 'manager_mode returns false after timeout expiry' do
        @mock_bot_client.stubs(:send_message).returns({ 'result' => { 'message_id' => 123 } })

        # Takeover with 1 minute timeout
        post "/chats/#{@chat.id}/manager/takeover", params: { timeout_minutes: 1 }

        assert_response :success
        json = JSON.parse(response.body)
        assert json['chat']['manager_active']

        # Travel past expiry - manager_mode? checks timeout and auto-releases
        travel 2.minutes do
          @chat.reload
          assert_not @chat.manager_mode?
        end
      end

      # === JSON Error Response Tests ===

      test 'returns JSON 404 for non-existent chat' do
        post '/chats/999999/manager/takeover'

        assert_response :not_found
        json = JSON.parse(response.body)
        assert_not json['success']
        assert_equal 'Chat not found', json['error']
      end

      test 'returns JSON 400 for missing message params' do
        @chat.takeover_by_manager!(@owner)

        post "/chats/#{@chat.id}/manager/messages", params: {}

        assert_response :bad_request
        json = JSON.parse(response.body)
        assert_not json['success']
        assert_includes json['error'], 'message'
      end
    end
  end
end
