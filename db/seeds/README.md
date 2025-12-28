# LLM-генератор диалогов

Скрипт для автоматической генерации реалистичных диалогов через общение двух LLM моделей.

## Быстрый старт

```bash
# Показать план без генерации
bin/generate_demo_dialogs --dry-run

# Сгенерировать 10 тестовых диалогов
bin/generate_demo_dialogs --count 10

# Сгенерировать 100 диалогов (по умолчанию)
bin/generate_demo_dialogs
```

## Использование

```bash
bin/generate_demo_dialogs [options]

Опции:
  -c, --count COUNT     Количество диалогов (default: 100)
  -p, --profile PROFILE Только для конкретного профиля
  -d, --dry-run         Показать план без генерации
  -o, --output FILE     Имя выходного файла
  -m, --model MODEL     Модель LLM (default: gpt-4o-mini)
  -v, --verbose         Подробный вывод
  -h, --help            Справка
```

## Примеры

```bash
# Генерация только для активных клиентов
bin/generate_demo_dialogs --profile active_client --count 20

# С указанием выходного файла
bin/generate_demo_dialogs --output my_dialogs.yml

# С другой моделью
bin/generate_demo_dialogs --model gpt-4o --count 10
```

## Профили клиентов

| Профиль | Доля | Booking Rate | Сообщений |
|---------|------|--------------|-----------|
| `active_client` | 20% | 90% | 10-20 |
| `one_time_client` | 50% | 50% | 5-12 |
| `just_asking` | 20% | 0% | 3-6 |
| `urgent_client` | 10% | 85% | 6-10 |

Профили хранятся в `db/seeds/client_profiles/`.

## Архитектура

```
┌─────────────────┐     ┌─────────────────┐
│  Модель-клиент  │────▶│ Модель-ассистент│
│  (с профилем)   │◀────│ (system prompt) │
└─────────────────┘     └─────────────────┘
         │
         ▼
   ┌───────────┐
   │ YAML файл │
   └───────────┘
```

1. Модель-клиент получает профиль поведения
2. Модель-ассистент использует системный промпт из `data/system-prompt.md`
3. Они обмениваются N сообщениями
4. Результат сохраняется в `db/seeds/generated_dialogs/`

## Формат выходного файла

```yaml
metadata:
  generated_at: "2025-01-01T12:00:00+03:00"
  model: "gpt-4o-mini"
  total_dialogs: 100
  profiles:
    active_client: 20
    one_time_client: 50
    just_asking: 20
    urgent_client: 10

dialogs:
  - id: "uuid-1234"
    profile: "active_client"
    generated_at: "2025-01-01T12:00:00+03:00"
    message_count: 12
    booking_expected: true
    messages:
      - role: "user"
        content: "Добрый день! Хочу записаться на ТО"
        timestamp: "2025-01-01T12:00:01+03:00"
      - role: "assistant"
        content: "Здравствуйте! С удовольствием помогу..."
        timestamp: "2025-01-01T12:00:02+03:00"
```

## Оценка стоимости

| Параметр | Значение |
|----------|----------|
| 100 диалогов | ~2000 API вызовов |
| Модель gpt-4o-mini | $0.15-0.60 |
| Время генерации | 30-60 минут |

## Файлы

```
db/seeds/
├── client_profiles/           # Профили клиентов
│   ├── active_client.md
│   ├── one_time_client.md
│   ├── just_asking.md
│   └── urgent_client.md
├── generated_dialogs/         # Сгенерированные диалоги
│   └── dialogs_TIMESTAMP.yml
└── README.md                  # Этот файл
```

## Связанные задачи

- [#132](https://github.com/dapi/valera/issues/132) — MVP с ручными диалогами
- [#135](https://github.com/dapi/valera/issues/135) — LLM-генератор (этот скрипт)
