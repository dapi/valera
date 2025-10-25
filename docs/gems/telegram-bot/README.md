# Telegram Bot Gem Documentation

## Overview
`telegram-bot-rb` - это Ruby gem для создания Telegram ботов с поддержкой всех основных функций Telegram Bot API.

## Basic Setup

### Installation
```ruby
gem 'telegram-bot'
```

### Basic Bot Example
```ruby
require 'telegram/bot'

token = 'YOUR_BOT_TOKEN'

Telegram::Bot::Client.run(token) do |bot|
  bot.listen do |message|
    case message.text
    when '/start'
      bot.api.send_message(chat_id: message.chat.id, text: "Hello, #{message.from.first_name}!")
    when '/stop'
      bot.api.send_message(chat_id: message.chat.id, text: "Bye!")
    else
      bot.api.send_message(chat_id: message.chat.id, text: "I don't understand this command")
    end
  end
end
```

## Core Components

### Bot Client
```ruby
# Create bot instance
bot = Telegram::Bot::Client.new(token)

# Send messages
bot.api.send_message(chat_id: chat_id, text: 'Hello!')

# Get bot info
bot.api.get_me
```

### Message Types
- `message.text` - текстовые сообщения
- `message.photo` - фото
- `message.document` - документы
- `message.audio` - аудио
- `message.video` - видео
- `message.voice` - голосовые сообщения
- `message.location` - геолокация
- `message.contact` - контакты

### Message Handlers
```ruby
# Text messages
bot.listen do |message|
  puts message.text
end

# Callback queries (inline keyboards)
bot.listen do |message|
  case message
  when Telegram::Bot::Types::CallbackQuery
    # Handle callback
    bot.api.answer_callback_query(callback_query_id: message.id)
  end
end
```

## Webhooks Setup

### Setting Webhook
```ruby
bot = Telegram::Bot::Client.new(token)
bot.api.set_webhook(url: 'https://your-domain.com/webhook')
```

### Rails Integration Example
```ruby
# config/routes.rb
Rails.application.routes.draw do
  post '/webhook' => 'telegram_webhook#update'
end

# app/controllers/telegram_webhook_controller.rb
class TelegramWebhookController < ApplicationController
  def update
    # Update telegram-bot-rb gem to support webhook mode
    Telegram::Bot::Client.update(params)
    head :ok
  end
end
```

## Keyboards

### Reply Keyboard
```ruby
keyboard = Telegram::Bot::Types::ReplyKeyboardMarkup.new(
  keyboard: [
    ['/button1', '/button2'],
    ['/button3']
  ],
  resize_keyboard: true,
  one_time_keyboard: true
)

bot.api.send_message(
  chat_id: message.chat.id,
  text: 'Choose option:',
  reply_markup: keyboard
)
```

### Inline Keyboard
```ruby
keyboard = Telegram::Bot::Types::InlineKeyboardMarkup.new(
  inline_keyboard: [
    [
      Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Option 1', callback_data: 'opt1'),
      Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Option 2', callback_data: 'opt2')
    ]
  ]
)

bot.api.send_message(
  chat_id: message.chat.id,
  text: 'Select:',
  reply_markup: keyboard
)
```

## File Handling

### Sending Files
```ruby
# Send photo
bot.api.send_photo(chat_id: chat_id, photo: Faraday::UploadIO.new('path/to/photo.jpg', 'image/jpeg'))

# Send document
bot.api.send_document(chat_id: chat_id, document: Faraday::UploadIO.new('path/to/file.pdf', 'application/pdf'))

# Send by file_id
bot.api.send_photo(chat_id: chat_id, photo: 'AgADAgADyqoxG6n8qUQHjJbLmXh2w')
```

### Downloading Files
```ruby
# Get file info
file_info = bot.api.get_file(file_id: message.photo.last.file_id)

# Download file
file_url = "https://api.telegram.org/file/bot#{token}/#{file_info.file_path}"
require 'open-uri'
File.open('downloaded.jpg', 'wb') { |f| f.write(open(file_url).read) }
```

## Common Patterns

### Command Handling
```ruby
COMMANDS = {
  '/start' => :handle_start,
  '/help' => :handle_help,
  '/settings' => :handle_settings
}.freeze

def handle_command(message)
  command = message.text.split.first
  method = COMMANDS[command]
  send(method, message) if method
end

private

def handle_start(message)
  # Handle start command
end

def handle_help(message)
  # Handle help command
end

def handle_settings(message)
  # Handle settings command
end
```

### State Management
```ruby
# Simple state management with session
user_sessions = {}

def handle_message(message)
  user_id = message.from.id
  session = user_sessions[user_id] ||= { state: :initial }

  case session[:state]
  when :initial
    handle_initial_state(message, session)
  when :waiting_for_name
    handle_name_input(message, session)
  end
end
```

## Error Handling

```ruby
begin
  bot.api.send_message(chat_id: chat_id, text: 'Hello')
rescue Telegram::Bot::Exceptions::ResponseError => e
  case e.error_code
  when 403
    puts "Bot was blocked by user"
  when 429
    puts "Too many requests, retry after #{e.parameters['retry_after']} seconds"
  end
rescue Faraday::TimeoutError, Faraday::ConnectionFailed
  puts "Network error, retrying..."
  retry
end
```

## Configuration

### Environment Configuration
```ruby
# config/initializers/telegram_bot.rb
Telegram::Bot.configure do |config|
  config.default = :production
  config.adapters = {
    production: {
      token: ENV['TELEGRAM_BOT_TOKEN'],
      username: ENV['TELEGRAM_BOT_USERNAME']
    },
    development: {
      token: ENV['TELEGRAM_BOT_TOKEN_DEV'],
      username: ENV['TELEGRAM_BOT_USERNAME_DEV']
    }
  }
end
```

## Testing

```ruby
# RSpec example
require 'telegram/bot/rspec/integration/rspec'

RSpec.describe TelegramBotController, type: :request do
  include Telegram::Bot::RSpec::Integration

  let(:bot) { Telegram::Bot::Client.new('fake_token') }
  let(:message) { Telegram::Bot::Types::Message.new(text: '/start', chat: chat, from: from) }

  before do
    allow(Telegram::Bot).to receive(:clients).and_return(bot)
  end

  it 'handles /start command' do
    dispatch_message(message)
    expect(response).to have_http_status(:ok)
  end
end
```

## Rate Limiting
- Не отправляйте более 30 сообщений в секунду одному и тому же пользователю
- Используйте очереди для массовых рассылок
- Обрабатывайте ошибки 429 (Too Many Requests)

## Security Notes
- Храните токен бота в безопасном месте (ENV переменные)
- Проверяйте входящие данные от пользователей
- Используйте webhook с HTTPS
- Ограничивайте доступ к эндпоинтам вебхука