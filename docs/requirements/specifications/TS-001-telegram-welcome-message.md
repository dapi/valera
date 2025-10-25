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
Telegram Webhook → TelegramController → WelcomeService → Template Engine → Telegram API
                                    ↓
                              Chat/Message Models ← LLM System (для последующих сообщений)
```

### Компоненты
- **TelegramController:** Обработка входящих webhook'ов
- **WelcomeService:** Логика определения новых пользователей
- **TemplateEngine:** Обработка шаблона welcome message
- **TelegramClient:** Отправка сообщений

### Алгоритм работы
1. **Получение webhook:** Валидация и парсинг входящего сообщения
2. **Определение пользователя:** Проверка существования Chat записи по telegram_id
3. **Логика приветствия:**
   - Если новый пользователь → отправить welcome message из шаблона
   - Если существующий → маршрутизировать в LLM систему
4. **Обработка шаблона:** Интерполяция {{username}} если доступно
5. **Отправка сообщения:** Через TelegramClient
6. **Сохранение контекста:** Создание Chat и Message записей

## 🗄️ Данные и схема

### Конфигурация
```ruby
# ApplicationConfig
welcome_message_path: './data/welcome-message.md'
welcome_message_template: "./data/welcome-message.md"
```

### Шаблон welcome message
```markdown
🔧 Здравствуйте! Я Валера - AI-ассистент по кузовному ремонту и покраске автосервиса "Кузник".

Сейчас могу помочь с:
📋 Текстовыми консультациями по кузовному ремонту
💰 Расчетом стоимости по вашему описанию повреждений
🚗 Записью на бесплатный осмотр в наш сервис в Чебоксарах

В ближайшее время добавлю оценку по фото и помощь со страховками!

Расскажите, с чем нужно помочь с вашим автомобилем?
```

### База данных
- **Chat** (существующая) - добавление поля `last_contacted_at`
- **Message** (существующая) - добавление поля `message_type`
- **Индексы:** На `chats.telegram_id` для быстрого поиска

### Форматы данных
```ruby
# Telegram webhook payload
{
  "message": {
    "from": {
      "id": 123456789,
      "first_name": "Александр",
      "username": "alex_user"
    },
    "chat": {
      "id": 123456789,
      "type": "private"
    },
    "text": "Привет"
  }
}

# Template interpolation result
"Здравствуйте, Александр! Я Валера - AI-ассистент..."
```

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

## 🌐 API и интерфейсы

### Endpoints
- `POST /api/v1/telegram/webhook` - Основной webhook endpoint

### Request/Response форматы
**Request:** Telegram webhook payload
**Response:** HTTP 200 OK (empty body)

```ruby
# Welcome message payload
{
  "chat_id": 123456789,
  "text": "🔧 Здравствуйте! Я Валера - AI-ассистент по кузовному ремонту...",
  "parse_mode": nil  # Без форматирования для Dialogue-Only
}
```

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

### WelcomeService
```ruby
class WelcomeService
  def initialize(telegram_client)
    @telegram_client = telegram_client
  end

  def handle_message(webhook_data)
    user_info = extract_user_info(webhook_data)

    if new_user?(user_info[:telegram_id])
      send_welcome_message(user_info)
      create_chat_record(user_info)
    else
      # Маршрутизация в LLM систему
      route_to_llm(webhook_data)
    end
  end

  private

  def new_user?(telegram_id)
    Chat.exists?(telegram_id: telegram_id)
  end

  def send_welcome_message(user_info)
    template = load_template
    message = interpolate_template(template, user_info)

    @telegram_client.send_message(
      chat_id: user_info[:chat_id],
      text: message
    )
  end

  def load_template
    template_path = ApplicationConfig.welcome_message_path
    File.read(template_path)
  end

  def interpolate_template(template, user_info)
    return template unless user_info[:first_name]

    template.gsub("Здравствуйте!", "Здравствуйте, #{user_info[:first_name]}!")
  end
end
```

### TelegramController
```ruby
class TelegramController < ApplicationController
  def webhook
    webhook_data = JSON.parse(request.body.read)

    WelcomeService.new(telegram_client).handle_message(webhook_data)

    render json: { status: 'ok' }
  end

  private

  def telegram_client
    @telegram_client ||= TelegramClient.new
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