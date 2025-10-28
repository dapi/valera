# Telegram Bot API Reference

## Core Classes

### Telegram::Bot::Client
Основной класс для работы с Telegram Bot API.

```ruby
# Инициализация
bot = Telegram::Bot::Client.new(token, username: optional_username)

# Запуск бота (long polling)
bot.listen do |message|
  # обработка сообщений
end

# Прямые вызовы API
bot.api.send_message(chat_id: chat_id, text: 'Hello')
```

### Методы API Client

#### Сообщения
- `send_message(chat_id:, text:, parse_mode: nil, entities: nil, disable_web_page_preview: nil, disable_notification: nil, reply_to_message_id: nil, allow_sending_without_reply: nil, reply_markup: nil)`
- `send_photo(chat_id:, photo:, caption: nil, parse_mode: nil, caption_entities: nil, disable_notification: nil, reply_to_message_id: nil, allow_sending_without_reply: nil, reply_markup: nil)`
- `send_audio(chat_id:, audio:, caption: nil, parse_mode: nil, caption_entities: nil, duration: nil, performer: nil, title: nil, thumb: nil, disable_notification: nil, reply_to_message_id: nil, allow_sending_without_reply: nil, reply_markup: nil)`
- `send_document(chat_id:, document:, caption: nil, parse_mode: nil, caption_entities: nil, disable_content_type_detection: nil, disable_notification: nil, reply_to_message_id: nil, allow_sending_without_reply: nil, reply_markup: nil)`
- `send_video(chat_id:, video:, duration: nil, width: nil, height: nil, thumb: nil, caption: nil, parse_mode: nil, caption_entities: nil, supports_streaming: nil, disable_notification: nil, reply_to_message_id: nil, allow_sending_without_reply: nil, reply_markup: nil)`
- `send_animation(chat_id:, animation:, duration: nil, width: nil, height: nil, thumb: nil, caption: nil, parse_mode: nil, caption_entities: nil, disable_notification: nil, reply_to_message_id: nil, allow_sending_without_reply: nil, reply_markup: nil)`
- `send_voice(chat_id:, voice:, caption: nil, parse_mode: nil, caption_entities: nil, duration: nil, disable_notification: nil, reply_to_message_id: nil, allow_sending_without_reply: nil, reply_markup: nil)`
- `send_video_note(chat_id:, video_note:, duration: nil, length: nil, thumb: nil, disable_notification: nil, reply_to_message_id: nil, allow_sending_without_reply: nil, reply_markup: nil)`

#### Медиа группы
- `send_media_group(chat_id:, media:, disable_notification: nil, reply_to_message_id: nil, allow_sending_without_reply: nil)`

#### Локация и контакты
- `send_location(chat_id:, latitude:, longitude:, horizontal_accuracy: nil, live_period: nil, heading: nil, proximity_alert_radius: nil, disable_notification: nil, reply_to_message_id: nil, allow_sending_without_reply: nil, reply_markup: nil)`
- `edit_message_live_location(chat_id: nil, message_id: nil, inline_message_id: nil, latitude:, longitude:, horizontal_accuracy: nil, heading: nil, proximity_alert_radius: nil, reply_markup: nil)`
- `stop_message_live_location(chat_id: nil, message_id: nil, inline_message_id: nil, reply_markup: nil)`
- `send_venue(chat_id:, latitude:, longitude:, title:, address:, foursquare_id: nil, foursquare_type: nil, google_place_id: nil, google_place_type: nil, disable_notification: nil, reply_to_message_id: nil, allow_sending_without_reply: nil, reply_markup: nil)`
- `send_contact(chat_id:, phone_number:, first_name:, last_name: nil, vcard: nil, disable_notification: nil, reply_to_message_id: nil, allow_sending_without_reply: nil, reply_markup: nil)`

