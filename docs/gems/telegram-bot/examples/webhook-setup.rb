#!/usr/bin/env ruby

# Пример настройки Telegram бота с использованием Webhooks
# Этот код демонстрирует как настроить webhook для Rails приложения

require 'telegram/bot'
require 'sinatra' # или использовать Rails

class TelegramWebhookBot
  def initialize(token)
    @bot = Telegram::Bot::Client.new(token)
  end

  # Установка webhook
  def set_webhook(webhook_url)
    response = @bot.api.set_webhook(url: webhook_url)
    if response.ok?
      puts "Webhook успешно установлен: #{webhook_url}"
    else
      puts "Ошибка установки webhook: #{response.description}"
    end
    response
  end

  # Получение информации о webhook
  def get_webhook_info
    @bot.api.get_webhook_info
  end

  # Удаление webhook
  def delete_webhook
    response = @bot.api.delete_webhook
    puts "Webhook удален" if response.ok?
    response
  end

  # Обработка входящего обновления
  def handle_update(update)
    message = update.message || update.edited_message || update.channel_post || update.edited_channel_post
    callback_query = update.callback_query
    inline_query = update.inline_query
    chosen_inline_result = update.chosen_inline_result
    shipping_query = update.shipping_query
    pre_checkout_query = update.pre_checkout_query
    poll = update.poll
    poll_answer = update.poll_answer
    my_chat_member = update.my_chat_member
    chat_member = update.chat_member
    chat_join_request = update.chat_join_request

    if message
      handle_message(message)
    elsif callback_query
      handle_callback_query(callback_query)
    elsif inline_query
      handle_inline_query(inline_query)
    elsif chosen_inline_result
      handle_chosen_inline_result(chosen_inline_result)
    elsif poll_answer
      handle_poll_answer(poll_answer)
    elsif chat_join_request
      handle_chat_join_request(chat_join_request)
    end
  end

  private

  def handle_message(message)
    chat_id = message.chat.id

    case message.text
    when '/start'
      @bot.api.send_message(
        chat_id: chat_id,
        text: "Бот работает через webhook! ✅\n" \
              "Текущее время: #{Time.now}"
      )
    when '/webhook_info'
      info = get_webhook_info
      @bot.api.send_message(
        chat_id: chat_id,
        text: "*Webhook информация:*\n" \
              "URL: #{info.url || 'не установлен'}\n" \
              "Пользовательские сертификаты: #{info.has_custom_certificate ? 'Да' : 'Нет'}\n" \
              "Ожидающие обновления: #{info.pending_update_count}\n" \
              "Последняя ошибка: #{info.last_error_message || 'нет'}",
        parse_mode: 'Markdown'
      )
    else
      @bot.api.send_message(
        chat_id: chat_id,
        text: "Сообщение получено через webhook: #{message.text}"
      )
    end
  end

  def handle_callback_query(callback_query)
    @bot.api.answer_callback_query(
      callback_query_id: callback_query.id,
      text: "Callback получен: #{callback_query.data}"
    )

    @bot.api.edit_message_text(
      chat_id: callback_query.message.chat.id,
      message_id: callback_query.message.message_id,
      text: "Callback обработан: #{callback_query.data}"
    )
  end

  def handle_inline_query(inline_query)
    results = [
      Telegram::Bot::Types::InlineQueryResultArticle.new(
        id: '1',
        title: 'Результат 1',
        input_message_content: Telegram::Bot::Types::InputTextMessageContent.new(
          message_text: 'Это результат инлайн поиска #1'
        )
      ),
      Telegram::Bot::Types::InlineQueryResultArticle.new(
        id: '2',
        title: 'Результат 2',
        input_message_content: Telegram::Bot::Types::InputTextMessageContent.new(
          message_text: 'Это результат инлайн поиска #2'
        )
      )
    ]

    @bot.api.answer_inline_query(
      inline_query_id: inline_query.id,
      results: results
    )
  end

  def handle_chosen_inline_result(chosen_inline_result)
    puts "User chose inline result: #{chosen_inline_result.result_id}"
  end

  def handle_poll_answer(poll_answer)
    puts "Poll answer received: #{poll_answer.poll_id}, options: #{poll_answer.option_ids}"
  end

  def handle_chat_join_request(chat_join_request)
    if chat_join_request.from
      @bot.api.approve_chat_join_request(
        chat_id: chat_join_request.chat.id,
        user_id: chat_join_request.from.id
      )

      @bot.api.send_message(
        chat_id: chat_join_request.chat.id,
        text: "Добро пожаловать в чат, #{chat_join_request.from.first_name}! 🎉"
      )
    end
  end
end

# Sinatra пример для webhook эндпоинта
configure do
  set :token, ENV['TELEGRAM_BOT_TOKEN']
  set :bot, TelegramWebhookBot.new(settings.token)
  set :webhook_url, ENV['TELEGRAM_WEBHOOK_URL']
end

# Установка webhook (выполняется один раз)
post '/set_webhook' do
  if params[:url]
    settings.bot.set_webhook(params[:url])
    "Webhook установлен: #{params[:url]}"
  else
    "Ошибка: укажите URL параметр"
  end
end

# Основной webhook эндпоинт
post '/webhook' do
  begin
    # В Telegram Bot API обновления приходят в формате JSON
    update = JSON.parse(request.body.read, symbolize_names: true)

    # Конвертируем хеш в объект типа Telegram::Bot::Types::Update
    update_object = Telegram::Bot::Types::Update.new(update)

    # Обрабатываем обновление
    settings.bot.handle_update(update_object)

    status 200
    'OK'
  rescue JSON::ParserError => e
    status 400
    "Invalid JSON: #{e.message}"
  rescue => e
    status 500
    "Error processing update: #{e.message}"
  end
end

# Информация о webhook
get '/webhook_info' do
  info = settings.bot.get_webhook_info
  content_type :json
  {
    url: info.url,
    has_custom_certificate: info.has_custom_certificate,
    pending_update_count: info.pending_update_count,
    last_error_date: info.last_error_date,
    last_error_message: info.last_error_message
  }.to_json
end

# Health check
get '/health' do
  'Bot is running'
end

# Запуск для тестирования
if __FILE__ == $0
  token = ENV['TELEGRAM_BOT_TOKEN'] || ARGV[0]
  webhook_url = ENV['TELEGRAM_WEBHOOK_URL'] || ARGV[1]

  unless token && webhook_url
    puts "Usage: #{$0} <BOT_TOKEN> <WEBHOOK_URL>"
    puts "Or set TELEGRAM_BOT_TOKEN and TELEGRAM_WEBHOOK_URL environment variables"
    exit 1
  end

  # Устанавливаем webhook
  bot = TelegramWebhookBot.new(token)
  bot.set_webhook(webhook_url)

  puts "Webhook установлен. Запустите сервер для приема обновлений:"
  puts "ruby webhook-setup.rb"
  puts "Webhook URL: #{webhook_url}"
  puts "Health check: http://localhost:4567/health"
  puts "Webhook info: http://localhost:4567/webhook_info"
end