#!/usr/bin/env ruby

require 'telegram/bot'

# Базовый пример Telegram бота с обработкой команд
class BasicBot
  def initialize(token)
    @bot = Telegram::Bot::Client.new(token)
  end

  def start
    puts "Starting bot..."

    @bot.listen do |message|
      handle_message(message)
    end
  rescue Telegram::Bot::Exceptions::ResponseError => e
    puts "Error: #{e.description}"
    sleep 5
    retry
  end

  private

  def handle_message(message)
    case message.text
    when '/start'
      handle_start(message)
    when '/help'
      handle_help(message)
    when '/info'
      handle_info(message)
    when '/keyboard'
      handle_keyboard(message)
    when '/inline'
      handle_inline(message)
    else
      handle_unknown(message)
    end
  rescue => e
    puts "Error handling message: #{e.message}"
    send_error_message(message.chat.id)
  end

  def handle_start(message)
    @bot.api.send_message(
      chat_id: message.chat.id,
      text: "Привет, #{message.from.first_name}! Я тестовый бот. 👋\n\n" \
            "Доступные команды:\n" \
            "/help - справка\n" \
            "/info - информация о боте\n" \
            "/keyboard - показать клавиатуру\n" \
            "/inline - инлайн кнопки"
    )
  end

  def handle_help(message)
    help_text = <<~HELP
      *Справка по командам:*

      `/start` - приветствие
      `/help` - эта справка
      `/info` - информация о боте
      `/keyboard` - показать Reply клавиатуру
      `/inline` - показать инлайн кнопки

      *Особенности:*
      • Бот поддерживает форматирование текста
      • Работает с различными типами сообщений
      • Обрабатывает callback от кнопок
    HELP

    @bot.api.send_message(
      chat_id: message.chat.id,
      text: help_text,
      parse_mode: 'Markdown'
    )
  end

  def handle_info(message)
    bot_info = @bot.api.get_me

    info_text = <<~INFO
      *Информация о боте:*

      Имя: #{bot_info.first_name}
      Username: @#{bot_info.username}
      ID: #{bot_info.id}

      *Ваша информация:*
      Имя: #{message.from.first_name}
      Username: #{message.from.username}
      ID: #{message.from.id}

      *Чат:*
      Тип: #{message.chat.type}
      ID: #{message.chat.id}
    INFO

    @bot.api.send_message(
      chat_id: message.chat.id,
      text: info_text,
      parse_mode: 'Markdown'
    )
  end

  def handle_keyboard(message)
    keyboard = Telegram::Bot::Types::ReplyKeyboardMarkup.new(
      keyboard: [
        ['👋 Приветствие', 'ℹ️ Информация'],
        ['⌨️ Скрыть клавиатуру']
      ],
      resize_keyboard: true,
      one_time_keyboard: false
    )

    @bot.api.send_message(
      chat_id: message.chat.id,
      text: 'Выберите действие:',
      reply_markup: keyboard
    )
  end

  def handle_inline(message)
    inline_keyboard = Telegram::Bot::Types::InlineKeyboardMarkup.new(
      inline_keyboard: [
        [
          Telegram::Bot::Types::InlineKeyboardButton.new(
            text: '🔍 Google',
            url: 'https://google.com'
          ),
          Telegram::Bot::Types::InlineKeyboardButton.new(
            text: '💬 Callback',
            callback_data: 'callback_test'
          )
        ],
        [
          Telegram::Bot::Types::InlineKeyboardButton.new(
            text: '📱 Поделиться',
            switch_inline_query: 'share this'
          )
        ]
      ]
    )

    @bot.api.send_message(
      chat_id: message.chat.id,
      text: 'Инлайн кнопки:',
      reply_markup: inline_keyboard
    )
  end

  def handle_unknown(message)
    # Проверяем, может это callback от инлайн кнопки
    if message.is_a?(Telegram::Bot::Types::CallbackQuery)
      handle_callback(message)
    elsif message.text&.include?('Приветствие')
      @bot.api.send_message(
        chat_id: message.chat.id,
        text: "Снова привет, #{message.from.first_name}! 👋"
      )
    elsif message.text&.include?('Информация')
      handle_info(message)
    elsif message.text&.include?('Скрыть клавиатуру')
      hide_keyboard(message)
    else
      @bot.api.send_message(
        chat_id: message.chat.id,
        text: "Я не понимаю команду '#{message.text}'.\n" \
              "Используйте /help для списка доступных команд."
      )
    end
  end

  def handle_callback(callback_query)
    case callback_query.data
    when 'callback_test'
      @bot.api.answer_callback_query(
        callback_query_id: callback_query.id,
        text: 'Callback получен! ✅',
        show_alert: true
      )

      @bot.api.edit_message_text(
        chat_id: callback_query.message.chat.id,
        message_id: callback_query.message.message_id,
        text: "Callback обработан!\nДанные: #{callback_query.data}",
        reply_markup: callback_query.message.reply_markup
      )
    end
  end

  def hide_keyboard(message)
    hide_keyboard = Telegram::Bot::Types::ReplyKeyboardRemove.new

    @bot.api.send_message(
      chat_id: message.chat.id,
      text: 'Клавиатура скрыта',
      reply_markup: hide_keyboard
    )
  end

  def send_error_message(chat_id)
    @bot.api.send_message(
      chat_id: chat_id,
      text: 'Произошла ошибка при обработке сообщения. Попробуйте еще раз.'
    )
  rescue
    # Если даже ошибка не отправляется, просто логируем
    puts "Failed to send error message to chat #{chat_id}"
  end
end

# Запуск бота
if __FILE__ == $0
  token = ENV['TELEGRAM_BOT_TOKEN'] || ARGV[0]

  unless token
    puts "Usage: #{$0} <BOT_TOKEN>"
    puts "Or set TELEGRAM_BOT_TOKEN environment variable"
    exit 1
  end

  bot = BasicBot.new(token)
  bot.start
end