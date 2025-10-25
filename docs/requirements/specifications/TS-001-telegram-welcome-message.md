# Technical Specification: TS-001 - Telegram Welcome Message Implementation

**Статус:** Draft
**Приоритет:** High
**Версия:** 1.0
**Создан:** 26.10.2025
**Автор:** Technical Lead
**Ревьювер:** Senior Developer

## 📋 Обзор (Overview)

### Описание
Техническая спецификация реализации системы приветствия новых пользователей в Telegram боте "Валера" для автосервиса "Кузник" с использованием гибридного архитектурного подхода.

### Цели
- [ ] Мгновенная отправка приветственного сообщения новым пользователям
- [ ] Соблюдение Hybrid Architecture подхода (шаблон + LLM)
- [ ] Интеграция с существующей системой Chat/Message моделей
- [ ] Обеспечение соответствия Product Constitution

## 🔧 Требования

### Функциональные требования
- **FR-001:** Определение новых пользователей через Telegram webhook
- **FR-002:** Отправка конфигурируемого welcome message из файла
- **FR-003:** Поддержка интерполяции username в шаблоне
- **FR-004:** Маршрутизация последующих сообщений в LLM систему
- **FR-005:** Логирование всех приветствий

### Нефункциональные требования
- **Производительность:** Время отправки welcome message < 200ms
- **Надежность:** 99.9% доступность, работа при недоступности LLM
- **Масштабируемость:** Поддержка до 1000 одновременных приветствий
- **Безопасность:** Валидация webhook от Telegram

## 🏗️ Техническое решение (Technical Approach)

### Архитектура
```
Telegram API → telegram_webhook helper → Telegram::WebhookController → WelcomeService → Template Engine → respond_with
                                                     ↓
                                           TelegramUser/Chat Models ← LLM System (для последующих сообщений)
```

### Компоненты
- **Telegram::WebhookController:** Наследуется от `Telegram::Bot::UpdatesController`, обрабатывает входящие обновления
- **WelcomeService:** Логика определения новых пользователей и отправки приветствия
- **TemplateEngine:** Обработка шаблона welcome message
- **respond_with:** Встроенный метод контроллера для отправки сообщений

### Алгоритм работы
1. **Получение webhook:** Автоматическая обработка через `telegram_webhook` helper
2. **Определение пользователя:** Проверка существования TelegramUser по `from['id']`
3. **Логика приветствия:**
   - **Новый пользователь:** Отправка welcome message через `start!` command handler
   - **Существующий пользователь:** Маршрутизация в LLM систему через `message` handler
4. **Обработка шаблона:** Интерполяция `#{name}` на `telegram_user.name`
5. **Отправка сообщения:** Через `respond_with :message, text:` в контроллере
6. **Сохранение контекста:** Создание TelegramUser записи через `find_or_create_by!` (Chat/Message логика будет в отдельной спецификации)

## 🗄️ Данные и схема

### Конфигурация
```ruby
# ApplicationConfig - путь к шаблону захардкожен в welcome_message_template_path методе
```

### Локализация (I18n)
```yaml
# config/locales/ru.yml
ru:
  telegram:
    welcome_message:
      default: |
        🔧 Здравствуйте! Я Валера - AI-ассистент по кузовному ремонту и покраске.

        Сейчас могу помочь с:
        📋 Текстовыми консультациями по кузовному ремонту
        💰 Расчетом стоимости по вашему описанию повреждений
        🚗 Записью на бесплатный осмотр в сервис

        В ближайшее время добавлю оценку по фото и помощь со страховками!

        Расскажите, с чем нужно помочь с вашим автомобилем?
```

### Шаблон welcome message
```markdown
# data/welcome-message.md
🔧 Здравствуйте! Я Валера - AI-ассистент по кузовному ремонту и покраске.

Сейчас могу помочь с:
📋 Текстовыми консультациями по кузовному ремонту
💰 Расчетом стоимости по вашему описанию повреждений
🚗 Записью на бесплатный осмотр в сервис

В ближайшее время добавлю оценку по фото и помощь со страховками!

Расскажите, с чем нужно помочь с вашим автомобилем?
```

**Примечание:** Шаблон может использовать `#{name}` для персонализации, которая будет заменена на имя пользователя или @username в `interpolate_template`.

