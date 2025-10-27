# 🏢 SaaS Overview - Общие сведения

**Создан:** 27.10.2025
**Статус:** Active Documentation
**Версия:** 1.0
**Автор:** Product Team

## 📋 Что такое Valera SaaS?

Valera — это **Software as a Service (SaaS) платформа** для автоматизации кузовных автосервисов через AI-powered Telegram ботов.

### Ключевые характеристики SaaS:

**1. Multi-Tenancy:**
- Один экземпляр платформы обслуживает множество клиентов
- Каждый автосервис = отдельный Account с изолированными данными
- Один пользователь (TelegramUser) может работать с разными ботами

**2. Subscription-Based:**
- Ежемесячная подписка (без единоразовых платежей)
- Три тарифа: Starter (10,000₽), Professional (25,000₽), Enterprise (50,000₽)
- Предсказуемый recurring revenue

**3. Cloud-Based:**
- Нет необходимости устанавливать софт
- Доступ через веб-интерфейс и Telegram
- Автоматические обновления

**4. Scalable:**
- Неограниченное количество клиентов на одной инфраструктуре
- Горизонтальное масштабирование
- Pay-as-you-grow модель

---

## 🏗️ Архитектура Multi-Tenancy

### Принцип работы:

```
┌─────────────────────────────────────────────────┐
│              VALERA PLATFORM                     │
│         (Единая инфраструктура)                  │
├─────────────────────────────────────────────────┤
│                                                  │
│  Account 1 (Автосервис А)                        │
│    ├─ bot_token_1 → @autoservice_a_bot           │
│    ├─ system_prompt_1                            │
│    ├─ price_list_1                               │
│    └─ chats → клиенты автосервиса А              │
│                                                  │
│  Account 2 (Автосервис Б)                        │
│    ├─ bot_token_2 → @autoservice_b_bot           │
│    ├─ system_prompt_2                            │
│    ├─ price_list_2                               │
│    └─ chats → клиенты автосервиса Б              │
│                                                  │
│  Account N (Автосервис N)                        │
│    ├─ bot_token_N → @autoservice_n_bot           │
│    ├─ system_prompt_N                            │
│    ├─ price_list_N                               │
│    └─ chats → клиенты автосервиса N              │
│                                                  │
└─────────────────────────────────────────────────┘
```

### Изоляция данных:

**Уровень 1: Database Level**
- Каждый Chat привязан к Account (foreign key)
- Уникальный constraint: один Chat на (telegram_user, account)
- Все запросы фильтруются по account_id

**Уровень 2: Application Level**
- RequestStore для текущего Account в каждом запросе
- Автоматическая фильтрация через scopes
- Middleware для webhook routing по bot_id

**Уровень 3: Business Logic Level**
- Каждый Account имеет свой system_prompt
- Изолированные прайс-листы и настройки
- Separate bot instances (Telegram::Bot::Client per Account)

---

## 👥 Типы пользователей

### 1. **Service Bot Users (Клиенты автосервисов)**

**Кто это:**
- Владельцы автомобилей с повреждениями
- Люди, которым нужен кузовной ремонт
- Клиенты конкретного автосервиса

**Как работают:**
```
Клиент → @autoservice_a_bot (Telegram)
        → TelegramUser (создается/находится)
        → Chat (создается для этого Account)
        → AI диалог (консультация, запись)
        → Booking (заявка на услугу)
```

**Характеристики:**
- Модель: TelegramUser
- Связь с Account: через Chat
- Может писать в несколько ботов (разные автосервисы)
- Не имеет доступа к веб-интерфейсу

---

### 2. **BossBot Users (Владельцы/Менеджеры автосервисов)**

**Кто это:**
- Владельцы автосервисов (owners)
- Менеджеры автосервисов (admin, support)
- Люди, которые управляют платформой

**Как работают:**
```
Владелец → @valera_boss_bot (Telegram Login Widget)
         → TelegramUser (авторизация)
         → Веб-интерфейс (dashboard)
         → Управление Account (настройки, команда)
         → Просмотр Bookings (заявки клиентов)
```

**Характеристики:**
- Модель: TelegramUser (та же, что и у клиентов!)
- Связь с Account: через owner_id или Membership
- Может владеть/управлять несколькими Account
- Имеет доступ к веб-интерфейсу

---

### 3. **Memberships (Команда автосервиса)**

**Концепция:**
- Владелец может добавить менеджеров в свою команду
- Membership = связь TelegramUser ↔ Account + роль

**Роли:**