#### Опросы
- `send_poll(chat_id:, question:, options:, is_anonymous: nil, type: nil, allows_multiple_answers: nil, correct_option_id: nil, explanation: nil, explanation_parse_mode: nil, explanation_entities: nil, open_period: nil, close_date: nil, is_closed: nil, disable_notification: nil, reply_to_message_id: nil, allow_sending_without_reply: nil, reply_markup: nil)`
- `send_dice(chat_id:, emoji: nil, disable_notification: nil, reply_to_message_id: nil, allow_sending_without_reply: nil, reply_markup: nil)`

#### Чаты
- `kick_chat_member(chat_id:, user_id:, until_date: nil, revoke_messages: nil)`
- `unban_chat_member(chat_id:, user_id:, only_if_banned: nil)`
- `restrict_chat_member(chat_id:, user_id:, permissions: nil, until_date: nil)`
- `promote_chat_member(chat_id:, user_id:, is_anonymous: nil, can_manage_chat: nil, can_post_messages: nil, can_edit_messages: nil, can_delete_messages: nil, can_manage_video_chats: nil, can_invite_users: nil, can_restrict_members: nil, can_pin_messages: nil, can_manage_topics: nil, can_promote_members: nil)`
- `set_chat_administrator_custom_title(chat_id:, user_id:, custom_title:)`
- `ban_chat_sender_chat(chat_id:, sender_chat_id:)`
- `unban_chat_sender_chat(chat_id:, sender_chat_id:)`
- `set_chat_permissions(chat_id:, permissions:)`
- `export_chat_invite_link(chat_id:)`
- `create_chat_invite_link(chat_id:, name: nil, expire_date: nil, member_limit: nil, creates_join_request: nil)`
- `edit_chat_invite_link(chat_id:, invite_link:, name: nil, expire_date: nil, member_limit: nil, creates_join_request: nil)`
- `revoke_chat_invite_link(chat_id:, invite_link:)`
- `approve_chat_join_request(chat_id:, user_id:)`
- `decline_chat_join_request(chat_id:, user_id:)`
- `set_chat_photo(chat_id:, photo:)`
- `delete_chat_photo(chat_id:)`
- `set_chat_title(chat_id:, title:)`
- `set_chat_description(chat_id:, description: nil)`
- `pin_chat_message(chat_id:, message_id:, disable_notification: nil)`
- `unpin_chat_message(chat_id:, message_id:)`
- `unpin_all_chat_messages(chat_id:)`
- `leave_chat(chat_id:)`
- `get_chat(chat_id:)`
- `get_chat_administrators(chat_id:)`
- `get_chat_member_count(chat_id:)`
- `get_chat_member(chat_id:, user_id:)`
- `set_chat_sticker_set(chat_id:, sticker_set_name:)`
- `delete_chat_sticker_set(chat_id:)`

#### Сообщения (продолжение)
- `forward_message(chat_id:, from_chat_id:, message_id:, disable_notification: nil)`
- `copy_message(chat_id:, from_chat_id:, message_id:, caption: nil, parse_mode: nil, caption_entities: nil, disable_notification: nil, reply_to_message_id: nil, allow_sending_without_reply: nil, reply_markup: nil)`
- `send_sticker(chat_id:, sticker:, disable_notification: nil, reply_to_message_id: nil, allow_sending_without_reply: nil, reply_markup: nil)`

#### Редактирование сообщений
- `edit_message_text(chat_id: nil, message_id: nil, inline_message_id: nil, text:, parse_mode: nil, entities: nil, disable_web_page_preview: nil, reply_markup: nil)`
- `edit_message_caption(chat_id: nil, message_id: nil, inline_message_id: nil, caption: nil, parse_mode: nil, caption_entities: nil, reply_markup: nil)`
- `edit_message_media(chat_id: nil, message_id: nil, inline_message_id: nil, media:, reply_markup: nil)`
- `edit_message_reply_markup(chat_id: nil, message_id: nil, inline_message_id: nil, reply_markup: nil)`
- `stop_poll(chat_id:, message_id:, reply_markup: nil)`
- `delete_message(chat_id:, message_id:)`

