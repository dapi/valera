# frozen_string_literal: true

require 'test_helper'

module Telegram
  class WebhookControllerTest < ActionDispatch::IntegrationTest
    include TelegramSupport

    test 'message method exists' do
      controller = Telegram::WebhookController.new
      assert_respond_to controller, :message
    end

    test 'start! method exists' do
      controller = Telegram::WebhookController.new
      assert_respond_to controller, :start!
    end

    test 'rejects messages when tenant has no admin_chat_id' do
      unconfigured_tenant = tenants(:unconfigured)
      assert_nil unconfigured_tenant.admin_chat_id, 'Fixture должен иметь пустой admin_chat_id'

      host! "#{unconfigured_tenant.key}.#{ApplicationConfig.host}"
      Tenant.any_instance.stubs(:bot_client).returns(Telegram.bot)

      post '/telegram/webhook',
           params: {
             update_id: 12345,
             message: {
               message_id: 1,
               from: { id: 123, is_bot: false, first_name: 'Test' },
               chat: { id: 123, type: 'private' },
               date: Time.current.to_i,
               text: 'Привет'
             }
           }.to_json,
           headers: {
             'X-Telegram-Bot-Api-Secret-Token' => unconfigured_tenant.webhook_secret,
             'Content-Type' => 'application/json'
           }

      assert_response :ok

      # Проверяем что бот отправил сообщение о том что не настроен
      sent_messages = Telegram.bot.requests[:sendMessage]
      assert sent_messages.present?, 'Должно быть отправлено сообщение'

      last_message = sent_messages.last
      assert_includes last_message[:text], 'не настроен',
                      "Сообщение должно содержать 'не настроен': #{last_message[:text]}"
    end

    test 'allows messages when tenant has admin_chat_id configured' do
      configured_tenant = tenants(:one)
      assert configured_tenant.admin_chat_id.present?, 'Fixture должен иметь admin_chat_id'

      host! "#{configured_tenant.key}.#{ApplicationConfig.host}"
      Tenant.any_instance.stubs(:bot_client).returns(Telegram.bot)

      # Мокаем LLM и MarkdownCleaner чтобы не делать реальный запрос
      mock_response = Struct.new(:content).new('Тестовый ответ')
      Chat.any_instance.stubs(:say).returns(mock_response)
      MarkdownCleanerService.stubs(:clean_with_line_breaks).returns('Тестовый ответ')

      post '/telegram/webhook',
           params: {
             update_id: 12345,
             message: {
               message_id: 1,
               from: { id: 123, is_bot: false, first_name: 'Test' },
               chat: { id: 123, type: 'private' },
               date: Time.current.to_i,
               text: 'Привет'
             }
           }.to_json,
           headers: {
             'X-Telegram-Bot-Api-Secret-Token' => configured_tenant.webhook_secret,
             'Content-Type' => 'application/json'
           }

      assert_response :ok

      # Проверяем что бот отправил ответ (не сообщение об ошибке)
      sent_messages = Telegram.bot.requests[:sendMessage]
      assert sent_messages.present?, 'Должно быть отправлено сообщение'

      last_message = sent_messages.last
      refute_includes last_message[:text], 'не настроен',
                      "Сообщение НЕ должно содержать 'не настроен': #{last_message[:text]}"
    end

    test 'rejects /start command when tenant has no admin_chat_id' do
      unconfigured_tenant = tenants(:unconfigured)

      host! "#{unconfigured_tenant.key}.#{ApplicationConfig.host}"
      Tenant.any_instance.stubs(:bot_client).returns(Telegram.bot)

      post '/telegram/webhook',
           params: {
             update_id: 12345,
             message: {
               message_id: 1,
               from: { id: 123, is_bot: false, first_name: 'Test' },
               chat: { id: 123, type: 'private' },
               date: Time.current.to_i,
               text: '/start'
             }
           }.to_json,
           headers: {
             'X-Telegram-Bot-Api-Secret-Token' => unconfigured_tenant.webhook_secret,
             'Content-Type' => 'application/json'
           }

      assert_response :ok

      # Проверяем что бот отправил сообщение о том что не настроен
      sent_messages = Telegram.bot.requests[:sendMessage]
      assert sent_messages.present?, 'Должно быть отправлено сообщение'

      last_message = sent_messages.last
      assert_includes last_message[:text], 'не настроен',
                      "Сообщение должно содержать 'не настроен': #{last_message[:text]}"
    end
  end
end