### База данных
**Текущая структура (уже реализована):**
- **TelegramUser** - таблица пользователей Telegram
  - `id` (bigint, primary key) - Telegram user ID
  - `first_name`, `last_name`, `username`, `photo_url`
  - `created_at`, `updated_at`
- **Chat** - таблица чатов, связанная с TelegramUser
  - `telegram_user_id` (foreign key, unique)
  - `model_id` (foreign key)
  - `created_at`, `updated_at`
- **Message** - таблица сообщений в чате
  - `chat_id` (foreign key)
  - `role` (string: 'user', 'assistant', 'system')
  - `content` (text)
  - `input_tokens`, `output_tokens` (integer)
  - `tool_call_id`, `model_id` (foreign keys)

**Индексы:** Уже существуют на `telegram_user_id`, `chat_id`, `role`

### Форматы данных
```ruby
# Доступные данные в Telegram::Bot::UpdatesController
# from['id'], from['first_name'], from['username'] и т.д.

# TelegramUser запись (после find_or_create)
#<TelegramUser:0x00001234567890
  id: 123456789,
  first_name: "Александр",
  last_name: "Иванов",
  username: "alex_user",
  created_at: "2025-10-25 20:00:00",
  updated_at: "2025-10-25 20:00:00">

# Template interpolation result
"Здравствуйте, @alex_user! 🔧 Я Валера - AI-ассистент..."
```

### Типы входящих сообщений
- **Команда `/start`:** Обрабатывается через `start!` method → welcome message
- **Текстовые сообщения:** Обрабатываются через `message` method → LLM система
- **Другие типы:** Callback queries, inline keyboards и т.д.

## 🔌 Интеграции и зависимости

### Внутренние зависимости
- **ruby_llm gem:** Для последующих сообщений (не для welcome)
- **anyway_config:** Конфигурация пути к шаблону
- **Solid Queue:** Асинхронная отправка сообщений
- **Rails Models:** Chat, Message для сохранения контекста

### Gems и библиотеки
- **telegram-bot-rb:** Основной gem для работы с Telegram API
- **rails:** Rails framework (существующий)
- **pg:** PostgreSQL (существующий)

## 🌐 Telegram Webhook интерфейс

### Webhook endpoint
Основной webhook endpoint обрабатывается через `Telegram::Bot::UpdatesController` в `Telegram::WebhookController`

## 🔒 Безопасность

### Аутентификация и авторизация
- Проверка секретного токена webhook'а
- Валидация источника запроса (только Telegram IP)

### Обработка ошибок
- Логирование всех ошибок с детальной информацией
- Graceful degradation при недоступности шаблона
- Retry механизм для временных сбоев

## 🧪 Тестирование

### Unit тесты
- [ ] WelcomeService пользовательской логики
- [ ] TemplateEngine обработки шаблонов
- [ ] TelegramController webhook обработки
- [ ] TelegramClient отправки сообщений

### Integration тесты
- [ ] End-to-end webhook flow
- [ ] Database integration с Chat/Message моделями
- [ ] Template loading и interpolation
- [ ] Telegram API integration (mocked)

### E2E тесты
- [ ] New user welcome flow
- [ ] Returning user LLM routing
- [ ] Template interpolation с username
- [ ] Error handling сценарии

## 📊 Мониторинг и логирование

### Метрики
- welcome_messages_sent: Количество отправленных приветствий
- welcome_processing_time: Время обработки приветствия
- new_users_count: Количество новых пользователей
- template_load_errors: Ошибки загрузки шаблона

### Логи
- welcome_sent: INFO уровень, данные пользователя
- template_loaded: DEBUG уровень, путь к шаблону
- welcome_error: ERROR уровень, детали ошибки
- webhook_received: INFO уровень, формат JSON

## 🔧 Детальная реализация

### ApplicationConfig
```ruby
# config/configs/application_config.rb
class ApplicationConfig
  # ... существующий код ...

  def welcome_message_template
    template_path = welcome_message_template_path
    File.read(template_path)
  rescue Errno::ENOENT
    I18n.t('telegram.welcome_message.default')
  end

  private

  def welcome_message_template_path
    Rails.root.join('data', 'welcome-message.md')
  end
end
```

