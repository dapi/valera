# Technical Specification: TS-002a - Telegram Basic Consultation

**Статус:** Ready for Development
**Версия:** 2.0 (адаптированная под текущую архитектуру)
**Приоритет:** High
**Оценка времени:** 2-4 часа (минимальные изменения)
**Создан:** 25.10.2025
**Автор:** Technical Lead
**Обновлен:** 25.10.2025 (адаптация)

## 📋 Обзор (Overview)

### Описание
Техническая спецификация реализации базовых AI-консультаций по кузовному ремонту в Telegram. Система использует **ПОЛНОСТЬЮ ГОТОВУЮ** ruby_llm инфраструктуру и требует МИНИМАЛЬНЫХ изменений для активации функциональности.

### Цели
- [x] **Активировать** уже существующую AI-консультацию по кузовному ремонту
- [x] **Использовать** готовый системный промпт с ценами (уже в `/data/system-prompt.md`)
- [x] **Использовать** готовый прайс-лист (уже в `/data/price.csv`)
- [ ] **Исправить** передачу сообщений в LLM через `chat.ask(message)`
- [ ] Обеспечить естественный диалог без кнопок (Product Constitution - уже соблюдается)

## 🏗️ Архитектура на основе существующего кода

### ✅ ПОЛНОСТЬЮ ГОТОВАЯ инфраструктура:
- ✅ **TelegramUser модель** - создана с `has_one :chat`
- ✅ **Chat модель** - интегрирована с ruby_llm через `acts_as_chat`
- ✅ **Message модель** - готова для хранения сообщений через `acts_as_message`
- ✅ **Telegram::WebhookController** - обрабатывает webhook через telegram-bot gem
- ✅ **WelcomeService** - работает для US-001
- ✅ **ApplicationConfig** - настроена через anyway_config
- ✅ **ruby_llm интеграция** - Chat модель уже использует `acts_as_chat`
- ✅ **Системный промпт** - `./data/system-prompt.md` содержит инструкции по консультациям
- ✅ **Прайс-лист** - `./data/price.csv` с ценами по классам автомобилей (1/2/3)
- ✅ **RSpec тесты** - базовая структура тестов уже существует

### 🚨 ЕДИНСТВЕННАЯ ПРОБЛЕМА:
**Контроллер не передает сообщения в LLM!** Текущий метод `message(message)` пустой.

### Правильный поток данных для US-002a:
```
Telegram webhook → Telegram::WebhookController → chat.ask(message) →
ruby_llm (Message модель + AI response) → Ответ клиенту
```

## 🔧 Требования к реализации

### Функциональные требования (АКТИВАЦИЯ):
- **FR-001:** AI понимает запросы о кузовном ремонте ✅ (уже готово в системном промпте)
- **FR-002:** Предоставляет ориентировочную стоимость в виде диапазонов цен ✅ (уже готово)
- **FR-003:** Уточняет класс автомобиля при необходимости ✅ (уже готово в системном промпте)
- **FR-004:** Использует существующий CSV прайс-лист через системный промпт ✅ (уже готово)
- **FR-005:** Работает в рамках диалога без кнопок (Product Constitution) ✅ (уже соблюдается)
- **FR-006:** **ПЕРЕДАЧА СООБЩЕНИЙ В LLM** - единственное что нужно реализовать

### Нефункциональные требования:
- **Производительность:** AI ответ < 5 секунд (ruby_llm обеспечивает)
- **Язык:** Только русский ✅ (уже в системном промпте)
- **Диалог:** Естественный диалог без интерфейсов ✅ (Product Constitution соблюден)
- **Надежность:** Graceful degradation при ошибках AI ✅ (ruby_llm обеспечивает)

## 🛠️ Техническое решение (ЕДИНСТВЕННОЕ НЕОБХОДИМОЕ ИЗМЕНЕНИЕ)

### 🚨 КЛЮЧЕВОЕ ОТКРЫТИЕ: ВСЕ УЖЕ ГОТОВО!

После анализа текущей архитектуры выяснилось, что:

1. **Системный промпт уже содержит** все инструкции для консультаций по кузовному ремонту ✅
2. **Прайс-лист уже загружен** и работает через системный промпт ✅
3. **ApplicationConfig уже умеет** загружать файлы ✅
4. **Chat модель уже готова** для работы с ruby_llm ✅
5. **НЕТ НУЖДЫ** изменять системный промпт или ApplicationConfig!

