#!/usr/bin/env ruby

require 'ruby_llm'
require 'dotenv/load'

# Базовый пример использования Ruby LLM для создания чат-бота
class BasicChatBot
  def initialize(model = 'gpt-3.5-turbo')
    configure_llm
    @model = model
    @chats = {}  # Хранение чатов по ID пользователей
  end

  def start
    puts "🤖 Ruby LLM Chat Bot запущен!"
    puts "Модель: #{@model}"
    puts "Команды: /new, /model, /help, /exit"
    puts "-" * 50

    loop do
      print "> "
      input = gets.chomp

      case input
      when '/exit'
        puts "👋 До свидания!"
        break
      when '/help'
        show_help
      when '/new'
        start_new_chat
      when '/model'
        change_model
      when empty?
        next
      else
        process_message(input)
      end
    end
  end

  private

  def configure_llm
    RubyLLM.configure do |config|
      config.use_new_acts_as = true
      config.request_timeout = 120
      config.max_retries = 2

      # API ключи (загружаются из .env файла)
      config.openai_api_key = ENV['OPENAI_API_KEY']
      config.anthropic_api_key = ENV['ANTHROPIC_API_KEY']
      config.gemini_api_key = ENV['GEMINI_API_KEY']
      config.deepseek_api_key = ENV['DEEPSEEK_API_KEY']
      config.openrouter_api_key = ENV['OPENROUTER_API_KEY']
      config.mistral_api_key = ENV['MISTRAL_API_KEY']

      config.default_model = 'gpt-3.5-turbo'
      config.default_embedding_model = 'text-embedding-3-large'
      config.default_image_model = 'dall-e-3'
    end
  end

  def current_chat
    @current_chat ||= create_new_chat
  end

  def create_new_chat(system_prompt = nil)
    chat = RubyLLM.chat.new(
      model: @model,
      system: system_prompt || "Ты - дружелюбный и полезный ассистент, который общается на русском языке. Отвечай кратко и по делу."
    )

    @chats[chat.object_id] = chat
    @current_chat = chat
    chat
  end

  def process_message(message)
    begin
      print "🤔 Думаю... "

      # Отправляем сообщение и получаем ответ
      response = current_chat.say(message)

      puts "\n🤖 #{response.content}"

      # Показываем информацию об использовании токенов
      if response.usage
        tokens = response.usage[:total_tokens]
        puts "💰 Использовано токенов: #{tokens}"
      end

      puts
    rescue RubyLLM::AuthenticationError => e
      puts "\n❌ Ошибка аутентификации: #{e.message}"
      puts "Проверьте настройки API ключей в .env файле"
    rescue RubyLLM::RateLimitError => e
      puts "\n⏰ Превышен лимит запросов. Повторите через #{e.retry_after} секунд"
      sleep(e.retry_after || 5)
      retry
    rescue RubyLLM::InvalidRequestError => e
      puts "\n❌ Некорректный запрос: #{e.message}"
    rescue RubyLLM::APIError => e
      puts "\n❌ Ошибка API: #{e.message}"
    rescue => e
      puts "\n❌ Неизвестная ошибка: #{e.message}"
      puts e.backtrace.first(3) if ENV['DEBUG']
    end
  end

  def start_new_chat
    puts "🆕 Создание нового чата..."
    create_new_chat
    puts "✅ Новый чат создан"
  end

  def change_model
    puts "📋 Доступные модели:"
    models = list_available_models
    models.each_with_index do |model, index|
      puts "#{index + 1}. #{model[:name]} (#{model[:provider]})"
    end

    print "Выберите модель (1-#{models.size}): "
    choice = gets.chomp.to_i

    if choice.between?(1, models.size)
      @model = models[choice - 1][:id]
      create_new_chat
      puts "✅ Модель изменена на: #{models[choice - 1][:name]}"
    else
      puts "❌ Некорректный выбор"
    end
  end

  def list_available_models
    # Популярные модели для примера
    [
      { id: 'gpt-3.5-turbo', name: 'GPT-3.5 Turbo', provider: 'OpenAI' },
      { id: 'gpt-4', name: 'GPT-4', provider: 'OpenAI' },
      { id: 'claude-sonnet-4', name: 'Claude Sonnet 4', provider: 'Anthropic' },
      { id: 'claude-haiku-3.5', name: 'Claude Haiku 3.5', provider: 'Anthropic' },
      { id: 'gemini-pro', name: 'Gemini Pro', provider: 'Google' },
      { id: 'deepseek-chat', name: 'DeepSeek Chat', provider: 'DeepSeek' }
    ]
  end

  def show_help
    puts <<~HELP
      📖 **Справка по командам:**

      /new - Создать новый чат
      /model - Изменить модель
      /help - Показать эту справку
      /exit - Выйти из программы

      💡 **Советы:**
      • Начните новое общение с помощью /new
      • Меняйте модели для разных задач
      • GPT-4 лучше для сложных задач
      • Claude хорошо понимает русский язык
      • Gemini и DeepSeek - бюджетные альтернативы
    HELP
  end
