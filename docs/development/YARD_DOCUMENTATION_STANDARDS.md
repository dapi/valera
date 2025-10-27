# YARD Documentation Standards

**Дата создания:** 27.10.2025
**Тип документа:** Development Standards
**Ответственный:** Development Team

## 📋 Overview

Этот документ определяет стандарты документации кода с использованием YARD (Yet Another Ruby Documentation) в проекте Valera. Качественная документация критически важна для поддержания кодовой базы и понимания архитектуры системы.

## 🚨 Критические требования

**ОБЯЗАТЕЛЬНО:** Все новые классы, модули и публичные методы должны иметь YARD-документацию!

**Цели документации:**
- Обеспечить понятность API для всех разработчиков
- Создать исчерпывающую техническую документацию
- Поддерживать высокое качество кода
- Упростить онбординг новых разработчиков

## 📝 Базовый шаблон документации

### Классы и модули

```ruby
# frozen_string_literal: true

# Обработчик вебхуков Telegram для получения сообщений от пользователей
#
# Этот контроллер обрабатывает входящие вебхуки от Telegram API,
# аутентифицирует запросы и направляет их соответствующим обработчикам.
# Поддерживает различные типы сообщений: текст, фото, документы, локацию.
#
# @example Базовая обработка текстового сообщения
#   # POST /telegram/webhook
#   # { "message": { "text": "Привет", "chat": { "id": 12345 } } }
#
#   # Контроллер обработает сообщение и создаст чат с пользователем
#
# @see Telegram::MessageHandler Для обработки различных типов сообщений
# @see Telegram::AuthService Для аутентификации запросов
# @author Danil Pismenny
# @since 0.1.0
class Telegram::WebhookController < ApplicationController
  # Обрабатывает входящие вебхуки от Telegram
  #
  # Аутентифицирует запрос, проверяет формат данных и направляет
  # сообщение соответствующему обработчику в зависимости от типа контента.
  #
  # @param [Hash] webhook_data данные вебхука от Telegram
  # @option webhook_data [String] :message информация о сообщении
  # @option webhook_data [String] :callback_query данные callback'а
  # @return [Hash] JSON ответ с результатом обработки
  # @raise [Telegram::AuthenticationError] если токен неверный
  # @raise [Telegram::InvalidFormatError] если формат данных некорректен
  # @note Этот метод является точкой входа для всех Telegram запросов
  def create
    # реализация
  end
end
```

### Сервисы и бизнес-логика

```ruby
# frozen_string_literal: true

# Сервис для управления диалогами с пользователями через AI
#
# Отвечает за обработку пользовательских сообщений, взаимодействие
# с AI моделью и формирование ответов. Поддерживает контекст диалога,
# управление инструментами и обработку ошибок.
#
# @example Базовый диалог
#   service = DialogueService.new(chat_id: 12345)
#   response = service.process_message("Привет, я хочу записаться на ТО")
#   puts response.content
#
# @see Chat модель для хранения диалогов
# @see Message модель для хранения сообщений
# @see ruby_llm документация по AI интеграции
# @author Danil Pismenny
# @since 0.1.0
class DialogueService
  # Обрабатывает входящее сообщение от пользователя
  #
  # Анализирует сообщение, определяет намерение пользователя,
  # вызывает соответствующие инструменты и формирует ответ.
  #
  # @param content [String] текст сообщения от пользователя
  # @param options [Hash] дополнительные опции обработки
  # @option options [Boolean] :streaming включить стриминг ответа
  # @option options [Hash] :context дополнительный контекст диалога
  # @option options [Array<Tool>] :available_tools доступные инструменты
  # @return [DialogueResponse] структурированный ответ системы
  # @raise [DialogueError] при ошибке обработки сообщения
  # @raise [ContentModerationError] если контент нарушает правила
  # @example Обработка простого сообщения
  #   response = process_message("Здравствуйте")
  #   response.content #=> "Здравствуйте! Чем могу помочь?"
  # @example Обработка с инструментами
  #   response = process_message("Запиши на ТО завтра",
  #     available_tools: [BookingTool.new])
  #   response.tool_calls #=> [#<ToolCall:...>]
  # @todo Добавить валидацию длины сообщения
  # @todo Реализовать обработку медиа-контента
  def process_message(content, options = {})
    # реализация
  end
end
```

### Модели данных

