# CLAUDE.md

**Critical Rules для Claude Code при работе с проектом Super Valera**

**Quick Start:** @docs/README.md

## ⚙️ Critical Rules

🚨 **Models:** ВСЕГДА `rails generate model` (модель + миграция вместе)
🚨 **Error Handling:** `ErrorLogger` вместо `Bugsnag.notify()` — проект использует Bugsnag для error tracking
🚨 **Fatal DB Errors:** НЕ ловить фатальные ошибки БД (`ActiveRecord::ConnectionNotEstablished`, `PG::ConnectionBad`, `ActiveRecord::QueryCanceled`) — это инфраструктурные проблемы, ожидаемое поведение: 500 ошибка + лог в Bugsnag. Ловить только `ActiveRecord::StatementInvalid` для graceful degradation бизнес-логики.
🚨 **Configuration:** Только `anyway_config`, никаких `.env*` файлов
🚨 **Documentation:** НЕ архивировать FIP/US/TSD документы из `docs/requirements/`
🚨 **Testing:** Без `File.write/File.delete` и изменения ENV в тестах
🚨 **Jobs/SolidQueue:** НЕ использовать символы `:exponentially_longer` или `:polynomially_longer` в `retry_on` — SolidQueue их не поддерживает. Используй lambda: `wait: ->(executions) { (executions**4) + 2 }`
🚨 **Порты worktree:** НЕ проверяй занятость портов вручную — просто запускай сервер через `direnv exec . dip rails s`. Порт выбирается автоматически через `port-selector` в `.envrc`.
🚨 **Остановка сервера:** Используй `direnv exec . dip down` для остановки. НЕ использовать `pkill` — это не очищает Docker контейнеры и оставляет висящие ресурсы.
🚨 **Demo/Production авторизация:** НИКОГДА не устанавливать/менять пароли на demo.supervalera.ru или production. Если форма предлагает "Установить пароль" — НЕ делать этого, а спросить у пользователя актуальные креды.
🚨 **Slim + Tailwind arbitrary values:** НЕ использовать shorthand-синтаксис `.class-[value]` в Slim — парсер обрезает класс на `[`. Вместо `.max-w-[70%]` используй `div class="max-w-[70%]"` или inline style `div style="max-width: 70%"`. См. [issue #165](https://github.com/dapi/valera/issues/165).

## 🚀 Запуск проекта в новом каталоге (worktree)

При работе в новом git worktree или свежем клоне:

```bash
# 1. Первоначальная настройка (postgres, redis, зависимости, база)
dip provision

# 2. Seed данные (создаёт demo tenant и тестовых пользователей)
direnv exec . dip rails db:seed

# 3. Запуск dev сервера
direnv exec . dip rails s  # или direnv exec . dip dev для полного стека
```

**ВАЖНО для AI-агентов:**
- Все команды `dip` запускать через `direnv exec .` для прокидывания переменных окружения
- Для URL использовать значение `$URL` из окружения: `direnv exec . bash -c 'echo $URL'`
- НЕ выдумывать домены (lvh.me, localhost) — использовать только `$URL`

**URLs:**
- **Admin панель:** `http://admin.$URL/login`
- **Tenant Dashboard:** `http://demo.$URL/` (demo tenant из seeds)

**Креды для dev окружения:**

| Роль | Email | Пароль |
|------|-------|--------|
| Admin (superuser) | из env var ADMIN_EMAIL или`admin@example.com` | из env var ADMIN_PASSWORD или `password` |
| Tenant Owner | из env var TENANT_DEMO_USER_EMAIL или `tenant@super-valera.ru` | из env var TENANT_DEMO_USER_PASSWORD или`password` |

**Отдельные команды (всегда через `direnv exec .`):**
- `direnv exec . dip rails s` — только Rails server
- `direnv exec . dip rails c` — консоль
- `direnv exec . dip test` — тесты
- `direnv exec . dip psql` — PostgreSQL консоль

### 🎭 Авторизация через Playwright MCP

При необходимости авторизоваться в Admin/Dashboard через Playwright:

```
1. browser_close                    # Рекомендуется для чистого состояния
2. browser_navigate → login URL
3. browser_fill_form → email + password
4. browser_click → submit button
```

**Примечание:** Session cookies разделены по портам (`_session_3010`, `_session_3013`), поэтому параллельные worktree не конфликтуют. `browser_close` рекомендуется для чистого состояния, но не обязателен.

## 📸 Скриншоты для документации

Генерация скриншотов dashboard для PR и документации:

```bash
# Установка зависимостей (один раз)
npm install
npx playwright install chromium

# Запуск сервера (в отдельном терминале)
bin/rails server

# Генерация скриншотов (7 дней + 30 дней)
bin/rails screenshots:dashboard
```

Скриншоты сохраняются в `docs/screenshots/`.

**Требования:** Node.js, Playwright, seed данные (`bin/rails db:seed`), запущенный сервер.

## 📋 Ссылки

**Process:** @docs/FLOW.md | **Development:** @docs/development/README.md | **Error Handling:** @docs/patterns/error-handling.md | **Architecture:** @docs/architecture/decisions.md | **Gems:** @docs/gems/README.md

## 🎯 Работа с требованиями (Critical для AI-агентов)

### 📁 Структура управления требованиями

**ROADMAP.md** - Активные фазы разработки
- Только запланированные к реализации фазы
- Четкие timeline и зависимости
- Текущий фокус: Phase 1 → Phase 1.5 → Phase 2 → Phase 3 → Phase 4

**BACKLOG.md** - Очередь на рассмотрение
- Утвержденные идеи с бизнес-ценностью, но без конкретных сроков
- Требуют уточнения или дополнительного анализа
- Ежемесячные review для перемещения в ROADMAP

**ICEBOX.md** - Отложенные indefinitely
- "Maybe someday" идеи с низким приоритетом
- Технически сложные или рискованные концепции
- Ежеквартальные review при изменении обстоятельств

**DEPRECATED.md** - Архив отклоненных идей
- Признанные нецелесообразными решения
- Исторический контекст для избежания повторения ошибок
- Lessons learned и успешные отклонения

### 🤖 Инструкции для AI-агентов

#### При работе с User Stories и требованиями:

1. **ВСЕГДА проверять статус документа** перед началом работы:
   - Если статус "Draft" → сначала уточни требования у пользователя
   - Если статус "Ready" или "In Progress" → можно начинать реализацию
   - Если статус "Completed" → не трогать, создай новую версию при необходимости

2. **Для новых требований:**
   - Определи категорию: User Story (US), FIP, или Technical Design (TSD)
   - Создай в соответствующей папке `docs/requirements/{user-stories,fip,tsd}/`
   - Используй шаблоны из `docs/requirements/templates/`
   - Установи начальный статус "Draft"

3. **Для существующих требований:**
   - НЕ изменяй документы со статусом "Completed" или "Production"
   - Для активных документов обновляй статусы следуя workflow:
     ```
     Draft → BusinessAnalyzes → SystemAnalyzes → Ready → In Progress → Completed → Production
     ```

4. **При работе сROADMAP:**
   - Функции из ROADMAP.md имеют высший приоритет
   - BACKLOG.md можно предлагать к перемещению в ROADMAP при наличии ресурсов
   - ICEBOX.md - только при стратегическом изменении приоритетов

5. **Процесс создания новых требований:**
   ```
   Идея → Обсуждение → Draft документ → Business Analyzes → System Analyzes → Ready → Implementation
   ```

### 🔄 Workflow принятия решений

**Новая функция появляется:**
1. Создать Draft документ в соответствующей категории
2. Провести бизнес-анализ (ценность, ROI, метрики)
3. Провести системный анализ (сложность, риски, зависимости)
4. Определить приоритет и место в структуре:
   - Высокий приоритет + четко → ROADMAP.md
   - Есть ценность + timing неясен → BACKLOG.md
   - Интересно + низкий приоритет → ICEBOX.md
   - Плохая идея → DEPRECATED.md

**Регулярные ревью:**
- **Ежемесячно (1-го числа):** BACKLOG review
- **Ежеквартально:** ICEBOX review
- **При изменениях:** ROADMAP-ARCHIVE.md обновляется


# Production & Kubernetes доступ

**Кластер:** goga-office (K8s context: `goga-office`; infra target `goga-infra`)
**Namespace:** `valera-production`
**Deployment:** `valera`
**Container:** `ror`

## Подключение к production базе для диагностики

Креды для подключения к production postgresql базы для диагностики находятся в
переменных окружения: PRODUCTION_VALERA_DATABASE_USERNAME, PRODUCTION_VALERA_DATABASE_HOST, PRODUCTION_VALERA_DATABASE_PASSWORD, PRODUCTION_VALERA_DATABASE_NAME

используй их для подключения через psql

## Прямой доступ через kubectl

🚨 **Не запускай Rails внутри веб-контейнера** (`kubectl exec deploy/valera -- rails runner|console`).
Второй процесс Rails не помещается в лимит памяти контейнера (278Mi): OOM убивает
весь контейнер вместе с Puma, и supervalera.ru падает (так было 2026-09-26).
Ruby-код на production выполняй только через `bin/production-rails-runner` — он
поднимает одноразовый под с тем же образом и окружением и удаляет его после работы.

```bash
# Rails Runner (одноразовый под)
bin/production-rails-runner 'puts User.count'

# Проверка подов
kubectl --context=goga-office -n valera-production get pods

# Логи
kubectl --context=goga-office -n valera-production logs deploy/valera -c ror --tail=100
```

# Авторизация в SaaS для диагностики в разработке

Доступ в administarte осуществляется через playwright mcp по адресу указанном в переменной окружения
ADMIN_URL, а доступы бери из переменных окружеия ADMIN_EMAIL, ADMIN_PASSWORD

# Окружения

- **Production:** `supervalera.ru` — боевой сервер
- **Development:** $_URL, — development сервер (SSL self-signed, нужно принять сертификат)

# Диагностика

- Логи из production смотреть через `make production-logs`
- Запустить rails runner на production через `bin/production-rails-runner`

## Production Rails Runner

Скрипт `bin/production-rails-runner` для выполнения Ruby-кода на production:

```bash
# Простые команды
bin/production-rails-runner 'User.count'
bin/production-rails-runner 'puts Tenant.pluck(:key)'

# Команды с ! и спецсимволами — через stdin (решает проблему экранирования bash)
echo 'DemoDataSeeder.send("seed!", Tenant.find_by_key(:demo))' | bin/production-rails-runner -
echo 'require_relative "db/seeds/demo_data"; DemoDataSeeder.send("seed!", Tenant.first)' | bin/production-rails-runner -
```

**Важно:** Для методов с `!` используй `send("method!", args)` через stdin, иначе bash экранирует `!`.

### 🚨 Critical Rules для требований

🚨 **НЕ изменять** документы со статусом "Completed" или "Production"
🚨 **ВСЕГДА** следовать workflow статусов (не перескакивать через этапы)
🚨 **НЕ архивировать** активные документы - используй префикс `[DEPRECATED]`
🚨 **ИСПОЛЬЗУЙ** шаблоны из `docs/requirements/templates/` для новых документов
🚨 **ОБНОВЛЯЙ** ROADMAP-ARCHIVE.md при значительных изменениях приоритетов
- При изменении конфигурации всегда отражай это в CHANGES.md для SRE-инженера
/file:.claude-on-rails/context.md