### 💡 Единственное необходимое изменение: Исправить метод `message` в контроллере

**Проблема:** Текущий метод `message(message)` ничего не делает с сообщениями пользователя.

**Решение:** Передавать сообщения в LLM через `chat.ask(message)`

**Файл:** `app/controllers/telegram/webhook_controller.rb` (исправить существующий)

```ruby
def message(message)
  # Проверяем, что это текстовое сообщение
  return unless message['text'].present?

  # Сохраняем сообщение пользователя в базу через ruby_llm
  # ruby_llm автоматически:
  # 1. Сохранит сообщение в Message модель
  # 2. Использует системный промпт (уже с ценами!)
  # 3. Сгенерирует AI ответ

  ai_response = llm_chat.ask(message['text'])

  # Отправляем ответ клиенту через Telegram API
  respond_with :message, text: ai_response
rescue => e
  # Обработка ошибок AI
  Rails.logger.error "Error processing message: #{e.message}"
  respond_with :message, text: "Извините, произошла ошибка. Попробуйте еще раз."
end
```

### ✅ Почему это будет работать:

1. **Системный промпт уже содержит** инструкции по консультациям и ценам
2. **ruby_llm автоматически** использует `acts_as_chat` и сохраняет сообщения
3. **Chat модель** уже настроена для работы с LLM
4. **Product Constitution соблюдается** - все сообщения идут напрямую в AI без фильтрации

### 🔍 Анализ текущего системного промпта:

Текущий `/data/system-prompt.md` уже содержит:
- Инструкции по консультациям по кузовному ремонту ✅
- Правила работы с прайс-листом ✅
- Классификацию автомобилей (1/2/3 классы) ✅
- Правила форматирования ответов ✅
- Инструкции по работе с RequestDetector для заявок ✅

**НЕТ НУЖДЫ** что-либо добавлять в промпт - он уже полный!

### ❌ НЕ НУЖНО ДЕЛАТЬ (изначальная спецификация была неправильной):

- ~~Расширять системный промпт~~ - уже содержит все инструкции
- ~~Добавлять system_prompt_template в ApplicationConfig~~ - не нужно
- ~~Добавлять метод system_prompt в Chat модель~~ - ruby_llm работает без этого
- ~~Создавать новую логику~~ - вся логика уже готова

### 🎯 ИТОГ: Простейшая реализация

**Нужно изменить ОДНУ строчку в контроллере:**
```ruby
# Было:
def message(message)
  # Ничего не делаем здесь - LLM система обрабатывает сообщения автоматически
end

# Стало:
def message(message)
  ai_response = llm_chat.ask(message['text'])
  respond_with :message, text: ai_response
end
```

**Все остальное уже работает!**

## 🧪 Тестирование

### RSpec тест для Telegram контроллера

**Файл:** `spec/requests/telegram_webhook_spec.rb`

```ruby
require 'rails_helper'

RSpec.describe Telegram::WebhookController, type: :telegram_bot_controller do
  let(:telegram_user) { TelegramUser.create!(id: from_id, first_name: "Иван", last_name: "Петров") }
  let(:chat) { Chat.create!(telegram_user: telegram_user) }

  # Используем telegram-bot RSpec helpers
  include_context 'telegram/bot/updates_controller'

  describe '#message' do
    context "когда пользователь отправляет сообщение о кузовном ремонте" do
      it "сохраняет сообщение в базе данных через ruby_llm" do
        expect {
          dispatch_message "сколько стоит убрать вмятину на двери?"
        }.to change(Message, :count).by(1)

        # Проверяем, что сообщение сохранено с правильным содержимым
        saved_message = Message.last
        expect(saved_message.content).to eq("сколько стоит убрать вмятину на двери?")
        expect(saved_message.chat).to eq(chat)
      end

      it "передает запрос в LLM и получает ответ" do
        # Мокаем LLM ответ через chat.ask
        allow(chat).to receive(:ask).with("сколько стоит убрать вмятину на двери?").and_return("Ориентировочно 7000-10000₽")

        dispatch_message "сколько стоит убрать вмятину на двери?"

        expect(response).to have_http_status(:ok)
      end

      it "отправляет ответ пользователю через Telegram API" do
        # Мокаем LLM ответ
        allow(chat).to receive(:ask).and_return("Ориентировочно 7000-10000₽")

        # Ожидаем, что будет отправлено сообщение с текстом ответа
        expect { dispatch_message "сколько стоит убрать вмятину на двери?" }
          .to respond_with_message("Ориентировочно 7000-10000₽")
      end
    end

    context "когда пользователь отправляет обычное сообщение" do
      it "также сохраняет сообщение в базе данных" do
        expect {
          dispatch_message "привет"
        }.to change(Message, :count).by(1)

        saved_message = Message.last
        expect(saved_message.content).to eq("привет")
      end

      it "передает обычное сообщение в LLM и получает ответ" do
        allow(chat).to receive(:ask).with("привет").and_return("Здравствуйте!")

        dispatch_message "привет"

        expect(response).to have_http_status(:ok)
      end
    end

    context "когда пользователь отправляет команду /start" do
      it "обрабатывает команду через start! метод" do
        expect(controller).to receive(:start!)

        dispatch_command :start
      end
    end
  end

  describe '#callback_query' do
    it "отвечает на callback query" do
      expect(controller).to receive(:answer_callback_query).with('Получено!')

      dispatch callback_query: {data: 'test_data'}
    end
  end
end
```

