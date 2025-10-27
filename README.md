# AI-бот Валера для записи на кузовной ремонт и покраску

[![CI](https://github.com/dapi/valera/actions/workflows/ci.yml/badge.svg)](https://github.com/dapi/valera/actions/workflows/ci.yml)

> **Open-source проект** для создания AI-powered Telegram ботов для автосервисов кузовного ремонта

---

## 🎯 О проекте

**Valera** - это open-source Ruby on Rails проект, который позволяет **владельцам автосервисов** запускать своих AI-powered Telegram ботов для автоматизации консультаций и записи клиентов.

### Для кого этот проект?

**Целевая аудитория проекта:**
- 🏢 **Владельцы автосервисов** - хотят запустить AI-бота для своего бизнеса
- 👨‍💻 **Разработчики** - хотят контрибьютить в open-source
- 🚀 **Предприниматели** - хотят создать решение на базе проекта

> **О терминологии:** ПРОЕКТ = этот репозиторий, ПРОДУКТ = созданный AI-бот.
> Подробнее см. [Глоссарий](docs/domain/glossary.md#фундаментальная-терминология-проекта)

---

## ✨ Что можно создать с этим проектом

### Возможности созданного AI-бота (продукта):

**Для клиентов автосервиса:**
- 🤖 Естественный диалог - общение как с живым консультантом
- 📸 AI-анализ повреждений - оценка стоимости по фото
- 🔍 Визуальная оценка - определение типов повреждений
- 📋 Работа со страховыми - помощь с ОСАГО/КАСКО
- 📊 Фотоотчеты - прозрачность на каждом этапе
- ⚡ Быстрая запись - на бесплатный осмотр

**Для владельцев автосервисов:**
- 📈 Увеличение конверсии - до 40% из фото в заявку
- 💰 Высокий средний чек - фокус на кузовном ремонте
- 🤝 Снижение нагрузки - автоматизация консультаций
- 🎯 Страховые клиенты - автоматизация ОСАГО/КАСКО
- 📊 Аналитика - полная история взаимодействий

> **Бизнес-метрики продукта:** См. [docs/product/business-metrics.md](docs/product/business-metrics.md)

---

## 🚀 Быстрый старт

**Полное руководство по установке:** [docs/development/SETUP.md](docs/development/SETUP.md)

**Краткие требования:**
- Ruby 3.4+, PostgreSQL 14+
- Telegram Bot Token, AI API key

**Быстрая установка:**
```bash
git clone https://github.com/dapi/valera.git
cd valera
bundle install
bin/rails db:create db:migrate
bin/rails telegram:bot:poller
```

**Production deployment:** [docs/deployment/README.md](docs/deployment/README.md)

---

## 🛠️ Технологии

**Основной стек:** Ruby on Rails 8.1 + ruby_llm + Telegram + PostgreSQL

**AI провайдеры:** Anthropic Claude, DeepSeek (OpenAI, GigaChat в разработке)

**Подробнее о технологиях:** [docs/development/stack.md](docs/development/stack.md)

---

## 📸 Пример диалога

```
Клиент: Здравствуйте, у меня вмятина на двери
Валера: Добрый день! Пришлите фото повреждения,
        и я сделаю предварительную оценку стоимости.
```

---

## 🗺️ План развития

**Полный roadmap:** [docs/ROADMAP.md](docs/ROADMAP.md)

**Текущий статус:** Phase 2 - AI-анализ фотографий повреждений и визуальная оценка стоимости

---

## 🤝 Для контрибьюторов

Мы приветствуем контрибьюции!

**Начать здесь:**
- **[Product Constitution](docs/product/constitution.md)** - требования к продукту
- **[Development Guide](docs/development/README.md)** - руководство для разработчиков
- **[Open Issues](https://github.com/dapi/valera/issues)** - задачи для участия

**Полная документация:** [docs/INDEX.md](docs/INDEX.md)

---

## 📚 Документация

**Основная документация:** [docs/INDEX.md](docs/INDEX.md)

**Ключевые разделы:**
- **[Development Guide](docs/development/README.md)** - для разработчиков
- **[Product Constitution](docs/product/constitution.md)** - требования к продукту
- **[Глоссарий](docs/domain/glossary.md)** - терминология проекта

---

## 📄 Лицензия

(TODO: добавить лицензию)

---

## 💬 Контакты

- **Issues:** [GitHub Issues](https://github.com/dapi/valera/issues)
- **Discussions:** [GitHub Discussions](https://github.com/dapi/valera/discussions)

---

**Версия проекта:** 0.2.0 (MVP+)
**Статус:** Active Development
