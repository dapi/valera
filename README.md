# Супер Валера

AI-ассистент автосервиса в Telegram: консультирует по услугам и прайсу, собирает контакты и передаёт заявку менеджеру.

[Сайт](https://supervalera.ru/) · [Демо-бот](https://t.me/super_valera_demo_bot) · [Тарифы](https://supervalera.ru/price)

## Текущие возможности

- Текстовый диалог на русском с учётом информации и прайса автосервиса.
- Отдельные боты и данные автосервисов, личный кабинет с клиентами, заявками и историей чатов.
- Роли сотрудников, передача диалога менеджеру и возврат боту.
- Приглашения по ссылке и email, восстановление пароля по email и самостоятельная смена пароля в ЛК.
- Уведомления менеджеру, аналитика и учёт использования LLM.

Фотоанализ отключён. Бот собирает заявку и удобное время; подтверждение визита остаётся за автосервисом. Гарантированный рост конверсии или фиксированное время ответа не заявляются без измерений.

## Разработка

Ruby 3.4.8, Rails 8.1, PostgreSQL, GoodJob, Hotwire и RubyLLM. Настройки и секреты — согласно [CLAUDE.md](CLAUDE.md) и [руководству](docs/development/README.md).

```bash
git clone git@github.com:dapi/valera.git
cd valera
direnv exec . dip provision
direnv exec . dip rails db:seed
direnv exec . dip rails s
```

Порт и URL выбираются окружением. Для тестов: `direnv exec . dip test`.

## Эксплуатация и состояние

Код приложения — `~/code/valera`, конфигурация production — `~/code/brandymint/infra`. Инструкция запуска диагностики: [CLAUDE.md](CLAUDE.md). Production LLM: DeepSeek Flash через частный gateway; [маршрутизация](docs/deployment/telegram-gateway.md).

[Актуальное состояние и очередь](docs/product/current-status.md) · [документация](docs/INDEX.md) · [требования к боту](docs/product/constitution.md) · [правила участия](CONTRIBUTING.md).

Версия приложения хранится в `.semver`. Старые roadmap и требования отражают состояние на дату документа; они не заменяют текущий обзор.
