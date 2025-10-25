# Implementation Plan: US-001 Telegram Auto Greeting

**Дата создания:** 26.10.2025
**Статус:** Ready for Implementation
**Версия:** 1.0
**Technical Specification:** TS-001-telegram-welcome-message.md

## 📋 Обзор плана

План реализации системы приветствия новых пользователей в Telegram боте "Валера" для автосервиса "Кузник" с использованием гибридного архитектурного подхода (шаблон + LLM).

## 🎯 Ключевые архитектурные решения

### Hybrid Architecture Exception
- **Welcome Message:** Конфигурируемый шаблон (производительность < 200ms)
- **Последующие сообщения:** LLM с System-First подходом
- **Соответствие Product Constitution:** Dialogue-Only взаимодействие

### Технический стек
- **telegram-bot-rb:** Основной gem для Telegram API
- **anyway_config:** Конфигурация путей к шаблонам
- **ruby_llm:** Интеграция с Chat/Message моделями
- **Rails 8.1:** Основной фреймворк

## 🔧 Порядок реализации

### Фаза 1: Базовая инфраструктура

#### 1.1 Обновление ApplicationConfig
**Что добавить:**
```ruby
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
```

**Почему:** Централизованная логика загрузки шаблона с graceful degradation

#### 1.2 Расширение TelegramUser модели
**Что добавить:**
```ruby
def name
  [first_name, last_name].compact.join(' ').presence || "@#{username}"
end
```

**Почему:** Единый метод получения имени пользователя для интерполяции

### Фаза 2: Сервисы отправки

#### 2.1 Создание WelcomeService
**Основные методы:**
- `send_welcome_message(telegram_user, controller)`
- `interpolate_template(template, telegram_user)`
- Логирование отправки
- Обработка ошибок

**Почему:** Изоляция логики приветствия от контроллера

#### 2.2 Интеграция с существующими моделями
**Chat модель:**
- Автоматическое создание при первом приветствии
- Интеграция с ruby_llm `acts_as_chat`

**Почему:** Seamless переход к LLM после приветствия

### Фаза 3: Обновление контроллера

#### 3.1 Модификация Telegram::WebhookController
**Что изменить:**
- Обновить `start!` метод для использования WelcomeService
- Сохранить `message` method для LLM обработки
- Добавить логирование

**Почему:** Реализация Hybrid Architecture подхода

### Фаза 4: Локализация и ошибки

#### 4.1 Настройка I18n
**Добавить в config/locales/ru.yml:**
```yaml
ru:
  telegram:
    welcome_message:
      default: |
        🔧 Здравствуйте! Я Валера - AI-ассистент по кузовному ремонту...
```

**Почему:** Fallback сообщение при недоступности шаблона

#### 4.2 Обработка ошибок
- Graceful degradation при отсутствии файла
- Retry механизм для временных сбоев
- Детальное логирование ошибок

**Почему:** Надежность системы согласно требованиям

### Фаза 5: Тестирование

#### 5.1 Unit тесты
- WelcomeService логики
- Template interpolation
- TelegramUser.name метод
- ApplicationConfig методов

#### 5.2 Integration тесты
- End-to-end webhook flow
- Database интеграция
- Template loading

#### 5.3 E2E тесты
- New user welcome flow
- Template с username интерполяцией
- Error handling сценарии

#### 5.4 Performance тесты
- Время ответа < 200ms
- Нагрузочное тестирование 100+ пользователей

### Фаза 6: Валидация и мониторинг

#### 6.1 Проверка соответствия Product Constitution
- Dialogue-Only взаимодействие (нет кнопок)
- Hybrid Architecture подход
- Russian Language Context

#### 6.2 Мониторинг и метрики
- welcome_messages_sent count
- welcome_processing_time metrics
- template_load_errors tracking

## 📊 Критерии успеха

### Функциональные критерии
- [ ] Welcome message отправляется новым пользователям
- [ ] Template интерполяция работает с username
- [ ] Последующие сообщения обрабатываются LLM
- [ ] Ошибки обрабатываются gracefully

### Performance критерии
- [ ] Время ответа < 200ms
- [ ] Поддержка 100+ одновременных пользователей
- [ ] 99.9% доступность

### Качественные критерии
- [ ] Unit тест покрытие > 90%
- [ ] Все integration тесты проходят
- [ ] E2E тесты на ключевые сценарии
- [ ] Соответствие Product Constitution

## 🚨 Риски и митигация

| Риск | Вероятность | Митигация |
|------|-------------|-----------|
| Template файл не найден | Низкая | Graceful degradation с I18n |
| Telegram API недоступен | Средняя | Retry механизм |
| Высокая нагрузка | Средняя | Оптимизация запросов |
| Ошибка интерполяции | Низкая | Safe interpolation methods |

## 🔗 Связанные документы

- **User Story:** US-001-telegram-auto-greeting.md
- **Technical Specification:** TS-001-telegram-welcome-message.md
- **Product Constitution:** docs/product/constitution.md
- **Feature Description:** feature-telegram-welcome-experience.md

## 📝 Заметки по реализации

1. **ВАЖНО:** Не нарушать Product Constitution - Dialogue-Only подход
2. **ВАЖНО:** Соблюдать Hybrid Architecture - шаблон для welcome, LLM для остального
3. **ВАЖНО:** Все тесты должны быть безопасными (File operations запрещены)
4. **ВАЖНО:** Логирование не мокается в тестах
5. **ВАЖНО:** Использовать существующие модели (TelegramUser, Chat, Message)

## ✅ Definition of Done

- [ ] Все задачи из плана выполнены
- [ ] Все тесты проходят
- [ ] Performance требования удовлетворены
- [ ] Product Constitution соблюден
- [ ] Код готов к production deploy
- [ ] Документация обновлена
- [ ] Implementation plan сохранен в .protocols/

---

**Следующие шаги после завершения:**
1. Testing на staging с реальными Telegram аккаунтами
2. Production deploy
3. Мониторинг метрик
4. Сбор feedback от пользователей
5. Планирование следующих улучшений (Phase 2)