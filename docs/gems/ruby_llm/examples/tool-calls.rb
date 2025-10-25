#!/usr/bin/env ruby

require 'ruby_llm'
require 'json'
require 'net/http'
require 'uri'
require 'dotenv/load'

# Продвинутый пример использования Ruby LLM с инструментами (function calling)
class ToolCallingBot
  def initialize(model = 'gpt-4')
    configure_llm
    @model = model
    @tools = define_tools
    @chat = create_chat_with_tools
  end

  def start
    puts "🤖 Tool Calling Bot запущен!"
    puts "Модель: #{@model}"
    puts "Доступные инструменты: #{@tools.map { |t| t[:name] }.join(', ')}"
    puts "Команды: /help, /exit"
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
      when '/tools'
        show_available_tools
      when empty?
        next
      else
        process_message_with_tools(input)
      end
    end
  end

  private

  def configure_llm
    RubyLLM.configure do |config|
      config.use_new_acts_as = true
      config.request_timeout = 120
      config.max_retries = 2
      config.openai_api_key = ENV['OPENAI_API_KEY']
      config.anthropic_api_key = ENV['ANTHROPIC_API_KEY']
      config.default_model = @model
    end
  end

  def define_tools
    [
      {
        name: 'get_weather',
        description: 'Получает текущую погоду для указанного города',
        parameters: {
          type: 'object',
          properties: {
            city: {
              type: 'string',
              description: 'Название города на русском или английском языке'
            },
            units: {
              type: 'string',
              enum: ['celsius', 'fahrenheit'],
              description: 'Единицы измерения температуры',
              default: 'celsius'
            }
          },
          required: ['city']
        }
      },
      {
        name: 'calculate',
        description: 'Выполняет математические вычисления',
        parameters: {
          type: 'object',
          properties: {
            expression: {
              type: 'string',
              description: 'Математическое выражение для вычисления (например: "2 + 2 * 3")'
            }
          },
          required: ['expression']
        }
      },
      {
        name: 'search_web',
        description: 'Выполняет поиск в интернете (симуляция)',
        parameters: {
          type: 'object',
          properties: {
            query: {
              type: 'string',
              description: 'Поисковый запрос'
            },
            num_results: {
              type: 'integer',
              description: 'Количество результатов',
              default: 5
            }
          },
          required: ['query']
        }
      },
      {
        name: 'get_current_time',
        description: 'Получает текущее время для указанного города',
        parameters: {
          type: 'object',
          properties: {
            city: {
              type: 'string',
              description: 'Название города (например: "Москва", "New York")'
            },
            timezone: {
              type: 'string',
              description: 'Часовой пояс (например: "Europe/Moscow", "America/New_York")'
            }
          },
          required: []
        }
      },
      {
        name: 'translate_text',
        description: 'Переводит текст с одного языка на другой',
        parameters: {
          type: 'object',
          properties: {
            text: {
              type: 'string',
              description: 'Текст для перевода'
            },
            from_lang: {
              type: 'string',
              description: 'Исходный язык (например: "ru", "en")'
            },
            to_lang: {
              type: 'string',
              description: 'Целевой язык (например: "en", "ru")'
            }
          },
          required: ['text', 'to_lang']
        }
      }
    ]
  end

  def create_chat_with_tools
    RubyLLM.chat.new(
      model: @model,
      system: "Ты - умный ассистент с доступом к различным инструментам. " \
              "Используй инструменты, когда это необходимо для ответа на вопросы пользователя. " \
              "Отвечай на русском языке, если не указано иное.",
      tools: @tools
    )
  end

  def process_message_with_tools(message)
    begin
      print "🤔 Анализирую запрос... "

      response = @chat.say(message)
      puts "\n"

      # Если модель вызвала инструменты
      if response.tool_calls.any?
        handle_tool_calls(response)
      else
        puts "🤖 #{response.content}"
      end

      # Показываем информацию об использовании токенов
      if response.usage
        tokens = response.usage[:total_tokens]
        puts "💰 Использовано токенов: #{tokens}"
      end

      puts
    rescue RubyLLM::AuthenticationError => e
      puts "\n❌ Ошибка аутентификации: #{e.message}"
    rescue RubyLLM::RateLimitError => e
      puts "\n⏰ Превышен лимит запросов. Повторите через #{e.retry_after} секунд"
      sleep(e.retry_after || 5)
      retry
    rescue => e
      puts "\n❌ Ошибка: #{e.message}"
    end
  end

  def handle_tool_calls(response)
    puts "🔧 Вызываются инструменты: #{response.tool_calls.map(&:name).join(', ')}"
    puts

    response.tool_calls.each do |tool_call|
      handle_single_tool_call(tool_call)
    end
  end

  def handle_single_tool_call(tool_call)
    tool_name = tool_call.name
    arguments = JSON.parse(tool_call.arguments)

    puts "🔧 Инструмент: #{tool_name}"
    puts "📋 Аргументы: #{arguments}"
    print "⚡ Выполняю... "

    begin
      result = execute_tool(tool_name, arguments)
      puts "✅ Готово"
      puts "📊 Результат: #{result}"

      # Отправляем результат обратно в чат
      tool_response = @chat.say(
        tool_result: {
          tool_call_id: tool_call.id,
          result: result
        }
      )

      puts "🤖 #{tool_response.content}"
    rescue => e
      puts "❌ Ошибка: #{e.message}"

      # Отправляем информацию об ошибке
      @chat.say(
        tool_result: {
          tool_call_id: tool_call.id,
          error: e.message
        }
      )
    end

    puts
  end

  def execute_tool(tool_name, arguments)
    case tool_name
    when 'get_weather'
      get_weather(arguments['city'], arguments['units'])
    when 'calculate'
      calculate_expression(arguments['expression'])
    when 'search_web'
      search_web(arguments['query'], arguments['num_results'])
    when 'get_current_time'
      get_current_time(arguments['city'], arguments['timezone'])
    when 'translate_text'
      translate_text(arguments['text'], arguments['from_lang'], arguments['to_lang'])
    else
      raise "Неизвестный инструмент: #{tool_name}"
    end
  end

  def get_weather(city, units = 'celsius')
    # Симуляция API погоды
    weather_data = {
      'Москва' => { temp: 15, condition: 'Облачно', humidity: 65 },
      'Санкт-Петербург' => { temp: 12, condition: 'Дождь', humidity: 80 },
      'Новосибирск' => { temp: 8, condition: 'Солнечно', humidity: 45 },
      'London' => { temp: 18, condition: 'Туманно', humidity: 70 },
      'New York' => { temp: 22, condition: 'Ясно', humidity: 55 },
      'Tokyo' => { temp: 25, condition: 'Облачно', humidity: 60 }
    }

    data = weather_data[city] || { temp: 20, condition: 'Ясно', humidity: 50 }
    temp = units == 'fahrenheit' ? (data[:temp] * 9/5 + 32).round(1) : data[:temp]
    unit = units == 'fahrenheit' ? '°F' : '°C'

    "В городе #{city}: #{temp}#{unit}, #{data[:condition]}, влажность #{data[:humidity]}%"
  end

  def calculate_expression(expression)
    # Безопасное вычисление математических выражений
    # Разрешаем только базовые операции и числа
    unless expression.match(/^[\d\+\-\*\/\(\)\s\.]+$/)
      raise "Недопустимое математическое выражение"
    end

    begin
      # Используем eval с ограниченным контекстом
      result = eval(expression)
      "Результат: #{expression} = #{result}"
    rescue ZeroDivisionError
      "Ошибка: деление на ноль"
    rescue => e
      "Ошибка вычисления: #{e.message}"
    end
  end

  def search_web(query, num_results = 5)
    # Симуляция веб-поиска
    mock_results = [
      { title: "Результат 1: #{query}", url: "https://example.com/1", snippet: "Описание первого результата..." },
      { title: "Результат 2: #{query}", url: "https://example.com/2", snippet: "Описание второго результата..." },
      { title: "Результат 3: #{query}", url: "https://example.com/3", snippet: "Описание третьего результата..." },
      { title: "Результат 4: #{query}", url: "https://example.com/4", snippet: "Описание четвертого результата..." },
      { title: "Результат 5: #{query}", url: "https://example.com/5", snippet: "Описание пятого результата..." }
    ]

    results = mock_results.first(num_results)
    formatted_results = results.map.with_index do |result, index|
      "#{index + 1}. #{result[:title]}\n   #{result[:snippet]}\n   #{result[:url]}"
    end

    "Результаты поиска по запросу '#{query}':\n\n#{formatted_results.join("\n\n")}"
  end

  def get_current_time(city = nil, timezone = nil)
    # Получение текущего времени
    now = Time.now

    # Простая база данных часовых поясов
    timezones = {
      'Москва' => 'Europe/Moscow',
      'Санкт-Петербург' => 'Europe/Moscow',
      'New York' => 'America/New_York',
      'London' => 'Europe/London',
      'Tokyo' => 'Asia/Tokyo',
      'Paris' => 'Europe/Paris',
      'Berlin' => 'Europe/Berlin'
    }

    # Определяем часовой пояс
    tz = timezone || timezones[city] || 'UTC'

    begin
      # В реальном приложении здесь была бы работа с часовыми поясами
      city_name = city || tz
      "Текущее время в #{city_name}: #{now.strftime('%H:%M:%S')} (#{now.strftime('%d.%m.%Y')})"
    rescue => e
      "Не удалось получить время для #{city_name}: #{e.message}"
    end
  end

  def translate_text(text, from_lang = nil, to_lang)
    # Симуляция перевода (в реальном приложении здесь был бы API вызов)
    translations = {
      'ru' => {
        'en' => {
          'Привет, мир!' => 'Hello, world!',
          'Как дела?' => 'How are you?',
          'Спасибо' => 'Thank you',
          'Доброе утро' => 'Good morning'
        }
      },
      'en' => {
        'ru' => {
          'Hello, world!' => 'Привет, мир!',
          'How are you?' => 'Как дела?',
          'Thank you' => 'Спасибо',
          'Good morning' => 'Доброе утро'
        }
      }
    }

    # Определяем исходный язык, если не указан
    if from_lang.nil?
      from_lang = text.match(/[а-я]/i) ? 'ru' : 'en'
    end

    # Ищем перевод в нашей базе
    translation = translations.dig(from_lang, to_lang, text)

    if translation
      "Перевод с #{from_lang} на #{to_lang}:\n\nОригинал: #{text}\nПеревод: #{translation}"
    else
      "Перевод с #{from_lang} на #{to_lang}:\n\nОригинал: #{text}\nПеревод: [Симуляция перевода] #{text} (переведено на #{to_lang})"
    end
  end

  def show_help
    puts <<~HELP
      📖 **Справка по инструментам:**

      Доступные инструменты:
      • get_weather - Получение погоды для города
      • calculate - Математические вычисления
      • search_web - Поиск в интернете
      • get_current_time - Получение времени для города
      • translate_text - Перевод текста

      Примеры запросов:
      • "Какая погода в Москве?"
      • "Посчитай 15 * 8 + 32"
      • "Найди информацию о Ruby программировании"
      • "Который час в Токио?"
      • "Переведи 'Hello world' на русский"

      Команды:
      /help - Показать эту справку
      /tools - Показать доступные инструменты
      /exit - Выйти из программы
    HELP
  end

  def show_available_tools
    puts "🔧 Доступные инструменты:"
    @tools.each do |tool|
      puts "\n📋 #{tool[:name]}"
      puts "   #{tool[:description]}"
      if tool[:parameters][:properties]
        tool[:parameters][:properties].each do |param_name, param_info|
          required = tool[:parameters][:required]&.include?(param_name) ? " (обязательно)" : " (опционально)"
          puts "   • #{param_name}: #{param_info[:description]}#{required}"
        end
      end
    end
    puts
  end