```ruby
# frozen_string_literal: true

# Модель пользователя Telegram бота
#
# Хранит информацию о пользователях, их предпочтениях и истории взаимодействий.
# Поддерживает управление состоянием пользователя и персонализацию ответов.
#
# @example Создание нового пользователя
#   user = TelegramUser.create(
#     telegram_id: 12345,
#     username: "john_doe",
#     first_name: "John"
#   )
#
# @example Получение активных пользователей
#   active_users = TelegramUser.active.last_week
#
# @see Chat диалоги пользователя
# @see UserPreference предпочтения пользователя
# @author Danil Pismenny
# @since 0.1.0
class TelegramUser < ApplicationRecord
  # Находит пользователя по Telegram ID или создает нового
  #
  # Используется для идентификации пользователей при получении сообщений.
  # Автоматически создает запись для новых пользователей.
  #
  # @param telegram_id [Integer] уникальный идентификатор Telegram
  # @return [TelegramUser] найденный или созданный пользователь
  # @raise [ArgumentError] если telegram_id не является числом
  # @example Поиск существующего пользователя
  #   user = TelegramUser.find_or_create_by_telegram_id(12345)
  #   user.persisted? #=> true
  # @example Создание нового пользователя
  #   user = TelegramUser.find_or_create_by_telegram_id(67890)
  #   user.new_record? #=> false
  # @note Метод thread-safe благодаря usedatabase transactions
  def self.find_or_create_by_telegram_id(telegram_id)
    # реализация
  end
end
```

### Инструменты (Tools)

```ruby
# frozen_string_literal: true

# Инструмент для бронирования услуг автосервиса
#
# Позволяет пользователям записываться на различные услуги автосервиса
# через естественный диалог. Проверяет доступность времени и валидирует данные.
#
# @example Бронирование ТО
#   tool = BookingTool.new
#   result = tool.execute(
#     service: "техническое обслуживание",
#     date: "2024-12-01",
#     time: "14:00"
#   )
#   puts result.message
#
# @see Service доступные услуги
# @see BookingSlot доступные слоты времени
# @author Danil Pismenny
# @since 0.1.0
class BookingTool < BaseTool
  # Выполняет бронирование услуги
  #
  # Проверяет доступность услуги и времени, валидирует данные
  # и создает запись в системе бронирования.
  #
  # @param service_name [String] название услуги
  # @param date [String] дата в формате YYYY-MM-DD
  # @param time [String] время в формате HH:MM
  # @param options [Hash] дополнительные опции
  # @option options [String] :phone контактный телефон
  # @option options [String] :car_model модель автомобиля
  # @return [BookingResult] результат бронирования
  # @raise [ValidationError] если данные некорректны
  # @raise [ServiceNotAvailableError] если услуга недоступна
  # @raise [TimeSlotNotAvailableError] если время занято
  # @example Успешное бронирование
  #   result = execute("ТО", "2024-12-01", "14:00", phone: "+79001234567")
  #   result.success? #=> true
  #   result.booking_id #=> "BK-2024-001"
  # @example Ошибка валидации
  #   result = execute("ТО", "invalid-date", "14:00")
  #   result.success? #=> false
  #   result.errors #=> ["Некорректный формат даты"]
  # @todo Добавить проверку праздничных дней
  # @todo Реализовать систему уведомлений
  def execute(service_name, date, time, options = {})
    # реализация
  end
end
```

## 🏷️ YARD теги и их правильное использование

### Основные теги

| Тег | Назначение | Пример использования |
|-----|------------|----------------------|
| `@param` | Описание параметра метода | `@param user_id [Integer] ID пользователя` |
| `@return` | Возвращаемое значение | `@return [String] форматированная строка` |
| `@raise` | Исключения метода | `@raise [ArgumentError] если параметр пустой` |
| `@option` | Опции в Hash параметрах | `@option options [Boolean] :strict строгий режим` |
| `@example` | Примеры использования | Полный блок кода с результатом |
| `@note` | Важные замечания | `@note Этот метод является асинхронным` |
| `@todo` | Запланированные улучшения | `@todo Добавить кэширование результатов` |

### Метаданные

| Тег | Назначение | Пример |
|-----|------------|--------|
| `@since` | Версия добавления | `@since 0.1.0` |
| `@author` | Автор кода | `@author Danil Pismenny` |
| `@deprecated` | Устаревший код | `@deprecated 0.2.0 Используйте NewService` |
| `@see` | Ссылки на связанный код | `@see OtherClass#method` |
| `@api` | Уровень доступа API | `@api private` |

## ✅ Требования к качеству документации

### Обязательные элементы

