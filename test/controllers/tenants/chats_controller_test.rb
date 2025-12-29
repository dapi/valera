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
      # Проверяем что показаны все сообщения чата (2 сообщения в фикстурах)
      assert_select '.whitespace-pre-wrap', count: 2
    end

    test 'show displays all messages for chat' do
      host! "#{@tenant.key}.#{ApplicationConfig.host}"
      post '/session', params: { email: @owner.email, password: 'password123' }

      get "/chats/#{@chat.id}"

      assert_response :success
      # Проверяем наличие сообщений пользователя и ассистента
      assert_select '.bg-blue-500', count: 1  # user message
      assert_select '.bg-white.border', count: 1  # assistant message
    end
  end
end
