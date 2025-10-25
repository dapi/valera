# Protocol: User Chat Architecture Implementation

**Протокол:** protocol-user-chat-architecture-implementation
**Статус:** Draft
**Приоритет:** High
**Версия:** 1.0
**Создан:** 27.10.2025
**Автор:** AI Agent
**Основан на:** TSOL-002, ruby_llm архитектуре

## 🎯 Цель реализации

Рефакторинг архитектуры Valera бота для соответствия ruby_llm паттернам:
- Разделение пользователя Telegram и чата с AI
- Реализация двухуровневой before_action фильтрации
- Обеспечение сохранения истории диалогов

## 📋 Общий план имплементации

### **Phase 0: Подготовка и резервное копирование**
- [ ] Создать бэкап базы данных
- [ ] Отключить бота от Telegram API
- [ ] Проверить текущие тесты

### **Phase 1: Создание TelegramUser модели**
- [ ] Создать миграцию `20251027000001_create_telegram_users.rb`
- [ ] Создать модель `app/models/telegram_user.rb`
- [ ] Написать unit тесты для TelegramUser
- [ ] Запустить миграцию

### **Phase 2: Рефакторинг Chat модели**
- [ ] Создать миграцию `20251027000002_update_chats_for_ruby_llm.rb`
- [ ] Обновить модель `app/models/chat.rb`
- [ ] Добавить `acts_as_chat` интеграцию
- [ ] Написать unit тесты для Chat
- [ ] Запустить миграцию с переносом данных

### **Phase 3: Обновление Message модели**
- [ ] Создать миграцию `20251027000003_update_messages_for_ruby_llm.rb`
- [ ] Обновить модель `app/models/message.rb`
- [ ] Добавить `acts_as_message` интеграцию
- [ ] Написать unit тесты для Message
- [ ] Запустить миграцию

### **Phase 4: Обновление TelegramController**
- [ ] Добавить два before_action фильтра
- [ ] Обновить методы контроллера
- [ ] Написать integration тесты
- [ ] Проверить работу с существующими данными

### **Phase 5: Обновление сервисов**
- [ ] Обновить WelcomeService для работы с Chat
- [ ] Добавить логирование и обработку ошибок
- [ ] Тестировать WelcomeService

### **Phase 6: Тестирование и отладка**
- [ ] Запустить все тесты
- [ ] Проверить данные миграции
- [ ] Интеграционное тестирование
- [ ] Включить бота обратно

## 🔧 Техническое решение (для обсуждения)

### **1. Модели архитектуры**

#### **TelegramUser модель:**
```ruby
# app/models/telegram_user.rb
class TelegramUser < ApplicationRecord
  validates :telegram_id, presence: true, uniqueness: true

  has_many :chats, dependent: :destroy
  has_one :active_chat,
         -> { where(active: true) },
         class_name: 'Chat',
         dependent: :destroy

  def find_or_create_active_chat
    active_chat || chats.create!(active: true)
  end

  def set_active_chat(chat)
    transaction do
      chats.update_all(active: false)
      chat.update!(active: true)
    end
  end

  def touch_last_contacted
    update!(last_contacted_at: Time.current)
  end
end
```

#### **Chat модель (рефакторинг):**
```ruby
# app/models/chat.rb
class Chat < ApplicationRecord
  belongs_to :telegram_user
  has_many :messages, dependent: :destroy

  acts_as_chat  # ruby_llm интеграция

  scope :active, -> { where(active: true) }
  validates :title, presence: true

  def activate!
    telegram_user.set_active_chat(self)
  end
end
```

#### **Message модель (обновление):**
```ruby
# app/models/message.rb
class Message < ApplicationRecord
  belongs_to :chat

  acts_as_message  # ruby_llm интеграция

  validates :content, presence: true
  validates :role, inclusion: { in: %w[user assistant system] }

  attribute :message_type, :string, default: 'user'
end
```

