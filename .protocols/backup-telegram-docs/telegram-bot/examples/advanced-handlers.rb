#!/usr/bin/env ruby

require 'telegram/bot'
require 'json'
require 'fileutils'

# Продвинутый пример Telegram бота с обработкой файлов, состояний, и сложной логикой
class AdvancedBot
  def initialize(token)
    @bot = Telegram::Bot::Client.new(token)
    @user_states = {}
    @user_data = {}
    @data_dir = File.join(__dir__, '..', 'data')
    FileUtils.mkdir_p(@data_dir)
    load_user_data
  end

  def start
    puts "Starting advanced bot with file handling and state management..."

    @bot.listen do |message|
      begin
        handle_message(message)
        save_user_data
      rescue => e
        puts "Error handling message: #{e.message}"
        puts e.backtrace.first(5)
        send_error_message(message.chat.id)
      end
    end
  end

  private

  def handle_message(message)
    user_id = message.from.id
    init_user_data(user_id)

    case message
    when Telegram::Bot::Types::CallbackQuery
      handle_callback_query(message)
    when Telegram::Bot::Types::Message
      handle_regular_message(message)
    end
  end

  def handle_regular_message(message)
    user_id = message.from.id
    state = @user_states[user_id]

    case state[:state]
    when :waiting_for_name
      handle_name_input(message, user_id)
    when :waiting_for_age
      handle_age_input(message, user_id)
    when :waiting_for_file
      handle_file_input(message, user_id)
    when :waiting_for_location
      handle_location_input(message, user_id)
    else
      handle_command_message(message)
    end
  end

  def handle_command_message(message)
    user_id = message.from.id

    case message.text
    when '/start'
      handle_start(message)
    when '/register'
      start_registration(message, user_id)
    when '/profile'
      show_profile(message, user_id)
    when '/upload'
      request_file_upload(message, user_id)
    when '/location'
      request_location(message, user_id)
    when '/gallery'
      show_gallery(message, user_id)
    when '/cancel'
      cancel_current_action(message, user_id)
    when '/stats'
      show_statistics(message)
    else
      handle_text_input(message, user_id)
    end
  end

  def handle_start(message)
    inline_keyboard = Telegram::Bot::Types::InlineKeyboardMarkup.new(
      inline_keyboard: [
        [
          Telegram::Bot::Types::InlineKeyboardButton.new(
            text: '📝 Зарегистрироваться',
            callback_data: 'register'
          ),
          Telegram::Bot::Types::InlineKeyboardButton.new(
            text: '👤 Профиль',
            callback_data: 'profile'
          )
        ],
        [
          Telegram::Bot::Types::InlineKeyboardButton.new(
            text: '📁 Загрузить файл',
            callback_data: 'upload'
          ),
          Telegram::Bot::Types::InlineKeyboardButton.new(
            text: '📍 Отправить локацию',
            callback_data: 'location'
          )
        ]
      ]
    )

    @bot.api.send_message(
      chat_id: message.chat.id,
      text: "🤖 Добро пожаловать в продвинутого бота!\n\n" \
            "Доступные функции:\n" \
            "• Регистрация пользователя\n" \
            "• Загрузка и хранение файлов\n" \
            "• Отправка геолокации\n" \
            "• Просмотр галереи\n" \
            "• Статистика использования\n\n" \
            "Выберите действие:",
      reply_markup: inline_keyboard
    )
  end

  def start_registration(message, user_id)
    @user_states[user_id][:state] = :waiting_for_name
    @user_states[user_id][:registration_data] = {}

    @bot.api.send_message(
      chat_id: message.chat.id,
      text: "📝 Начинаем регистрацию!\n\n" \
            "Шаг 1: Введите ваше имя:"
    )
  end

  def handle_name_input(message, user_id)
    name = message.text.strip
    if name.length < 2
      @bot.api.send_message(
        chat_id: message.chat.id,
        text: "❌ Слишком короткое имя. Попробуйте еще раз:"
      )
      return
    end

    @user_states[user_id][:registration_data][:name] = name
    @user_states[user_id][:state] = :waiting_for_age

    @bot.api.send_message(
      chat_id: message.chat.id,
      text: "✅ Имя сохранено: #{name}\n\n" \
            "Шаг 2: Введите ваш возраст (цифрами):"
    )
  end

  def handle_age_input(message, user_id)
    age = message.text.strip.to_i
    if age < 1 || age > 120
      @bot.api.send_message(
        chat_id: message.chat.id,
        text: "❌ Некорректный возраст. Введите число от 1 до 120:"
      )
      return
    end

    @user_states[user_id][:registration_data][:age] = age
    complete_registration(message, user_id)
  end

  def complete_registration(message, user_id)
    registration_data = @user_states[user_id][:registration_data]
    @user_data[user_id].merge!(registration_data)
    @user_states[user_id][:state] = :idle

    @bot.api.send_message(
      chat_id: message.chat.id,
      text: "🎉 Регистрация завершена!\n\n" \
            "📋 Ваш профиль:\n" \
            "Имя: #{@user_data[user_id][:name]}\n" \
            "Возраст: #{@user_data[user_id][:age]}\n" \
            "ID: #{user_id}\n\n" \
            "Используйте /profile для просмотра полного профиля."
    )
  end

  def show_profile(message, user_id)
    user_profile = @user_data[user_id]

    if user_profile.empty?
      @bot.api.send_message(
        chat_id: message.chat.id,
        text: "📝 Профиль не найден. Используйте /register для регистрации."
      )
      return
    end

    profile_text = "👤 **Ваш профиль:**\n\n"
    profile_text += "🆔 ID: #{user_id}\n"
    profile_text += "👤 Имя: #{user_profile[:name]}\n" if user_profile[:name]
    profile_text += "🎂 Возраст: #{user_profile[:age]}\n" if user_profile[:age]
    profile_text += "📁 Загруженных файлов: #{user_profile[:files]&.size || 0}\n"
    profile_text += "📍 Локаций: #{user_profile[:locations]&.size || 0}\n"
    profile_text += "📊 Сообщений: #{user_profile[:message_count] || 0}"

    if user_profile[:last_location]
      loc = user_profile[:last_location]
      profile_text += "\n\n📍 Последняя локация: #{loc[:latitude]}, #{loc[:longitude]}"
    end

    @bot.api.send_message(
      chat_id: message.chat.id,
      text: profile_text,
      parse_mode: 'Markdown'
    )
  end

  def request_file_upload(message, user_id)
    @user_states[user_id][:state] = :waiting_for_file

    @bot.api.send_message(
      chat_id: message.chat.id,
      text: "📁 Пожалуйста, отправьте файл (документ, фото, видео или аудио).\n\n" \
            "Поддерживаемые форматы:\n" \
            "• Документы (PDF, DOC, TXT и др.)\n" \
            "• Фотографии (JPG, PNG, GIF)\n" \
            "• Видео (MP4, AVI)\n" \
            "• Аудио (MP3, WAV)\n\n" \
            "Используйте /cancel для отмены."
    )
  end

  def handle_file_input(message, user_id)
    file_info = nil
    file_type = nil
    caption = message.caption

    if message.photo
      file_info = message.photo.last
      file_type = 'photo'
    elsif message.document
      file_info = message.document
      file_type = 'document'
    elsif message.video
      file_info = message.video
      file_type = 'video'
    elsif message.audio
      file_info = message.audio
      file_type = 'audio'
    elsif message.voice
      file_info = message.voice
      file_type = 'voice'
    else
      @bot.api.send_message(
        chat_id: message.chat.id,
        text: "❌ Файл не распознан. Попробуйте другой файл."
      )
      return
    end

    begin
      # Сохраняем информацию о файле
      file_record = {
        file_id: file_info.file_id,
        file_name: file_info.file_name || "file_#{Time.now.to_i}",
        file_size: file_info.file_size,
        file_type: file_type,
        caption: caption,
        uploaded_at: Time.now.iso8601
      }

      @user_data[user_id][:files] ||= []
      @user_data[user_id][:files] << file_record

      # Скачиваем файл (опционально)
      download_file(file_info, user_id) if should_download_file?(file_info)

      @user_states[user_id][:state] = :idle

      @bot.api.send_message(
        chat_id: message.chat.id,
        text: "✅ Файл успешно загружен!\n\n" \
              "📁 Информация:\n" \
              "Тип: #{file_type}\n" \
              "Имя: #{file_record[:file_name]}\n" \
              "Размер: #{format_file_size(file_info.file_size)}\n" \
              "Всего файлов: #{@user_data[user_id][:files].size}"
      )
    rescue => e
      @bot.api.send_message(
        chat_id: message.chat.id,
        text: "❌ Ошибка при обработке файла: #{e.message}"
      )
    end
  end

  def request_location(message, user_id)
    @user_states[user_id][:state] = :waiting_for_location

    location_keyboard = Telegram::Bot::Types::ReplyKeyboardMarkup.new(
      keyboard: [
        [Telegram::Bot::Types::KeyboardButton.new(text: '📍 Отправить локацию', request_location: true)]
      ],
      resize_keyboard: true,
      one_time_keyboard: true
    )

    @bot.api.send_message(
      chat_id: message.chat.id,
      text: "📍 Пожалуйста, отправьте вашу геолокацию.\n\n" \
            "Нажмите кнопку ниже или прикрепите локацию к сообщению.\n\n" \
            "Используйте /cancel для отмены.",
      reply_markup: location_keyboard
    )
  end

  def handle_location_input(message, user_id)
    unless message.location
      @bot.api.send_message(
        chat_id: message.chat.id,
        text: "❌ Локация не найдена. Попробуйте еще раз."
      )
      return
    end

    location = message.location
    location_record = {
      latitude: location.latitude,
      longitude: location.longitude,
      timestamp: Time.now.iso8601
    }

    @user_data[user_id][:locations] ||= []
    @user_data[user_id][:locations] << location_record
    @user_data[user_id][:last_location] = location_record
    @user_states[user_id][:state] = :idle

    # Убираем клавиатуру локации
    hide_keyboard = Telegram::Bot::Types::ReplyKeyboardRemove.new

    @bot.api.send_message(
      chat_id: message.chat.id,
      text: "✅ Локация сохранена!\n\n" \
            "📍 Координаты: #{location.latitude}, #{location.longitude}\n" \
            "[Показать на карте](https://www.google.com/maps?q=#{location.latitude},#{location.longitude})\n\n" \
            "Всего локаций: #{@user_data[user_id][:locations].size}",
      parse_mode: 'Markdown',
      reply_markup: hide_keyboard
    )
  end

  def show_gallery(message, user_id)
    files = @user_data[user_id][:files] || []

    if files.empty?
      @bot.api.send_message(
        chat_id: message.chat.id,
        text: "📁 У вас нет загруженных файлов.\n\n" \
              "Используйте /upload для загрузки файлов."
      )
      return
    end

    # Создаем инлайн клавиатуру с файлами
    keyboard_buttons = files.map.with_index do |file, index|
      Telegram::Bot::Types::InlineKeyboardButton.new(
        text: "#{index + 1}. #{file[:file_name]} (#{file[:file_type]})",
        callback_data: "file_#{index}"
      )
    end

    # Разбиваем на группы по 2 кнопки в ряду
    keyboard_rows = keyboard_buttons.each_slice(2).to_a

    inline_keyboard = Telegram::Bot::Types::InlineKeyboardMarkup.new(
      inline_keyboard: keyboard_rows
    )

    @bot.api.send_message(
      chat_id: message.chat.id,
      text: "📁 Ваша галерея (#{files.size} файлов):\n\n" \
            "Выберите файл для просмотра:",
      reply_markup: inline_keyboard
    )
  end

  def cancel_current_action(message, user_id)
    @user_states[user_id][:state] = :idle
    hide_keyboard = Telegram::Bot::Types::ReplyKeyboardRemove.new

    @bot.api.send_message(
      chat_id: message.chat.id,
      text: "❌ Действие отменено.",
      reply_markup: hide_keyboard
    )
  end

  def show_statistics(message)
    total_users = @user_data.size
    total_files = @user_data.values.sum { |data| data[:files]&.size || 0 }
    total_locations = @user_data.values.sum { |data| data[:locations]&.size || 0 }
    total_messages = @user_data.values.sum { |data| data[:message_count] || 0 }

    stats_text = "📊 **Статистика бота:**\n\n"
    stats_text += "👥 Всего пользователей: #{total_users}\n"
    stats_text += "📁 Всего файлов: #{total_files}\n"
    stats_text += "📍 Всего локаций: #{total_locations}\n"
    stats_text += "💬 Всего сообщений: #{total_messages}\n"
    stats_text += "⏰ Время работы: #{format_uptime(Time.now - @start_time)}"

    @bot.api.send_message(
      chat_id: message.chat.id,
      text: stats_text,
      parse_mode: 'Markdown'
    )
  end

  def handle_callback_query(callback_query)
    user_id = callback_query.from.id
    data = callback_query.data

    case data
    when 'register'
      start_registration(callback_query.message, user_id)
    when 'profile'
      show_profile(callback_query.message, user_id)
    when 'upload'
      request_file_upload(callback_query.message, user_id)
    when 'location'
      request_location(callback_query.message, user_id)
    when /^file_(\d+)$/
      file_index = $1.to_i
      show_file_details(callback_query.message, user_id, file_index)
    end

    @bot.api.answer_callback_query(callback_query_id: callback_query.id)
  end

  def show_file_details(message, user_id, file_index)
    files = @user_data[user_id][:files] || []
    return if file_index >= files.size

    file = files[file_index]

    details_text = "📁 **Детали файла:**\n\n"
    details_text += "📄 Имя: #{file[:file_name]}\n"
    details_text += "🏷️ Тип: #{file[:file_type]}\n"
    details_text += "📏 Размер: #{format_file_size(file[:file_size])}\n"
    details_text += "📝 Описание: #{file[:caption] || 'Нет'}\n"
    details_text += "📅 Загружен: #{format_time(file[:uploaded_at])}"

    @bot.api.send_message(
      chat_id: message.chat.id,
      text: details_text,
      parse_mode: 'Markdown'
    )
  end

  def handle_text_input(message, user_id)
    @user_data[user_id][:message_count] = (@user_data[user_id][:message_count] || 0) + 1

    # Простая логика ответов
    case message.text.downcase
    when 'привет', 'здравствуй'
      @bot.api.send_message(
        chat_id: message.chat.id,
        text: "👋 Привет! Используйте /start для меню команд."
      )
    when 'помощь', 'help'
      @bot.api.send_message(
        chat_id: message.chat.id,
        text: "🆘 **Доступные команды:**\n\n" \
              "/start - главное меню\n" \
              "/register - регистрация\n" \
              "/profile - профиль\n" \
              "/upload - загрузить файл\n" \
              "/location - отправить локацию\n" \
              "/gallery - галерея файлов\n" \
              "/stats - статистика\n" \
              "/cancel - отменить действие",
        parse_mode: 'Markdown'
      )
    else
      @bot.api.send_message(
        chat_id: message.chat.id,
        text: "🤔 Я не понял команду. Используйте /help для справки."
      )
    end
  end

  def init_user_data(user_id)
    @user_states[user_id] ||= { state: :idle }
    @user_data[user_id] ||= {
      message_count: 0,
      files: [],
      locations: []
    }
  end

  def should_download_file?(file_info)
    # Скачиваем только файлы меньше 5MB
    file_info.file_size && file_info.file_size < 5 * 1024 * 1024
  end

  def download_file(file_info, user_id)
    begin
      file = @bot.api.get_file(file_id: file_info.file_id)
      file_url = "https://api.telegram.org/file/bot#{ENV['TELEGRAM_BOT_TOKEN']}/#{file.file_path}"

      # Создаем директорию для пользователя
      user_dir = File.join(@data_dir, "user_#{user_id}")
      FileUtils.mkdir_p(user_dir)

      # Скачиваем файл
      require 'open-uri'
      file_path = File.join(user_dir, file_info.file_name || "file_#{file_info.file_id}")
      File.open(file_path, 'wb') { |f| f.write(open(file_url).read) }

      puts "File downloaded: #{file_path}"
    rescue => e
      puts "Error downloading file: #{e.message}"
    end
  end

  def save_user_data
    File.write(File.join(@data_dir, 'user_data.json'), @user_data.to_json)
  end

  def load_user_data
    data_file = File.join(@data_dir, 'user_data.json')
    if File.exist?(data_file)
      @user_data = JSON.parse(File.read(data_file), symbolize_names: true)
    end
    @start_time = Time.now
  end

  def format_file_size(bytes)
    return '0 B' if bytes.nil? || bytes.zero?

    units = %w[B KB MB GB]
    size = bytes.to_f
    unit_index = 0

    while size >= 1024 && unit_index < units.length - 1
      size /= 1024
      unit_index += 1
    end

    "#{size.round(2)} #{units[unit_index]}"
  end

  def format_time(iso_time)
    Time.parse(iso_time).strftime('%d.%m.%Y %H:%M:%S')
  rescue
    'Неизвестно'
  end

  def format_uptime(seconds)
    hours = (seconds / 3600).to_i
    minutes = ((seconds % 3600) / 60).to_i
    "#{hours}ч #{minutes}м"
  end

  def send_error_message(chat_id)
    @bot.api.send_message(
      chat_id: chat_id,
      text: "❌ Произошла ошибка. Попробуйте еще раз позже."
    )
  rescue
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

  bot = AdvancedBot.new(token)
  bot.start
end