end

# Класс для демонстрации различных сценариев использования
class ChatScenarios
  def self.run_all_scenarios
    puts "🎯 Демонстрация различных сценариев использования Ruby LLM"
    puts "=" * 60

    configure_llm

    # Сценарий 1: Простая генерация текста
    demonstrate_text_generation

    # Сценарий 2: Генерация кода
    demonstrate_code_generation

    # Сценарий 3: Перевод текста
    demonstrate_translation

    # Сценарий 4: Анализ текста
    demonstrate_text_analysis

    # Сценарий 5: Создание эмбеддингов
    demonstrate_embeddings
  end

  private

  def self.configure_llm
    RubyLLM.configure do |config|
      config.openai_api_key = ENV['OPENAI_API_KEY']
      config.anthropic_api_key = ENV['ANTHROPIC_API_KEY']
      config.default_model = 'gpt-3.5-turbo'
    end
  end

  def self.demonstrate_text_generation
    puts "\n📝 Сценарий 1: Генерация текста"
    puts "-" * 30

    chat = RubyLLM.chat.new(
      system: "Ты - креативный писатель. Пиши краткие и интересные тексты."
    )

    prompt = "Напиши короткое стихотворение о программировании"

    print "🤔 Запрос: #{prompt}\n"
    print "🤖 Ответ: "

    response = chat.say(prompt)
    puts response.content
    puts "💰 Токенов использовано: #{response.usage[:total_tokens]}" if response.usage
  end

  def self.demonstrate_code_generation
    puts "\n💻 Сценарий 2: Генерация кода"
    puts "-" * 30

    chat = RubyLLM.chat.new(
      system: "Ты - опытный Ruby разработчик. Пиши чистый и эффективный код."
    )

    prompt = "Напиши Ruby метод для проверки, является ли число простым"

    print "🤔 Запрос: #{prompt}\n"
    print "🤖 Ответ:\n"

    response = chat.say(prompt)
    puts response.content
    puts "💰 Токенов использовано: #{response.usage[:total_tokens]}" if response.usage
  end

  def self.demonstrate_translation
    puts "\n🌍 Сценарий 3: Перевод текста"
    puts "-" * 30

    chat = RubyLLM.chat.new(
      system: "Ты - профессиональный переводчик. Переводи точно и естественно."
    )

    prompt = "Переведи на английский: 'Привет, как дела? Я сегодня отлично себя чувствую!'"

    print "🤔 Запрос: #{prompt}\n"
    print "🤖 Ответ: "

    response = chat.say(prompt)
    puts response.content
    puts "💰 Токенов использовано: #{response.usage[:total_tokens]}" if response.usage
  end

  def self.demonstrate_text_analysis
    puts "\n🔍 Сценарий 4: Анализ текста"
    puts "-" * 30

    chat = RubyLLM.chat.new(
      system: "Ты - аналитик текста. Проводи краткий и точный анализ."
    )

    text = "Ruby - это динамический, объектно-ориентированный язык программирования, известный своей простотой и элегантностью."
    prompt = "Проанализируй этот текст: определи тональность, основные темы и ключевые слова. Текст: #{text}"

    print "🤔 Запрос: #{prompt}\n"
    print "🤖 Ответ: "

    response = chat.say(prompt)
    puts response.content
    puts "💰 Токенов использовано: #{response.usage[:total_tokens]}" if response.usage
  end

  def self.demonstrate_embeddings
    puts "\n🔢 Сценарий 5: Создание эмбеддингов"
    puts "-" * 30

    texts = [
      "Программирование на Ruby",
      "Веб-разработка с Rails",
      "Кулинарные рецепты",
      "Спортивные новости"
    ]

    print "🤔 Создаю эмбеддинги для текстов...\n"

    texts.each_with_index do |text, index|
      begin
        embedding = RubyLLM.embed(text, model: 'text-embedding-3-large')
        puts "✅ Текст #{index + 1}: #{text}"
        puts "   Размерность вектора: #{embedding.vector.length}"
        puts "   Первые 5 значений: #{embedding.vector.first(5).map { |v| v.round(4) }}"
        puts
      rescue => e
        puts "❌ Ошибка при создании эмбеддинга для '#{text}': #{e.message}"
      end
    end
  end
end

# Запуск примера
if __FILE__ == $0
  if ARGV.include?('--demo')
    # Запуск демонстрации сценариев
    ChatScenarios.run_all_scenarios
  else
    # Запуск интерактивного чата
    bot = BasicChatBot.new
    bot.start
  end
end