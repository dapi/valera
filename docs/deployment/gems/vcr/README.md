# VCR Gem Documentation

**VCR (Video Cassette Recorder)** - это Ruby gem для записи и воспроизведения HTTP взаимодействий в тестах. Позволяет создавать быстрые, детерминированные и точные тесты, которые зависят от внешних API.

## Основная концепция

VCR перехватывает HTTP запросы, записывает их в "кассеты" (cassettes), а затем воспроизводит при последующих запусках тестов. Это решает несколько проблем:

- **Скорость** - Нет реальных сетевых запросов
- **Надежность** - Тесты не зависят от доступности внешних сервисов
- **Детерминизм** - Одинаковые результаты при каждом запуске
- **Офлайн разработка** - Тесты работают без интернета

## Ключевые возможности

- **Множественные HTTP библиотеки** - Поддержка WebMock, Typhoeus, Excon, Faraday
- **Гибкая настройка** - Различные режимы записи и сопоставления запросов
- **Фильтрация чувствительных данных** - Автоматическое скрытие токенов, паролей и т.д.
- **Интеграция с тестовыми фреймворками** - RSpec, Cucumber, Minitest
- **ERB шаблоны** - Динамические данные в кассетах
- **Кастомные матчеры** - Гибкое сравнение HTTP запросов

## Быстрый старт

### 1. Установка

```ruby
# Gemfile
gem 'vcr'
gem 'webmock'  # рекомендуется для перехвата HTTP запросов
```

```bash
bundle install
```

### 2. Базовая конфигурация

```ruby
# spec/spec_helper.rb или test/test_helper.rb
require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  c.hook_into :webmock
  c.default_cassette_options = { record: :new_episodes }
end
```

### 3. Базовое использование

```ruby
# RSpec пример
describe "API Integration" do
  it "fetches user data", vcr: true do
    response = Net::HTTP.get_response('api.example.com', '/users/1')

    expect(response.code).to eq('200')
    expect(JSON.parse(response.body)['name']).to eq('John Doe')
  end
end

# Manual использование
VCR.use_cassette('github_user') do
  response = Net::HTTP.get_response('api.github.com', '/users/octocat')
  puts JSON.parse(response.body)['login']  # => "octocat"
end
```

## Режимы записи

- **`:all`** - Записывать все HTTP взаимодействия, не воспроизводить
- **`:none`** - Не записывать новые запросы, только воспроизводить существующие
- **`:new_episodes`** - Воспроизводить существующие, записывать новые
- **`:once`** - Записать один раз, затем только воспроизводить

## Архитектурные паттерны

### 1. Изоляция внешних зависимостей

```ruby
# Хороший пример - изоляция API calls
VCR.use_cassette('payment_processing') do
  payment_service.process_payment(amount: 100, token: 'tok_123')
  # Внешний запрос к Stripe/PayPal записан в кассету
end
```

### 2. Комплексные рабочие процессы

```ruby
# Тестирование многошаговых процессов
VCR.use_cassettes([
  { name: 'user_registration', record: :once },
  { name: 'email_verification', record: :new_episodes },
  { name: 'profile_creation', record: :once }
]) do
  user_service.register(email: 'test@example.com')
  user_service.verify_email(token: 'abc123')
  user_service.create_profile(name: 'John Doe')
end
```

### 3. Тестирование обработки ошибок

```ruby
# Тестирование различных сценариев ошибок
VCR.use_cassette('api_rate_limit_error') do
  expect {
    api_service.make_bulk_request(1000.times.map { |i| { id: i } })
  }.to raise_error(API::RateLimitError)
end
```

## Интеграция с проектом

### RSpec интеграция

```ruby
# spec/rails_helper.rb
require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  c.hook_into :webmock
  c.filter_sensitive_data('<API_KEY>') { |interaction|
    interaction.request.headers['Authorization']&.first
  }
end

RSpec.configure do |config|
  config.extend VCR::RSpec::Macros
end
```

### Модель тестирования