**Admin (Администратор):**
- Полный доступ к Account
- Изменение настроек (промпты, прайс-лист)
- Управление командой (добавление/удаление членов)
- Просмотр всех заявок и аналитики

**Support (Поддержка):**
- Ограниченный доступ
- Просмотр заявок клиентов
- Общение с клиентами (в будущем)
- НЕТ доступа к настройкам и команде

**Схема:**
```
Account (Автосервис А)
  ├─ owner: Иван (TelegramUser)
  ├─ memberships:
  │   ├─ Иван (admin) - автоматически при создании
  │   ├─ Мария (support) - добавлена владельцем
  │   └─ Петр (admin) - добавлен владельцем
  └─ members → [Иван, Мария, Петр]
```

---

## 🔐 Авторизация и безопасность

### Service Bots (клиенты):
- **Не требуется авторизация**
- Идентификация по telegram_id
- Автоматическое создание TelegramUser при первом сообщении
- Session хранится в Chat model

### BossBot (владельцы/менеджеры):
- **Telegram Login Widget** для авторизации
- Проверка подписи от Telegram (HMAC-SHA256)
- TTL для auth data (5 минут)
- Session в Rails (session[:telegram_user_id])
- Logout доступен

**Процесс авторизации:**
```
1. Пользователь кликает "Login with Telegram" на landing page
2. Telegram Login Widget открывается
3. Пользователь подтверждает в @valera_boss_bot
4. Telegram отправляет callback с signed data
5. Valera проверяет подпись и создает сессию
6. Редирект на dashboard
```

---

## 🎯 Customer Journey

### Для владельца автосервиса (впервые):

**1. Discovery (Узнал о Valera):**
- Источник: реклама, сарафан, кейс
- Landing page с описанием
- Demo видео и примеры

**2. Onboarding:**
- Авторизация через BossBot (1 клик)
- Автоматическое создание Account
- Настройка bot_token (через BotFather)
- Настройка прайс-листа и промптов

**3. First Value (Первые результаты):**
- Первые клиенты пишут в бота
- Первые заявки приходят в dashboard
- Владелец видит работу AI

**4. Growth:**
- Добавление менеджеров в команду
- Upgrade на Professional (фото-анализ)
- Upgrade на Enterprise (страховые)

**5. Advocacy:**
- Положительные отзывы
- Рекомендации другим автосервисам
- Кейсы для маркетинга

---

### Для клиента автосервиса:

**1. Discovery:**
- Увидел рекламу автосервиса с Telegram ботом
- Перешел по ссылке t.me/autoservice_bot

**2. First Interaction:**
- Приветствие от AI-ассистента
- Описание повреждений в естественном диалоге
- Получение оценки стоимости

**3. Conversion:**
- Запись на бесплатный осмотр
- Создание заявки
- Подтверждение от менеджера

**4. Visit:**
- Приезд в автосервис
- Детальный осмотр
- Согласование ремонта

**5. Retention:**
- Возврат для следующего ремонта
- Рекомендации друзьям

---

## 📊 Key SaaS Metrics

### 1. **MRR (Monthly Recurring Revenue)**
**Определение:** Ежемесячная повторяющаяся выручка

**Формула:**
```
MRR = Σ (Активных подписок × Цена подписки)
```

**Target по phases:**
- Month 3: 80,000₽
- Month 6: 200,000₽
- Month 12: 325,000₽

---

### 2. **ARR (Annual Recurring Revenue)**
**Определение:** Годовая повторяющаяся выручка

**Формула:**
```
ARR = MRR × 12
```

**Target:** 3,900,000₽ (к концу первого года)

---

### 3. **Churn Rate (Отток клиентов)**
**Определение:** % клиентов, которые отменили подписку

**Формула:**
```
Churn Rate = (Ушедших клиентов / Начало периода) × 100%
```

**Target:** < 5% в месяц
**Industry benchmark:** 5-7% для B2B SaaS

**Причины churn:**
- Низкое качество AI
- Технические проблемы
- Отсутствие ROI
- Конкуренты

---

### 4. **CAC (Customer Acquisition Cost)**
**Определение:** Стоимость привлечения одного клиента

**Формула:**
```
CAC = (Маркетинг + Продажи + Онбординг) / Новых клиентов
```

**Target по тарифам:**
- Starter: 30,000₽
- Professional: 50,000₽
- Enterprise: 100,000₽

---

### 5. **LTV (Lifetime Value)**
**Определение:** Пожизненная ценность клиента

**Формула:**
```
LTV = ARPU × Average Lifetime (месяцев)
```

