# Gems Documentation

Этот каталог содержит исчерпывающую документацию по критически важным gems проекта Valera.

## 📚 Документация доступна для:

### 🔷 telegram-bot
**Расположение:** `./telegram-bot/`

Документация по созданию Telegram ботов с использованием gem `telegram-bot-rb`.

**Ключевые ресурсы:**
- [README.md](./telegram-bot/README.md) - Основная документация и quick start
- [API Reference](./telegram-bot/api-reference.md) - Полный справочник по API
- [Architecture Patterns](./telegram-bot/patterns.md) - Паттерны и лучшие практики
- [Code Examples](./telegram-bot/examples/) - Готовые примеры кода

**Примеры кода:**
- `advanced-handlers.rb` - Продвинутая обработка с state management

### 🔷 ruby_llm
**Расположение:** `./ruby_llm/`

Документация по работе с языковыми моделями через gem `ruby_llm`.

**Ключевые ресурсы:**
- [README.md](./ruby_llm/README.md) - Основная документация и конфигурация
- [API Reference](./ruby_llm/api-reference.md) - Полный справочник по API
- [Architecture Patterns](./ruby_llm/patterns.md) - Паттерны и лучшие практики
- [Code Examples](./ruby_llm/examples/) - Готовые примеры кода

**Примеры кода:**
- `basic-chat.rb` - Базовый чат и взаимодействие с LLM
- `tool-calls.rb` - Использование инструментов и function calling
- `configuration.rb` - Примеры конфигурации для разных сценариев


## 📖 Для AI агента

Эта документация создана для обеспечения AI агента полной информацией о gems при планировании и реализации задач.

### Инструкции для AI агента:

1. **При планировании задач с telegram-bot:**
   - Изучить паттерны в `telegram-bot/patterns.md`
   - Адаптировать подходящие примеры из `telegram-bot/examples/`
   - Использовать API reference для конкретных методов

2. **При планировании задач с ruby_llm:**
   - Выбрать подходящую модель и конфигурацию
   - Использовать паттерны из `ruby_llm/patterns.md`
   - Адаптировать примеры из `ruby_llm/examples/`

3. **При создании планов имплементации:**
   - Включать релевантные примеры кода
   - Ссылаться на конкретные разделы документации
   - Использовать best practices из документации

## 🔗 Связанные ресурсы

- [CLAUDE.md](../../CLAUDE.md) - Основная документация проекта
- [Application Configuration](../../config/configs/application_config.rb) - Конфигурация приложения
- [Rails Initializers](../../config/initializers/) - Инициализаторы Rails

---

**Последнее обновление:** #{Time.now.strftime('%d.%m.%Y %H:%M')}