```ruby
# spec/models/user_spec.rb
describe User do
  context "external profile sync" do
    it "syncs profile from external API", vcr: true do
      user = create(:user, external_id: 'ext_123')

      user.sync_external_profile

      expect(user.profile).to be_present
      expect(user.external_data).to have_key('last_synced')
    end
  end
end
```

## Лучшая практика для проекта Valera

### 1. Структура директорий

```
spec/
├── fixtures/
│   └── vcr_cassettes/
│       ├── telegram/
│       │   ├── bot_messages.yml
│       │   └── webhook_events.yml
│       ├── ruby_llm/
│       │   ├── chat_completions.yml
│       │   └── tool_calls.yml
│       └── external_apis/
│           ├── weather_service.yml
│           └── car_service_api.yml
```

### 2. Конфигурация для Valera

```ruby
# spec/spec_helper.rb
VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  c.hook_into :webmock
  c.default_cassette_options = {
    record: :once,
    match_requests_on: [:method, :uri, :body]
  }

  # Фильтрация чувствительных данных для telegram bot
  c.filter_sensitive_data('<BOT_TOKEN>') { |interaction|
    interaction.request.uri.match(/bot(\d+):([^\/]+)/)&.captures&.second
  }

  # Фильтрация API ключей для LLM
  c.filter_sensitive_data('<OPENAI_API_KEY>') { |interaction|
    interaction.request.headers['Authorization']&.first
  }

  # Игнорирование health check запросов
  c.ignore_request { |request|
    request.uri.include?('/health') || request.uri.include?('/up')
  }
end
```

### 3. Тестирование Telegram Bot

```ruby
# spec/requests/telegram_spec.rb
describe "Telegram Bot Integration" do
  it "processes incoming messages", vcr: {
    cassette_name: 'telegram/incoming_message',
    record: :once
  } do
    post '/telegram/webhook', params: {
      message: {
        text: '/start',
        chat: { id: 12345 },
        from: { id: 12345, first_name: 'Test User' }
      }
    }

    expect(response).to have_http_status(:ok)
  end
end
```

### 4. Тестирование Ruby LLM

```ruby
# spec/services/ai_assistant_spec.rb
describe AIAssistant do
  it "generates chat response", vcr: {
    cassette_name: 'ruby_llm/chat_completion',
    record: :once,
    erb: { model_name: 'gpt-3.5-turbo' }
  } do
    assistant = AIAssistant.new
    response = assistant.chat("Hello, how can you help with car service?")

    expect(response.content).to be_present
    expect(response.model).to eq('gpt-3.5-turbo')
  end
end
```

## Документация

- **[API Reference](api-reference.md)** - Полный справочник API
- **[Примеры использования](examples/)** - Практические примеры кода
  - [Базовое использование](examples/basic-usage.rb)
  - [RSpec интеграция](examples/rspec-integration.rb)
  - [Продвинутая конфигурация](examples/advanced-configuration.rb)
  - [Паттерны тестирования](examples/testing-patterns.rb)

## Частые проблемы и решения

### 1. "Unhandled HTTP request" ошибка

```ruby
# Решение: используйте VCR.use_cassette или VCR turned_off
VCR.turned_off do
  # Код, который делает реальные HTTP запросы
end
```

### 2. Кассеты не обновляются

```ruby
# Решение: используйте правильный record mode
VCR.use_cassette('api_call', record: :new_episodes) do
  # Записывает новые взаимодействия
end
```

### 3. Чувствительные данные в кассетах

```ruby
# Решение: фильтруйте данные перед записью
VCR.configure do |c|
  c.filter_sensitive_data('<TOKEN>') { |interaction|
    interaction.request.headers['Authorization']&.first
  }
end
```

## Ссылки

- [Официальный репозиторий VCR](https://github.com/vcr/vcr)
- [Документация Relish](https://www.relishapp.com/vcr/vcr/docs)
- [WebMock](https://github.com/bblimke/webmock) - основа для перехвата HTTP запросов

---

**Дата создания:** 2025-10-26 09:23:00 UTC
**Версия VCR:** 6.3.1