**Примечание:** Тест использует официальные telegram-bot RSpec helpers:
- `type: :telegram_bot_controller` - специальный тип для тестирования Telegram контроллеров
- `include_context 'telegram/bot/updates_controller'` - включает telegram-bot тестовые хелперы
- `dispatch_message` - отправляет тестовое сообщение в контроллер
- `dispatch_command` - отправляет тестовую команду
- `respond_with_message` - проверяет что было отправлено сообщение пользователю
- `from_id` и `chat_id` - автоматически доступны из контекста telegram-bot RSpec

## 📊 Проверка готовности (Checklist)

### ✅ Уже готово:
- [x] Модели TelegramUser и Chat
- [x] Базовый webhook контроллер
- [x] Ruby LLM интеграция через `acts_as_chat`
- [x] Системный промпт в `./data/system-prompt.md` (полностью готов!)
- [x] Прайс-лист в `./data/price.csv`
- [x] ApplicationConfig с поддержкой загрузки файлов
- [x] RSpec тесты базовая структура

### 🔄 Нужно реализовать:
- [ ] Исправить метод `message` в контроллере для использования `chat.ask(message)`
- [ ] Дополнить RSpec тесты для проверки сохранения сообщений
- [ ] Протестировать вручную

### 📈 Метрики успеха:
- **AI response time** < 5 секунд
- **Message persistence** > 99% (все сообщения сохраняются в базе)
- **User satisfaction** - клиенты получают понятные ответы на консультации

## 🚀 Deployment

### Шаги развертывания:
1. **Исправить контроллер:** `app/controllers/telegram/webhook_controller.rb` (изменить метод `message`)
2. **Обновить тесты:** `spec/requests/telegram_webhook_spec.rb` (добавить проверки)
3. **Запустить тесты:** `bundle exec rspec`
4. **Проверить в проде:** отправить тестовое сообщение в бот

### Rollback план:
- Восстановить исходный метод `message` в контроллере
- Перезапустить приложение

## ⚡ Оценка усилий

**Сложность:** Очень низкая
**Время:** 2-4 часа
**Риски:** Минимальные (используем существующую инфраструктуру)
**Команда:** 1 разработчик

**Преимущества подхода:**
- ✅ Использует существующий ruby_llm код
- ✅ Минимальные изменения (1 файл)
- ✅ Очень быстрая реализация
- ✅ Полное соответствие Product Constitution (dialogue-only, AI-first)
- ✅ Не требует сложной логики или фильтрации
- ✅ Все сообщения сохраняются в базе через ruby_llm

**Готовность к разработке:** ✅ Очень высокая

## 🔗 Связанные документы

- **User Story:** [../user-stories/US-002a-telegram-basic-consultation.md](../user-stories/US-002a-telegram-basic-consultation.md)
- **Product Constitution:** [../product/constitution.md](../product/constitution.md)
- **US-001:** [../user-stories/US-001-telegram-auto-greeting.md](../user-stories/US-001-telegram-auto-greeting.md) (зависимость)
- **Implementation Protocol:** [.protocol-us002a-implementation.md](../../.protocols/protocol-us002a-implementation.md)

---

**История изменений:**
- 25.10.2025 20:00 - v1.0: Создана спецификация на основе существующей инфраструктуры
- 25.10.2025 23:00 - v2.0: Адаптация под текущую архитектуру - обнаружено что всё уже готово