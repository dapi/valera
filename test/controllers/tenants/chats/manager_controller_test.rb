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

        post "/chats/#{@chat.id}/manager/takeover", as: :turbo_stream

        assert_redirected_to '/session/new'
      end

      test 'redirects to login when not authenticated for release' do
        reset!
        host! "#{@tenant.key}.#{ApplicationConfig.host}"

        post "/chats/#{@chat.id}/manager/release", as: :turbo_stream

        assert_redirected_to '/session/new'
      end

      test 'redirects to login when not authenticated for messages' do
        reset!
        host! "#{@tenant.key}.#{ApplicationConfig.host}"

        post "/chats/#{@chat.id}/manager/messages",
             params: { message: { content: 'test' } },
             as: :turbo_stream

        assert_redirected_to '/session/new'
      end

      # === Takeover Tests ===

      test 'takeover succeeds with valid chat' do
        @mock_bot_client.stubs(:send_message).returns({ 'result' => { 'message_id' => 123 } })

        post "/chats/#{@chat.id}/manager/takeover", as: :turbo_stream

        assert_response :success
        assert_turbo_stream_response
        assert_turbo_stream_replaces("chat_#{@chat.id}_controls")
        assert_turbo_stream_replaces("chat_#{@chat.id}_header")

        @chat.reload
        assert @chat.manager_active?
      end

      test 'takeover updates chat UI elements via turbo stream' do
        @mock_bot_client.stubs(:send_message).returns({ 'result' => { 'message_id' => 123 } })

        post "/chats/#{@chat.id}/manager/takeover", as: :turbo_stream

        assert_turbo_stream_replaces("chat_#{@chat.id}_header")
        assert_turbo_stream_replaces("chat_#{@chat.id}_controls")
        assert_turbo_stream_replaces("chat_#{@chat.id}_status")
      end

      test 'takeover with custom timeout_minutes' do
        @mock_bot_client.stubs(:send_message).returns({ 'result' => { 'message_id' => 123 } })

        freeze_time do
          post "/chats/#{@chat.id}/manager/takeover",
               params: { timeout_minutes: 60 },
               as: :turbo_stream

          assert_response :success
          @chat.reload
          assert_equal 60.minutes.from_now.to_i, @chat.manager_active_until.to_i
        end
      end

      test 'takeover without notification' do
        @mock_bot_client.expects(:send_message).never

        post "/chats/#{@chat.id}/manager/takeover",
             params: { notify_client: false },
             as: :turbo_stream

        assert_response :success
        @chat.reload
        assert @chat.manager_active?
      end

      test 'takeover with unrecognized notify_client value defaults to notification' do
        @mock_bot_client.expects(:send_message).once.returns({ 'result' => { 'message_id' => 123 } })

        post "/chats/#{@chat.id}/manager/takeover",
             params: { notify_client: 'invalid_value' },
             as: :turbo_stream

        assert_response :success
      end

      test 'takeover fails for already taken chat' do
        @chat.takeover_by_manager!(@owner)

        post "/chats/#{@chat.id}/manager/takeover", as: :turbo_stream

        assert_response :unprocessable_entity
        assert_turbo_stream_response
        assert_turbo_stream_updates('flash')
      end

      test 'takeover returns 404 for chat from another tenant' do
        other_chat = chats(:two)

        post "/chats/#{other_chat.id}/manager/takeover", as: :turbo_stream

        assert_response :not_found
      end

      # === Release Tests ===

      test 'release succeeds for manager-controlled chat' do
        @mock_bot_client.stubs(:send_message).returns({ 'result' => { 'message_id' => 123 } })
        @chat.takeover_by_manager!(@owner)

        post "/chats/#{@chat.id}/manager/release", as: :turbo_stream

        assert_response :success
        assert_turbo_stream_response

        @chat.reload
        assert_not @chat.manager_active?
      end

      test 'release without notification' do
        @chat.takeover_by_manager!(@owner)
        @mock_bot_client.expects(:send_message).never

        post "/chats/#{@chat.id}/manager/release",
             params: { notify_client: false },
             as: :turbo_stream

        assert_response :success
        @chat.reload
        assert_not @chat.manager_active?
      end

      test 'release returns 404 for chat from another tenant' do
        other_chat = chats(:two)

        post "/chats/#{other_chat.id}/manager/release", as: :turbo_stream

        assert_response :not_found
      end

      test 'release fails for bot-controlled chat' do
        # Chat is NOT in manager mode (default state)
        assert_not @chat.manager_mode?

        post "/chats/#{@chat.id}/manager/release", as: :turbo_stream

        assert_response :unprocessable_entity
        assert_turbo_stream_updates('flash')
      end

      # === Messages Tests ===

      test 'create_message succeeds for manager-controlled chat' do
        @mock_bot_client.stubs(:send_message).returns({ 'result' => { 'message_id' => 123 } })
        @chat.takeover_by_manager!(@owner)

        assert_difference -> { @chat.messages.count }, 1 do
          post "/chats/#{@chat.id}/manager/messages",
               params: { message: { content: 'Hello from manager!' } },
               as: :turbo_stream
        end

        assert_response :success
        assert_turbo_stream_response

        message = @chat.messages.last
        assert_equal 'Hello from manager!', message.content
        assert_equal 'manager', message.role
      end

      test 'create_message appends message and replaces controls' do
        @mock_bot_client.stubs(:send_message).returns({ 'result' => { 'message_id' => 123 } })
        @chat.takeover_by_manager!(@owner)

        post "/chats/#{@chat.id}/manager/messages",
             params: { message: { content: 'Test message' } },
             as: :turbo_stream

        assert_turbo_stream_appends('chat_messages')
        assert_turbo_stream_replaces("chat_#{@chat.id}_controls")
      end

      test 'create_message fails without content' do
        @chat.takeover_by_manager!(@owner)

        post "/chats/#{@chat.id}/manager/messages",
             params: { message: { content: '' } },
             as: :turbo_stream

        assert_response :unprocessable_entity
        assert_turbo_stream_updates('flash')
      end

      test 'create_message fails for bot-controlled chat' do
        post "/chats/#{@chat.id}/manager/messages",
             params: { message: { content: 'Hello!' } },
             as: :turbo_stream

        assert_response :unprocessable_entity
        assert_turbo_stream_updates('flash')
      end

      test 'create_message fails for non-active manager' do
        other_user = users(:two)
        @chat.takeover_by_manager!(other_user)

        post "/chats/#{@chat.id}/manager/messages",
             params: { message: { content: 'Hello!' } },
             as: :turbo_stream

        assert_response :unprocessable_entity
        assert_turbo_stream_updates('flash')
      end

      test 'create_message returns 404 for chat from another tenant' do
        other_chat = chats(:two)

        post "/chats/#{other_chat.id}/manager/messages",
             params: { message: { content: 'Hello!' } },
             as: :turbo_stream

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

        post "/chats/#{@chat.id}/manager/takeover", as: :turbo_stream

        assert_response :success
        @chat.reload
        assert @chat.manager_active?
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
             params: { message: { content: 'Message from member' } },
             as: :turbo_stream

        assert_response :success
      end

      # === Viewer Role Tests ===

      test 'viewer can access takeover endpoint' do
        viewer = users(:viewer_user_one)
        viewer.update!(password: 'password123')

        reset!
        host! "#{@tenant.key}.#{ApplicationConfig.host}"
        post '/session', params: { email: viewer.email, password: 'password123' }

        @mock_bot_client.stubs(:send_message).returns({ 'result' => { 'message_id' => 123 } })

        post "/chats/#{@chat.id}/manager/takeover", as: :turbo_stream

        assert_response :success
        @chat.reload
        assert @chat.manager_active?
      end

      # === Release Authorization Tests ===

      test 'release fails when different user tries to release' do
        other_user = users(:two)
        @chat.takeover_by_manager!(other_user)

        # Current user (@owner) tries to release chat taken by other_user
        post "/chats/#{@chat.id}/manager/release", as: :turbo_stream

        assert_response :unprocessable_entity
        assert_turbo_stream_updates('flash')
      end

      # === Timeout Expiry Tests ===

      test 'manager_active returns false after timeout expiry' do
        @mock_bot_client.stubs(:send_message).returns({ 'result' => { 'message_id' => 123 } })

        # Takeover with 1 minute timeout
        post "/chats/#{@chat.id}/manager/takeover",
             params: { timeout_minutes: 1 },
             as: :turbo_stream

        assert_response :success
        @chat.reload
        assert @chat.manager_active?

        # Travel past expiry - manager_active? checks timeout but doesn't auto-release
        # (auto-release happens via ChatTakeoverTimeoutJob)
        travel 2.minutes do
          @chat.reload
          # mode stays manager_mode until explicitly released
          assert @chat.manager_mode?
          # but manager_active? returns false when timeout expired
          assert_not @chat.manager_active?
        end
      end

      # === Error Response Tests ===

      test 'returns turbo stream error for non-existent chat' do
        post '/chats/999999/manager/takeover', as: :turbo_stream

        assert_response :not_found
        assert_turbo_stream_updates('flash')
      end

      test 'returns 400 for missing message params' do
        @chat.takeover_by_manager!(@owner)

        post "/chats/#{@chat.id}/manager/messages", params: {}, as: :turbo_stream

        assert_response :bad_request
      end

      # === Feature Toggle Tests ===

      test 'returns 404 when manager_takeover_enabled is false' do
        ApplicationConfig.stubs(:manager_takeover_enabled).returns(false)

        post "/chats/#{@chat.id}/manager/takeover", as: :turbo_stream

        assert_response :not_found
        assert_turbo_stream_updates('flash')
      end

      test 'release returns 404 when manager_takeover_enabled is false' do
        @chat.takeover_by_manager!(@owner)
        ApplicationConfig.stubs(:manager_takeover_enabled).returns(false)

        post "/chats/#{@chat.id}/manager/release", as: :turbo_stream

        assert_response :not_found
        assert_turbo_stream_updates('flash')
      end

      test 'create_message returns 404 when manager_takeover_enabled is false' do
        @chat.takeover_by_manager!(@owner)
        ApplicationConfig.stubs(:manager_takeover_enabled).returns(false)

        post "/chats/#{@chat.id}/manager/messages",
             params: { message: { content: 'Hello!' } },
             as: :turbo_stream

        assert_response :not_found
        assert_turbo_stream_updates('flash')
      end

      private

      # Helper to assert response is turbo stream
      def assert_turbo_stream_response
        assert_match %r{text/vnd\.turbo-stream\.html}, response.content_type
      end

      # Helper to assert turbo stream replace action for target
      def assert_turbo_stream_replaces(target)
        assert_match %r{<turbo-stream[^>]*action="replace"[^>]*target="#{target}"}, response.body
      end

      # Helper to assert turbo stream update action for target
      def assert_turbo_stream_updates(target)
        assert_match %r{<turbo-stream[^>]*action="update"[^>]*target="#{target}"}, response.body
      end

      # Helper to assert turbo stream append action for target
      def assert_turbo_stream_appends(target)
        assert_match %r{<turbo-stream[^>]*action="append"[^>]*target="#{target}"}, response.body
      end
    end
  end
end
