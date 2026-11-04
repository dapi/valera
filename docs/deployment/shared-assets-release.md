# 0.45.0: доставка email и непрерывные ассеты

## Email: фактическое получение

04.11.2026 в 19:35 UTC через production AccountMailer/SMTP отправлены два явно
помеченных теста на собственные адреса. Пользователи не сохранялись; тестовые
ссылки не соответствуют реальным аккаунтам.

Маркер `SVMAIL-20261104193503-d1169a` найден в Inbox обоих адресов:

| Получатель | Envelope | Message-ID |
| --- | --- | --- |
| danil@brandymint.ru | 48862 | 6aeb88e81e82_1a187547c@valera-runner-20261104223455-6008.mail |
| danilpismenny@yandex.ru | 9589 | 6aeb88e91e772_1a18755af@valera-runner-20261104223455-6008.mail |

Проверены envelope-поля и совпадение Message-ID с результатом Mail::SMTP.
Предыдущий запрос Himalaya с кавычками вокруг subject искал буквальные
кавычки. Рабочая форма: `envelope search -a <account> -m Inbox --json subject <marker>`.
SMTP менять не требуется. Тесты третьим лицам не отправлялись.

## Ассеты

Причина 404: HTML новой версии мог направлять запрос CSS на прежнюю реплику,
в image которой нового digest ещё нет. Shared middleware раздаёт файлы всех
версий с retained PVC. Publisher сверяет полные SHA256, не перезаписывает
объекты, публикует через атомарный hard link; manifest каждой версии остаётся
отдельным. Init заканчивается до готовности приложения. Web mount read-only.

Первый переход использует manifest 0.44.2 и seed её immutable image; после
полной замены старых pods manifest override и seed удаляются. Новые версии
публикуют свой комплект автоматически до ready.

Конфигурация и операционный runbook находятся в `~/code/brandymint/infra`.
PVC `valera-production/valera-assets`, 1Gi, `raid-office2-retain`, Helm keep.
Storage привязан к office2; автоматического удаления старых файлов нет.
Откат на image без shared middleware требует отдельной проверки asset set.

## Локальная проверка

- 910 тестов, 2793 assertions, 0 failures/errors.
- RuboCop: 5 изменённых Ruby-файлов без нарушений.
- Brakeman: 0 warnings/errors, 2 прежних ignored; исключены `docs/`,
  содержащие примеры vendored gems. bundler-audit с обновлённой базой: 0.
- Отдельный boot production с включённым middleware: GET probe=200;
  Propshaft использует bootstrap manifest и прежний tailwind-31d1ccf2.css.
- GET/HEAD/Range; отсутствующие файлы, manifest, traversal и POST передаются
  основному приложению.
- Четыре одновременных publisher: одинаковый результат, без потери данных.
- Повторная публикация идемпотентна; коллизия и mutable-имя отклонены;
  исходный объект сохранён, manifest не попадает в публичный каталог.

## Production

- Image `registry.brandymint.ru/dapi/valera:0.45.0`, source `826930c`,
  manifest-list digest `sha256:c2dc806bf8d6492072d51ad0df318da33814229d72f0b132e8cc7300bfa5e2e9`.
- Bootstrap rollout: release Valera revision 24, publisher 77 files / 6002662
  bytes. Все web pods заменены до удаления старого manifest override.
- После перехода revision 25 использует локальный `/rails/public/assets/.manifest.json`.
  Seed-init и bootstrap EmptyDir удалены. PVC Bound, web mount read-only.
- Дополнительный контролируемый rollout, release revision 26, завершён
  с annotation shared-assets=v1:
  одновременно Ready `valera-5687574575-c6swb` и `valera-59d787dcf6-gm7dk`.
  В обоих local public/assets контрольного файла нет. Оба ответили GET/HEAD
  200; пустое тело HEAD; cache-control public, max-age=31536000, immutable.
- Path `/assets/rollout-probe-44ae5b3a6240690d.css`, SHA256
  `44ae5b3a6240690db8cab2444cb4640e52ebe90d0824e0ac811c674c0e97f112`.
  Файл опубликован отдельным native operator pod без Rails, секретов или
  Service labels; pod удалён. Публичный HTTPS вернул тот же SHA256/200.
- Range проверен напрямую через Puma :3001: обе реплики вернули 206 и `/*`
  для bytes=0-1. Перед Rails работает Thruster: на cache hit он может вернуть
  200 с полным файлом на Range-запрос; это не является 404 или повреждением.
- Первый замер overlap прервался из-за TLS timeout Kubernetes API, следующий
  потребовал отделить Range-ответ Puma от поведения Thruster cache. Поэтому
  выполнен дополнительный rollout; успешный замер выше получен при двух Ready pods.
- 180 последовательных загрузок главной страницы и CSS через public HTTPS:
  180/180 HTML успешны, 180/180 CSS=200, ошибок нет.
- Headless Chromium: `/`, `/price`, `/login`, `/password_resets/new` на ширинах
  320, 390, 1280 px — 12/12 HTTP 200, CSS загружен, overflow=false;
  pageerrors и requestfailed отсутствуют.
- Production runner: версия 0.45.0, Rails 8.1.4.1; deepseek-flash через private
  LiteLLM; inbox pending=0, failed=0. Demo/kuznik: API ok, pending updates=0,
  webhook errors отсутствуют.
- GoodJob probe `46449b1b-245a-4253-a1bd-165eabeffd94` завершён настоящим
  worker, error=false; поллинг внутри ActiveRecord::Base.uncached.
- Infra: bootstrap `556c05d4`, окончательная конфигурация и operator probe
  `e6546b48`. Пользовательские пароли, права и Telegram-переписка не менялись.

Открытые работы проекта: [текущее состояние](../product/current-status.md).