### **2. TelegramController с двумя фильтрами:**

```ruby
# app/controllers/telegram_controller.rb
class TelegramController < Telegram::Bot::UpdatesController
  before_action :find_or_create_telegram_user
  before_action :find_or_create_db_chat

  def start!(*args)
    WelcomeService.new.send_welcome_message(@db_chat)
  end

  def message(message)
    respond_with :message, text: "Ваше сообщение получено! Бот находится в разработке."
  end

  private

  def find_or_create_telegram_user
    telegram_id = from.id
    @telegram_user = TelegramUser.find_by(telegram_id: telegram_id)

    unless @telegram_user
      @telegram_user = TelegramUser.create!(
        telegram_id: telegram_id,
        username: from.username,
        first_name: from.first_name,
        last_name: from.last_name,
        last_contacted_at: Time.current
      )
    else
      @telegram_user.touch_last_contacted
    end
  end

  def find_or_create_db_chat
    @db_chat = @telegram_user.find_or_create_active_chat
  end
end
```

### **3. Обновленный WelcomeService:**

```ruby
# app/services/welcome_service.rb
class WelcomeService
  def send_welcome_message(db_chat)
    template = load_template
    message = interpolate_template(template, db_chat.telegram_user)

    # Создаем сообщение в ruby_llm формате
    db_chat.messages.create!(
      content: message,
      role: 'assistant',
      message_type: 'welcome'
    )

    # Отправляем через Telegram API
    send_telegram_message(db_chat.telegram_user.telegram_id, message)
  end
end
```

## ⚠️ Риски и вопросы для обсуждения

### **Технические риски:**

1. **Миграция данных:** Есть риск потери существующих данных при переносе из Chat в TelegramUser
2. **Производительность:** Дополнительные запросы к базе данных для find/create операций
3. **Совместимость:** Нужно проверить совместимость с существующим кодом, который использует Chat

### **Вопросы для обсуждения:**

1. **Названия таблиц:**
   - `telegram_users` - понятно?
   - `chats` - оставить или переименовать в `ai_chats`?
   - `messages` - оставить или переименовать в `chat_messages`?

2. **Структура чатов:**
   - Один активный чат на пользователя - достаточно?
   - Нужно ли историю старых чатов?
   - Как обрабатывать переключение между чатами?

3. **Миграция данных:**
   - Как обрабатывать существующие чаты без telegram_id?
   - Нужно ли сохранять историю сообщений?
   - Как проверить целостность данных после миграции?

4. **Ruby LLM интеграция:**
   - Все ли поля для `acts_as_chat` и `acts_as_message` нужны?
   - Как обрабатывать system prompts?

5. **Тестирование:**
   - Насколько глубокими должны быть тесты?
   - Нужно ли тестировать миграцию данных?

## 📊 Метрики успеха

### **Критерии успешной миграции:**
- [ ] Все существующие пользователи сохранены
- [ ] Все существующие чаты перенесены
- [ ] История сообщений доступна
- [ ] Бот работает без сбоев
- [ ] Производительность не ухудшилась
- [ ] Все тесты проходят

### **Критерии функциональности:**
- [ ] Новый пользователь создает TelegramUser и Chat
- [ ] Существующий пользователь использует существующие записи
- [ ] Welcome message создается в Chat.messages
- [ ] ruby_llm интеграция работает корректно

## 🔄 План отката

Если что-то пойдет не так:
1. Откатить миграции (`rails db:rollback`)
2. Восстановить бэкап базы данных
3. Включить старую версию контроллера
4. Проверить работоспособность

## 📝 Результаты обсуждения

*Здесь будут记录 результаты обсуждения и принятые решения*

---

**История изменений:**
- 27.10.2025 v1.0: Создание протокола имплементации
  - Определена архитектура User/Chat/Message
  - Разработан двухуровневый подход к фильтрам
  - Выделены риски и вопросы для обсуждения