**Для всех публичных методов:**
- ✅ Краткое описание одной строкой
- ✅ Подробное описание (если метод сложный)
- ✅ Все `@param` с типами и описаниями
- ✅ `@return` с типом (кроме `void` методов)
- ✅ `@raise` для всех documented исключений
- ✅ `@since` тег
- ✅ Минимум один `@example` для сложных методов

**Для всех классов и модулей:**
- ✅ Краткое описание назначения
- ✅ Подробное описание функциональности
- ✅ `@author` тег
- ✅ `@since` тег
- ✅ `@see` теги для связанных классов
- ✅ Минимум один `@example`

### Типы данных в YARD

**Основные типы:**
- `String` - строки
- `Integer` - целые числа
- `Float` - числа с плавающей точкой
- `Boolean` - true/false
- `Array` - массивы
- `Hash` - хэши
- `Symbol` - символы
- `Time` - время
- `Date` - дата
- `DateTime` - дата и время

**Составные типы:**
- `Array<String>` - массив строк
- `Hash{Symbol => String}` - хэш с ключами-символами и строковыми значениями
- `String, nil` - строка или nil
- `Array<Tool>` - массив объектов Tool

**Кастомные типы:**
- `TelegramUser` - класс модели
- `BookingResult` - результат операции
- `DialogueResponse` - ответ диалога

## 🔍 Проверка качества документации

### Автоматическая проверка

```bash
# Проверить покрытие документации
rake doc:coverage

# Проверить качество документации
rake doc:quality

# Сгенерировать полную документацию
rake doc:complete
```

### Чек-лист качества

Перед коммитом кода убедитесь:

- [ ] Все новые классы имеют документацию
- [ ] Все публичные методы имеют документацию
- [ ] Все параметры типизированы
- [ ] Все возвращаемые значения типизированы
- [ ] Все исключения документированы
- [ ] Есть примеры использования для сложных методов
- [ ] Добавлены `@since` и `@author` теги
- [ ] Документация проходит `rake doc:quality`

## 🚀 Генерация документации

### Локальная разработка

```bash
# Сгенерировать документацию
rake yard

# Запустить сервер для просмотра
rake yard_server

# Открыть в браузере
open http://localhost:8808
```

### CI/CD интеграция

Документация автоматически проверяется в CI:
- Покрытие документации должно быть > 80%
- Все `@todo` и `@fixme` должны быть обработаны
- Примеры кода должны быть синтаксически корректны

## 📚 Примеры плохой и хорошей документации

### ❌ Плохая документация

```ruby
class UserService
  # Обновляет пользователя
  def update_user(id, params)
    # код без документации
  end
end
```

**Проблемы:**
- Нет описания класса
- Нет типов параметров
- Нет описания возвращаемого значения
- Нет примеров использования
- Нет обработки исключений

### ✅ Хорошая документация

```ruby
# frozen_string_literal: true

# Сервис для управления пользователями системы
#
# Предоставляет CRUD операции для управления пользовательскими
# аккаунтами, включая валидацию данных и уведомления.
#
# @author Danil Pismenny
# @since 0.1.0
class UserService
  # Обновляет данные существующего пользователя
  #
  # Валидирует входные параметры, обновляет запись в базе данных
  # и отправляет уведомления об изменениях.
  #
  # @param user_id [Integer] ID пользователя для обновления
  # @param params [Hash] параметры для обновления
  # @option params [String] :email новый email адрес
  # @option params [String] :first_name новое имя
  # @option params [String] :last_name новая фамилия
  # @return [User] обновленный объект пользователя
  # @raise [UserNotFound] если пользователь не найден
  # @raise [ValidationError] если данные некорректны
  # @example Обновление email пользователя
  #   user = update_user(123, { email: "new@example.com" })
  #   user.email #=> "new@example.com"
  # @example Обновление нескольких полей
  #   user = update_user(456, {
  #     first_name: "John",
  #     last_name: "Doe"
  #   })
  #   user.full_name #=> "John Doe"
  # @note Метод автоматически валидирует формат email
  # @todo Добавить поддержку аватаров
  def update_user(user_id, params = {})
    # реализация
  end
end
```

---

## 📊 Информация о документе

**Версия:** 1.0
**Дата создания:** 27.10.2025
**Последнее обновление:** 27.10.2025
**Тип документа:** Development Standards
**Ответственный:** Development Team

📈 **[Метрики использования](docs/docs-usage-metrics.md#yard-documentation-standards)** - см. централизованный документ метрик