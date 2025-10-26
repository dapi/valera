# 📋 План исправления тестов аналитики

**Дата создания:** 27.10.2025
**Приоритет:** High
**Статус:** Требуется исправление

## 🚨 Анализ проблем

### Основные категории ошибок:

1. **Отсутствие зависимостей для тестирования** (11 failures, 20 errors)
2. **Неправильная структура данных моделей**
3. **Отсутствие mocking библиотек**
4. **Проблемы с локализацией валидаций**
5. **Несоответствие структуры полей**

## 🎯 Детальный план исправления

### Категория 1: Установка зависимостей для тестирования

**Проблемы:**
- `NoMethodError: undefined method 'stubs'`
- `NameError: undefined local variable or method 'perform_enqueued_jobs'`
- `NoMethodError: undefined method 'expects'`
- `NameError: uninitialized constant AnalyticsServiceTest::Timecop`

**Решение:**
```ruby
# Gemfile
group :test do
  gem 'mocha' # для mocking/stubbing
  gem 'timecop' # для манипуляции временем
  gem 'minitest-stub_any_instance' # для stubbing любых экземпляров
end
```

### Категория 2: Исправление структуры TelegramUser

**Проблема:**
- `ActiveModel::UnknownAttributeError: unknown attribute 'telegram_id' for TelegramUser`

**Анализ:**
- В модели `TelegramUser` нет поля `telegram_id`
- Нужно использовать поле `id` или добавить `chat_id` метод

**Решение:**
```ruby
# app/models/telegram_user.rb
def chat_id
  id # Telegram user ID и есть chat ID
end
```

### Категория 3: Исправление валидаций AnalyticsEvent

**Проблемы:**
- Локализация ошибок валидации на русском языке
- Неправильные ожидаемые сообщения об ошибках

**Решение:**
```ruby
# test/models/analytics_event_test.rb
test "should be invalid without event_name" do
  @event.event_name = nil
  assert_not @event.valid?
  # Использовать правильные ключи локализации или отключить локализацию в тестах
  assert_includes @event.errors[:event_name], "can't be blank"
end
```

### Категория 4: Исправление JSONB свойств

**Проблема:**
- Несоответствие структуры JSONB (Hash vs JSON string)

**Решение:**
```ruby
# Исправить ожидания в тестах
expected_properties = {"user_id" => 1, "platform" => "telegram"}
assert_equal expected_properties, event.properties
```

### Категория 5: Настройка тестового окружения

**Проблемы:**
- Отсутствие конфигурации для тестирования фоновых задач
- Проблемы с обработкой времени в тестах

**Решение:**
```ruby
# test/test_helper.rb
require 'mocha/minitest'
require 'timecop'

# Настройка inline обработчика для тестов
Rails.application.configure do
  config.active_job.queue_adapter = :inline
end

# Хелпер для выполнения фоновых задач
def perform_enqueued_jobs
  # Для inline adapter задачи выполняются сразу
  # Для других adapter'ов нужно использовать специальную настройку
end
```

## 📋 Пошаговый план исправления

### Step 1: Установка зависимостей (5 минут)
```bash
# Добавить в Gemfile и bundle install
echo "gem 'mocha'" >> Gemfile
echo "gem 'timecop'" >> Gemfile
bundle install
```

### Step 2: Исправление TelegramUser модели (10 минут)
```ruby
# Добавить метод chat_id
def chat_id
  id
end
```

### Step 3: Настройка тестового окружения (15 минут)
```ruby
# Обновить test/test_helper.rb
# Подключить mocha и timecop
# Настроить обработку фоновых задач
```

### Step 4: Исправление валидаций в тестах (20 минут)
```ruby
# Обновить ожидания в тестах моделей
# Учесть русскую локализацию
# Исправить сообщения об ошибках
```

### Step 5: Исправление JSONB тестов (10 минут)
```ruby
# Исправить сравнение свойств JSONB
# Обновить ожидаемые форматы данных
```

### Step 6: Исправление интеграционных тестов (30 минут)
```ruby
# Исправить Telegram webhook тесты
# Обновить создание тестовых данных
# Исправить моки и стабы
```

### Step 7: Настройка background job тестов (15 минут)
```ruby
# Исправить AnalyticsJob тесты
# Настроить правильный queue adapter
# Обновить retry логику тестов
```

### Step 8: Запуск и валидация (10 минут)
```bash
# Запустить тесты и убедиться что все проходят
bin/rails test test/models/analytics_event_test.rb
bin/rails test test/services/analytics_service_test.rb
bin/rails test test/jobs/analytics_job_test.rb
bin/rails test test/integration/analytics_pipeline_test.rb
```

## 🔧 Конкретные исправления кода

### 1. Gemfile
```ruby
group :test do
  # ... существующие гемы
  gem 'mocha'
  gem 'timecop'
  gem 'minitest-stub_any_instance'
end
```

### 2. test/test_helper.rb
```ruby
require 'mocha/minitest'
require 'timecop'

module ActiveSupport
  class TestCase
    # Настройка для тестов аналитики
    setup do
      Rails.application.config.analytics_enabled = true
      Rails.application.config.active_job.queue_adapter = :inline
    end

    def perform_enqueued_jobs
      # Для inline adapter задачи выполняются сразу
      # Метод для совместимости
    end
  end
end
```

### 3. app/models/telegram_user.rb
```ruby
def chat_id
  id
end
```

### 4. test/models/analytics_event_test.rb
```ruby
test "should be invalid without event_name" do
  @event.event_name = nil
  assert_not @event.valid?
  assert_includes @event.errors[:event_name], :blank.to_s
end
```

## ⏱️ Оценка времени

- **Step 1:** 5 минут
- **Step 2:** 10 минут
- **Step 3:** 15 минут
- **Step 4:** 20 минут
- **Step 5:** 10 минут
- **Step 6:** 30 минут
- **Step 7:** 15 минут
- **Step 8:** 10 минут

**Итого:** ~2 часа

## ✅ Критерии успеха

1. Все тесты моделей проходят
2. Все тесты сервисов проходят
3. Все тесты фоновых задач проходят
4. Все интеграционные тесты проходят
5. Покрытие кода тестами > 80%

## 🔄 План после исправления

1. Добавить performance тесты
2. Настроить CI/CD для автоматического запуска тестов
3. Добавить тесты для Metabase интеграции
4. Создать тестовые дашборды

---

**Приоритет:** High - необходимо исправить перед production развертыванием
**Ожидаемое время:** 2 часа
**Ответственный:** Developer