### WelcomeService
```ruby
# frozen_string_literal: true

class WelcomeService
  def send_welcome_message(telegram_user, controller)
    template = ApplicationConfig.welcome_message_template
    message = interpolate_template(template, telegram_user)

    # Отправка через respond_with из контроллера
    controller.respond_with :message, text: message

    Rails.logger.info "Welcome message sent to telegram_user: #{telegram_user.id}"
  end

  private

  def interpolate_template(template, telegram_user)
    # Простая интерполяция #{name} -> telegram_user.name
    template.gsub("#{name}", telegram_user.name)
  end
end
```

### Telegram::WebhookController
```ruby
# frozen_string_literal: true

class Telegram::WebhookController < Telegram::Bot::UpdatesController
  before_action :find_or_create_telegram_user

  # message method остается без изменений - обрабатывается ruby_llm через acts_as_chat

  # Command handler /start - ЗДЕСЬ ТОЛЬКО ОТПРАВКА WELCOME
  def start!(*args)
    # Отправляем приветствие новому пользователю
    WelcomeService.new.send_welcome_message(telegram_user, self)

    nil
  end

  private

  attr_reader :telegram_user

  def find_or_create_telegram_user
    # Метод остается без изменений - используется существующая реализация
    @telegram_user = TelegramUser.find_or_create_by!(id: from['id'])
  end
end
```

## 🚀 Deployment

### Среды
- **Development:** Локальная настройка с ngrok для webhook'ов
- **Staging:** Отдельный bot token для тестов
- **Production:** Основной бот с мониторингом

### Конфигурация окружения
```bash
# .env.production
WELCOME_MESSAGE_PATH="./data/welcome-message.md"
TELEGRAM_BOT_TOKEN="production_bot_token"
```

## ⚠️ Риски и митигация

| Риск | Вероятность | Влияние | Митигация |
|------|-------------|---------|-----------|
| Template файл не найден | Низкая | Высокое | Graceful degradation с дефолтным сообщением |
| Telegram API недоступен | Средняя | Высокое | Retry механизм, очередь сообщений |
| Высокая нагрузка | Средняя | Среднее | Кэширование пользователей, оптимизация запросов |
| Ошибка интерполяции | Низкая | Среднее | Валидация шаблона, safe interpolation |

## 🔗 Связанные документы

- **User Story:** [US-001-telegram-auto-greeting.md](../user-stories/US-001-telegram-auto-greeting.md)
- **Feature Description:** [feature-telegram-welcome-experience.md](../features/feature-telegram-welcome-experience.md)
- **Product Constitution:** [constitution.md](../../product/constitution.md)
- **Company Data:** [кузник.csv](../../data/кузник.csv), [company-info.md](../../data/company-info.md)

## 📋 Критерии готовности

### ✅ Definition of Done
- [ ] Все функциональные требования реализованы
- [ ] Unit тесты покрытием > 90%
- [ ] Integration тесты проходят
- [ ] E2E тесты на ключевые сценарии
- [ ] Performance тесты (< 200ms ответ)
- [ ] Security аудит пройден
- [ ] Документация обновлена
- [ ] Мониторинг настроен
- [ ] Code review пройден
- [ ] Тестирование на staging с реальными Telegram аккаунтами

### 🚀 Готовность к продакшену
- [ ] Welcome message соответствует Product Constitution
- [ ] Hybrid Architecture approach реализован
- [ ] Все метрики мониторинга работают
- [ ] Алерты настроены
- [ ] Rollback план протестирован
- [ ] Команда эксплуатации обучена

---

**История изменений:**
- 26.10.2025 22:45 - v1.0: Создание технической спецификации на основе US-001
  - Добавлен Hybrid Architecture подход
  - Детализирована техническая реализация
  - Определены критерии готовности и риски
- 25.10.2025 20:30 - v1.1: Обновление спецификации согласно текущей архитектуре
  - Исправлена архитектура: Telegram::WebhookController вместо TelegramController
  - Обновлен алгоритм работы с учетом telegram-bot-rb gem
  - Актуализирована схема данных (TelegramUser/Chat/Message)
  - Добавлены детали интеграции с telegram_webhook helper
  - Обновлены примеры кода для соответствия реальной реализации