**Target по тарифам:**
- Starter: 240,000₽ (24 мес × 10,000₽)
- Professional: 600,000₽ (24 мес × 25,000₽)
- Enterprise: 1,200,000₽ (24 мес × 50,000₽)

---

### 6. **LTV/CAC Ratio**
**Определение:** Соотношение ценности к стоимости привлечения

**Формула:**
```
LTV/CAC Ratio = LTV / CAC
```

**Target:** > 3.0 (здоровый SaaS бизнес)

**Valera:**
- Starter: 8.0 (отлично)
- Professional: 12.0 (отлично)
- Enterprise: 12.0 (отлично)

---

### 7. **Payback Period**
**Определение:** Время окупаемости CAC

**Формула:**
```
Payback Period = CAC / MRR per customer
```

**Target:** < 12 месяцев

**Valera:**
- Starter: 3 месяца
- Professional: 2 месяца
- Enterprise: 2 месяца

---

## 🚀 Scaling Strategy

### Horizontal Scaling (Инфраструктура):

**Year 1 (17 клиентов):**
- 1 Rails app instance
- 1 PostgreSQL database
- 1 Redis instance
- 1 Solid Queue worker
- **Стоимость:** ~$50/месяц (AWS)

**Year 2 (40 клиентов):**
- 2-3 Rails app instances (load balancer)
- 1 PostgreSQL database (scaled up)
- 1 Redis instance (scaled up)
- 2-3 Solid Queue workers
- **Стоимость:** ~$200/месяц (AWS)

**Year 3 (70 клиентов):**
- 5+ Rails app instances (auto-scaling)
- PostgreSQL read replicas
- Redis cluster
- 5+ Solid Queue workers
- CDN for static assets
- **Стоимость:** ~$500/месяц (AWS)

---

### Vertical Scaling (Команда):

**Year 1:**
- 1 Founder/Developer
- 1 Part-time Support
- **Costs:** ~150,000₽/мес

**Year 2:**
- 1 Tech Lead
- 2 Developers
- 1 Customer Success Manager
- 1 Sales Manager
- **Costs:** ~500,000₽/мес

**Year 3:**
- 1 Tech Lead
- 3 Developers
- 2 Customer Success Managers
- 2 Sales Managers
- 1 Marketing Manager
- **Costs:** ~1,000,000₽/мес

---

## 📈 Growth Projections

### Conservative (Пессимистичный):
```
Year 1: 15 clients, 200K MRR, 2.4M ARR
Year 2: 30 clients, 450K MRR, 5.4M ARR
Year 3: 50 clients, 800K MRR, 9.6M ARR
```

### Base (Базовый):
```
Year 1: 17 clients, 325K MRR, 3.9M ARR
Year 2: 40 clients, 700K MRR, 8.4M ARR
Year 3: 70 clients, 1.2M MRR, 14.4M ARR
```

### Aggressive (Оптимистичный):
```
Year 1: 25 clients, 500K MRR, 6M ARR
Year 2: 60 clients, 1M MRR, 12M ARR
Year 3: 100 clients, 1.8M MRR, 21.6M ARR
```

---

## 🎯 Success Criteria

### Phase 1 (Month 1-3):
- [ ] Multi-tenancy реализован (FIP-002)
- [ ] BossBot авторизация работает (FIP-003)
- [ ] 3-5 pilot клиентов
- [ ] MRR > 50,000₽

### Phase 2 (Month 4-6):
- [ ] Photo Analysis реализован (US-003)
- [ ] 10-15 платных клиентов
- [ ] MRR > 150,000₽
- [ ] Churn < 10%

### Phase 3 (Month 7-12):
- [ ] Insurance Automation реализован (US-004)
- [ ] 17+ платных клиентов
- [ ] MRR > 300,000₽
- [ ] Churn < 5%
- [ ] LTV/CAC > 10

---

## 🔗 Связанные документы

- **[monetization-strategy.md](monetization-strategy.md)** - Стратегия монетизации
- **[business-value.md](business-value.md)** - Бизнес-ценность
- **[../requirements/FIP-002-multitenancy.md](../requirements/FIP-002-multitenancy.md)** - Multi-tenancy реализация
- **[../requirements/FIP-003-memberships-boss-bot.md](../requirements/FIP-003-memberships-boss-bot.md)** - BossBot авторизация
- **[../requirements/ROADMAP.md](../requirements/ROADMAP.md)** - Roadmap

---

**Версия:** 1.0
**Дата создания:** 27.10.2025
**Тип документа:** SaaS Overview
**Статус:** Active - Ready for Execution
