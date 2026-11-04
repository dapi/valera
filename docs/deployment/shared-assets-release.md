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
- GET/HEAD/Range; отсутствующие файлы, manifest, traversal и POST передаются
  основному приложению.
- Четыре одновременных publisher: одинаковый результат, без потери данных.
- Повторная публикация идемпотентна; коллизия и mutable-имя отклонены;
  исходный объект сохранён, manifest не попадает в публичный каталог.

## Production

В процессе: bootstrap rollout, затем переход на локальный manifest и
проверка файла новой версии через обе одновременно работающие реплики.