end

# Демонстрация различных сценариев с инструментами
class ToolCallScenarios
  def self.run_all_scenarios
    puts "🎯 Демонстрация работы с инструментами Ruby LLM"
    puts "=" * 60

    configure_llm

    demonstrate_weather_tool
    demonstrate_calculation_tool
    demonstrate_multi_tool_usage
  end

  private

  def self.configure_llm
    RubyLLM.configure do |config|
      config.openai_api_key = ENV['OPENAI_API_KEY']
      config.anthropic_api_key = ENV['ANTHROPIC_API_KEY']
      config.default_model = 'gpt-4'
    end
  end

  def self.demonstrate_weather_tool
    puts "\n🌤️ Сценарий 1: Запрос погоды"
    puts "-" * 30

    tools = [
      {
        name: 'get_weather',
        description: 'Получает погоду для города',
        parameters: {
          type: 'object',
          properties: {
            city: { type: 'string', description: 'Город' },
            units: { type: 'string', enum: ['celsius', 'fahrenheit'] }
          },
          required: ['city']
        }
      }
    ]

    chat = RubyLLM.chat.new(
      model: 'gpt-4',
      system: "Используй инструмент get_weather для ответа на вопросы о погоде.",
      tools: tools
    )

    # Эмуляция выполнения инструмента
    def chat.execute_tool_call(tool_call)
      if tool_call.name == 'get_weather'
        args = JSON.parse(tool_call.arguments)
        city = args['city']
        "В #{city} сейчас +18°C, солнечно, влажность 65%."
      end
    end

    prompt = "Какая погода в Париже?"

    print "🤔 Запрос: #{prompt}\n"
    response = chat.say(prompt)

    if response.tool_calls.any?
      puts "🔧 Модель вызвала инструмент: #{response.tool_calls.first.name}"

      # Эмулируем выполнение инструмента и отправку результата
      result = chat.execute_tool_call(response.tool_calls.first)
      final_response = chat.say(
        tool_result: {
          tool_call_id: response.tool_calls.first.id,
          result: result
        }
      )

      print "🤖 Ответ: #{final_response.content}\n"
    else
      print "🤖 Ответ: #{response.content}\n"
    end
  end

  def self.demonstrate_calculation_tool
    puts "\n🧮 Сценарий 2: Математические вычисления"
    puts "-" * 30

    tools = [
      {
        name: 'calculate',
        description: 'Выполняет математические операции',
        parameters: {
          type: 'object',
          properties: {
            expression: { type: 'string', description: 'Математическое выражение' }
          },
          required: ['expression']
        }
      }
    ]

    chat = RubyLLM.chat.new(
      model: 'gpt-4',
      system: "Используй инструмент calculate для математических вычислений.",
      tools: tools
    )

    # Эмуляция выполнения инструмента
    def chat.execute_tool_call(tool_call)
      if tool_call.name == 'calculate'
        args = JSON.parse(tool_call.arguments)
        expression = args['expression']
        result = eval(expression)
        "Результат: #{expression} = #{result}"
      end
    end

    prompt = "Сколько будет (25 * 4) + 17?"

    print "🤔 Запрос: #{prompt}\n"
    response = chat.say(prompt)

    if response.tool_calls.any?
      puts "🔧 Модель вызвала инструмент: #{response.tool_calls.first.name}"

      result = chat.execute_tool_call(response.tool_calls.first)
      final_response = chat.say(
        tool_result: {
          tool_call_id: response.tool_calls.first.id,
          result: result
        }
      )

      print "🤖 Ответ: #{final_response.content}\n"
    else
      print "🤖 Ответ: #{response.content}\n"
    end
  end

  def self.demonstrate_multi_tool_usage
    puts "\n🔧 Сценарий 3: Использование нескольких инструментов"
    puts "-" * 30

    tools = [
      {
        name: 'get_weather',
        description: 'Получает погоду для города',
        parameters: {
          type: 'object',
          properties: {
            city: { type: 'string', description: 'Город' }
          },
          required: ['city']
        }
      },
      {
        name: 'calculate',
        description: 'Выполняет математические операции',
        parameters: {
          type: 'object',
          properties: {
            expression: { type: 'string', description: 'Математическое выражение' }
          },
          required: ['expression']
        }
      }
    ]

    chat = RubyLLM.chat.new(
      model: 'gpt-4',
      system: "Используй доступные инструменты для ответа на вопросы.",
      tools: tools
    )

    # Эмуляция выполнения инструментов
    def chat.execute_tool_call(tool_call)
      case tool_call.name
      when 'get_weather'
        args = JSON.parse(tool_call.arguments)
        "В #{args['city']} +22°C, облачно."
      when 'calculate'
        args = JSON.parse(tool_call.arguments)
        result = eval(args['expression'])
        "Результат: #{args['expression']} = #{result}"
      end
    end

    prompt = "Посмотри погоду в Лондоне и посчитай разницу между 25 и 7 градусами"

    print "🤔 Запрос: #{prompt}\n"
    response = chat.say(prompt)

    if response.tool_calls.any?
      puts "🔧 Модель вызвала инструменты:"
      response.tool_calls.each { |tc| puts "   • #{tc.name}" }

      # Обрабатываем все вызовы инструментов
      response.tool_calls.each do |tool_call|
        result = chat.execute_tool_call(tool_call)
        chat.say(
          tool_result: {
            tool_call_id: tool_call.id,
            result: result
          }
        )
      end

      # Получаем финальный ответ
      final_response = chat.say("Отлично, теперь дай полный ответ на основе полученных данных.")
      print "🤖 Ответ: #{final_response.content}\n"
    else
      print "🤖 Ответ: #{response.content}\n"
    end
  end
end

# Запуск примера
if __FILE__ == $0
  if ARGV.include?('--demo')
    # Запуск демонстрации сценариев
    ToolCallScenarios.run_all_scenarios
  else
    # Запуск интерактивного бота с инструментами
    bot = ToolCallingBot.new
    bot.start
  end
end