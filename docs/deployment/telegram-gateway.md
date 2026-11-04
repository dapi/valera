# Telegram и LLM gateway

## Production contract

Deployment-конфигурация принадлежит `~/code/brandymint/infra`:
`values/valera.yaml.gotmpl` и `values/goga-office/valera.yaml.gotmpl`.
Production работает в `goga-office`, namespace `valera-production`.

- `TELEGRAM_API_PROXY_URL`: HTTP CONNECT-прокси для всех
  `Telegram::Bot::Client`, включая платформенный и динамические tenant-клиенты.
  В production используется `http://192.168.88.10:8119`, далее офисный SOCKS5.
  Это не глобальный HTTP proxy. Без настройки сохраняется штатный транспорт.
- Telegram: connect timeout 10 s, send/receive timeout 30 s.
- `LLM_PROVIDER=openai`, `LLM_MODEL=deepseek-flash`.
- `OPENAI_API_BASE=http://litellm.litellm.svc.cluster.local:4000/v1`,
  `OPENAI_API_KEY=local` — private gateway не требует клиентского секрета.
  Upstream API key остаётся в gateway.
- Fallback-переменные пусты: скрытого прямого платного маршрута нет.

Alias `deepseek-flash` в gateway использует текущую DeepSeek Flash;
на 04.11.2026 это V4.1-Flash-1017. Thinking отключён на стороне gateway,
чтобы сократить задержку и не требовать reasoning history при tool calls.
Источник: https://api-docs.deepseek.com/quick_start/pricing/ и
https://api-docs.deepseek.com/guides/thinking_mode/.

## Проверка

После rollout проверить `/up`, `getMe` и `getWebhookInfo` через штатные
клиенты обоих ботов, затем синтетический LLM-запрос с tool calling через
тот же RubyLLM provider. Не выводить bot tokens, секретный маршрут
платформенного webhook или полный payload реальных клиентов.

Для проверки транспортной настройки и регрессий:

```sh
bin/rails test test/lib/telegram/client_transport_test.rb \
  test/controllers/telegram/webhook_controller_test.rb \
  test/services/manager/telegram_message_sender_test.rb \
  test/services/llm_fallbacks_test.rb
```

Откат: через infra вернуть предыдущий image tag и прежние model settings.
Базу и данные диалогов при откате не удалять.
