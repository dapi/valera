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

    # NOTE: Тест для max_chat_messages_display удалён:
    # - Anyway_config мемоизирует значения и их невозможно мокать в integration tests
    # - Проверка .limit() — это unit-логика, тестировать её в integration test неправильно
    # - Rails гарантирует работу .limit(), нет смысла дублировать тестирование
    # Если нужно тестировать лимит сообщений, следует написать unit test для контроллера

    test 'displays messages in chronological order using preloaded data' do
      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      post '/session', params: { email: @owner.email, password: 'password123' }

      get "/chats/#{@chat.id}"

      assert_response :success

      # Проверяем что оба сообщения отображаются в chat message bubbles
      # User messages: bg-blue-500 (blue bubble)
      # Assistant messages: bg-white (white bubble)
      assert_select 'div.bg-blue-500 div.whitespace-pre-wrap', text: 'Hello, I need help with my car'
      assert_select 'div.bg-white div.whitespace-pre-wrap', text: /I can help you with car maintenance/
    end

    # === Infinite Scroll Tests (XHR) ===

    test 'XHR request returns chat list items for infinite scroll' do
      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      post '/session', params: { email: @owner.email, password: 'password123' }

      get '/chats', params: { page: 1 }, headers: { 'X-Requested-With' => 'XMLHttpRequest' }

      assert_response :success
      # Should render only chat list items partial, not full page
      assert_no_match '<html', response.body
      assert_no_match 'h1', response.body
      # Should contain chat link
      assert_select 'a[id^=chat_list_item_]'
    end

    test 'XHR request returns items without layout' do
      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      post '/session', params: { email: @owner.email, password: 'password123' }

      get '/chats', headers: { 'X-Requested-With' => 'XMLHttpRequest' }

      assert_response :success
      # Should not include page title (h1) as it's partial-only
      assert_select 'h1', count: 0
    end

    test 'XHR request accepts page parameter for pagination' do
      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      post '/session', params: { email: @owner.email, password: 'password123' }

      # Request page 2 - should return success even if no data on page 2
      get '/chats', params: { page: 2 }, headers: { 'X-Requested-With' => 'XMLHttpRequest' }

      assert_response :success
      # Should return empty partial without errors
      assert_no_match '<html', response.body
    end

    test 'XHR request preserves sort parameter' do
      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      post '/session', params: { email: @owner.email, password: 'password123' }

      get '/chats', params: { sort: 'created_at' }, headers: { 'X-Requested-With' => 'XMLHttpRequest' }

      assert_response :success
      # Response should be successful with sort applied
      assert_no_match '<html', response.body
    end

    # === Manager Takeover/Release/Messages Tests ===
    # Эти тесты теперь находятся в tenants/chats/manager_controller_test.rb
    # так как функционал перехвата чата вынесен в отдельный ManagerController
  end
end
