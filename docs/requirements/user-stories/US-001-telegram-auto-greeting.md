# User Story: US-001 - Telegram Auto Greeting

**Статус:** Approved
**Приоритет:** High
**Story Points:** 5
**Создан:** 25.10.2025
**Автор:** Product Owner

## 📝 Описание

**As a** car service owner
**I want** the bot to automatically greet new users and introduce itself
**So that** customers feel welcomed and understand what the bot can do for them

## ✅ Критерии приемки (Acceptance Criteria)

- [ ] **Given** a new user starts a chat with the bot **When** they send any message **Then** the bot responds with a welcome message within 2 seconds
- [ ] **Given** a user receives the welcome message **When** they read it **Then** the message includes the bot's name, purpose, and available commands
- [ ] **Given** a returning user messages the bot **When** they haven't messaged in 24 hours **Then** the bot responds with a brief re-welcome message
- [ ] **Given** the welcome message is sent **When** displayed **Then** it includes inline keyboard buttons for common actions (Book service, Check prices, Contact support)

## 🎯 Бизнес-ценность

- **Проблема:** Новые пользователи не понимают возможностей бота и как им пользоваться
- **Решение:** Автоматическое приветствие с четким описанием функциональности
- **Метрики успеха:** Увеличение конверсии новых пользователей в активных на 40%, снижение количества сообщений "что ты умеешь?" на 60%

## 👥 Пользователи

- **Основной пользователь:** Новые клиенты автосервиса, которые впервые пишут боту
- **Дополнительные пользователи:** Существующие клиенты, которые возвращаются после долгого отсутствия

## 🔗 Связанные документы

- **Feature Description:** [feature-telegram-welcome-experience.md](../features/feature-telegram-welcome-experience.md)
- **Technical Specification:** [TS-001-telegram-webhook-handling.md](../specifications/TS-001-telegram-webhook-handling.md)
- **Implementation Plan:** [protocol-telegram-welcome.md](../../.protocols/protocol-telegram-welcome.md)

## 🚫 Исключения (Edge Cases)

- **Пользователь заблокировал бота:** Нет действия, сообщение не доставляется
- **Bot временно недоступен:** Отложенная отправка приветствия при восстановлении
- **Спам сообщений:** Приветствие отправляется только один раз в час для одного пользователя

## ✅ Definition of Done

- [ ] Все критерии приемки выполнены
- [ ] Код покрыт тестами (unit + integration)
- [ ] Документация обновлена
- [ ] Code review пройден
- [ ] Функциональность протестирована на staging с реальными Telegram аккаунтами
- [ ] Производительность проверена (время ответа < 2 сек)

## 📋 Заметки

Приветственное сообщение должно быть на русском языке, так как целевая аудитория - русскоязычные клиенты автосервиса. Тон общения - дружелюбный, но профессиональный.

---

**История изменений:**
- 25.10.2025 14:30 - Создан черновик
- 25.10.2025 15:45 - Добавлены критерии приемки
- 25.10.2025 16:20 - Статус изменен на Approved