#### Инлайн режим
- `answer_inline_query(inline_query_id:, results:, cache_time: nil, is_personal: nil, next_offset: nil, switch_pm_text: nil, switch_pm_parameter: nil)`

#### Callback queries
- `answer_callback_query(callback_query_id:, text: nil, show_alert: nil, url: nil, cache_time: nil)`

#### Stickers
- `send_sticker(chat_id:, sticker:, disable_notification: nil, reply_to_message_id: nil, allow_sending_without_reply: nil, reply_markup: nil)`
- `get_sticker_set(name:)`
- `upload_sticker_file(user_id:, png_sticker:)`
- `create_new_sticker_set(user_id:, name:, title:, stickers:, sticker_format: nil)`
- `add_sticker_to_set(user_id:, name:, sticker:)`
- `set_sticker_position_in_set(sticker:, position:)`
- `delete_sticker_from_set(sticker:)`
- `set_sticker_set_thumb(name:, user_id:, thumb: nil)`

#### Информация
- `get_me`
- `get_user_profile_photos(user_id:, offset: nil, limit: nil)`
- `get_file(file_id:)`

## Типы данных

### Telegram::Bot::Types::Message
Основной объект сообщения с полями:
- `message_id` - Integer
- `from` - Telegram::Bot::Types::User
- `chat` - Telegram::Bot::Types::Chat
- `date` - Integer (timestamp)
- `text` - String (для текстовых сообщений)
- `photo` - Array[Telegram::Bot::Types::PhotoSize]
- `audio` - Telegram::Bot::Types::Audio
- `document` - Telegram::Bot::Types::Document
- `video` - Telegram::Bot::Types::Video
- `animation` - Telegram::Bot::Types::Animation
- `voice` - Telegram::Bot::Types::Voice
- `video_note` - Telegram::Bot::Types::VideoNote
- `caption` - String
- `location` - Telegram::Bot::Types::Location
- `contact` - Telegram::Bot::Types::Contact
- `reply_markup` - Telegram::Bot::Types::InlineKeyboardMarkup | Telegram::Bot::Types::ReplyKeyboardMarkup

### Telegram::Bot::Types::CallbackQuery
Объект для инлайн кнопок:
- `id` - String
- `from` - Telegram::Bot::Types::User
- `message` - Telegram::Bot::Types::Message
- `data` - String

### Telegram::Bot::Types::InlineKeyboardMarkup
```ruby
Telegram::Bot::Types::InlineKeyboardMarkup.new(
  inline_keyboard: [
    [
      Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Button 1', callback_data: 'data1'),
      Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Button 2', callback_data: 'data2')
    ]
  ]
)
```

### Telegram::Bot::Types::ReplyKeyboardMarkup
```ruby
Telegram::Bot::Types::ReplyKeyboardMarkup.new(
  keyboard: [
    ['/start', '/help'],
    ['/settings']
  ],
  resize_keyboard: true,
  one_time_keyboard: false,
  input_field_placeholder: 'Введите команду...',
  selective: false
)
```

## Обработка ошибок

### Telegram::Bot::Exceptions::ResponseError
- `error_code` - Integer (код ошибки API)
- `description` - String (описание ошибки)
- `parameters` - Hash (дополнительные параметры)

### Частые коды ошибок
- 400 Bad Request - неверные параметры запроса
- 401 Unauthorized - неверный токен
- 403 Forbidden - бот заблокирован пользователем
- 404 Not Found - чат/пользователь не найден
- 429 Too Many Requests - превышен лимит запросов
- 500 Internal Server Error - ошибка на сервере Telegram

## Конфигурация клиента

```ruby
client = Telegram::Bot::Client.new(token, {
  open_timeout: 5,
  read_timeout: 5,
  write_timeout: 5,
  proxy: {
    uri: 'http://proxy.example.com:8080',
    user: 'user',
    password: 'pass'
  }
})
```