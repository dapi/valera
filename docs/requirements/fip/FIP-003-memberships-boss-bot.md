# Feature Implementation Plan: FIP-003 - Memberships и BossBot авторизация

**Статус:** 📝 Draft
**Приоритет:** High
**Версия:** 1.0
**Создан:** 27.10.2025 02:00
**Автор:** Tech Lead
**Ожидаемое время реализации:** 3-4 дня
**Зависит от:** FIP-002 (Multi-Tenancy)

## 📋 Executive Summary

### Контекст продукта Valera

**🎯 Основные проблемы автосервисов**

**Для владельцев бизнеса:**

1. **Высокая нагрузка на менеджеров**
   - Менеджеры тратят 60-70% времени на типовые консультации: "сколько стоит", "как долго", "что с повреждением"
   - Valera автоматизирует это → снижение нагрузки на 15-25%

2. **Низкая конверсия обращений**
   - Клиенты уходят из-за долгого ожидания ответа
   - Valera отвечает мгновенно 24/7 → конверсия растет до 8-12%

3. **Нет первичной оценки без приезда**
   - Клиент должен приехать для осмотра → часто не приезжает
   - Valera анализирует фото → предварительная оценка за 5 секунд

4. **Сложность со страховыми случаями**
   - Оформление ОСАГО/КАСКО отнимает много времени
   - Valera (Phase 3) автоматизирует работу со страховыми

**Для клиентов автосервиса:**

1. **Долго ждать консультации**
   - Нужно звонить, ждать ответа менеджера
   - Valera отвечает сразу

2. **Неясная стоимость ремонта**
   - Нужно приезжать для оценки
   - Valera дает предварительную оценку по фото

3. **Неудобная запись**
   - Нужно звонить в рабочее время
   - Valera записывает 24/7 через простой диалог

**💰 Бизнес-результат**

- +20% новых клиентов (за счет 24/7 доступности)
- 15-25% снижение нагрузки на менеджеров
- 8-12% конверсия в заявки (MVP)
- 25-40% конверсия после анализа фото (Phase 2)

**🎯 Главная боль, которую решает**

Автоматизация первого контакта с клиентом - от "Здравствуйте" до создания заявки на ремонт, без участия менеджера, через естественный диалог с AI.

---

### Бизнес-проблема FIP-003 (Memberships)

После внедрения multi-tenancy (FIP-002) каждый автосервис имеет своего бота для клиентов. Однако **владельцы и менеджеры** автосервисов не имеют способа:
- Авторизоваться в веб-интерфейсе управления
- Управлять настройками своего автосервиса (промпты, прайс-листы)
- Просматривать бронирования и аналитику
- Добавлять других менеджеров в свой аккаунт

### Предлагаемое решение
Двухуровневая система ботов с единой моделью TelegramUser:

**1. Service Bots** (уже есть в FIP-002)
- Боты для **клиентов** автосервисов
- Запись на услуги, консультации
- Привязаны к Account через bot_token
- Работают через webhook routing
- TelegramUser → Chat → Booking

**2. BossBot** (новый, ЕДИНЫЙ для всего проекта)
- **Главный бот** для авторизации владельцев/менеджеров
- Авторизация через ссылки с временными токенами (веб ↔ бот)
- Управление командой (memberships с ролями)
- НЕ привязан к конкретному Account
- TelegramUser → Memberships → Accounts

**Ключевое решение:** TelegramUser используется и для клиентов, и для владельцев/менеджеров. Никаких отдельных моделей User!

### Бизнес-ценность
- **Безопасная авторизация** через Telegram (без паролей)
- **Team collaboration** - владелец может добавить менеджеров
- **Role-based access** - admin и support роли
- **Единая точка входа** - BossBot для всех автосервисов
- **Простая архитектура** - одна модель TelegramUser для всех

## 🏗️ Архитектура

### Два типа ботов, одна модель пользователей:

```
┌─────────────────────────────────────────────────────────────┐
│                     VALERA ECOSYSTEM                         │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  TelegramUser (ЕДИНАЯ модель для всех)                      │
│   ├─ chats → диалоги с Service Bots (клиенты)               │
│   ├─ owned_accounts → аккаунты где owner (владельцы)        │
│   └─ memberships → участие в аккаунтах (менеджеры)          │
│                                                              │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  1️⃣ SERVICE BOTS (множество, для клиентов)                  │
│     ├─ AutoService1Bot (@autoservice1_bot)                  │
│     ├─ AutoService2Bot (@autoservice2_bot)                  │
│     └─ ... каждый Account имеет свой бот                    │
│                                                              │
│     Клиенты (TelegramUser) → Service Bot → Запись           │
│                                                              │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  2️⃣ BOSS BOT (один, для владельцев/менеджеров)              │
│     └─ ValeraBossBot (@valera_boss_bot)                     │
│                                                              │
│     Владельцы (TelegramUser) → BossBot → Авторизация в веб  │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Модели данных (упрощенная архитектура):

```ruby
TelegramUser (ЕДИНАЯ модель - и клиенты, и владельцы)
  ├── chats (Chat) - диалоги с Service Bots
  ├── owned_accounts (Account, через owner_id) - аккаунты где owner
  ├── memberships (Membership) - участие в аккаунтах
  └── accounts (через memberships) - все доступные аккаунты

Account (из FIP-002, расширенная)
  ├── owner (TelegramUser) - владелец аккаунта
  ├── memberships (Membership) - команда аккаунта
  ├── members (TelegramUser, через memberships) - все члены команды
  └── chats (Chat) - диалоги клиентов с Service Bot

Membership (новая модель - связь TelegramUser ↔ Account с ролью)
  ├── telegram_user (TelegramUser) - член команды
  ├── account (Account) - аккаунт
  └── role (enum: admin, support) - роль в команде

Chat (из FIP-002, без изменений)
  ├── telegram_user (TelegramUser) - клиент
  ├── account (Account) - в каком боте диалог
  └── bookings (Booking) - бронирования клиента
```

### Разделение ответственности:

| Аспект | Service Bots | BossBot |
|--------|--------------|---------|
| **Пользователи** | Клиенты автосервисов | Владельцы/менеджеры |
| **Модель** | TelegramUser | TelegramUser (та же!) |
| **Функции** | Запись на услуги | Авторизация в веб |
| **Количество** | Множество (по боту на Account) | Один на весь проект |
| **Webhook** | `/telegram/webhook/:bot_id` | `/telegram/boss_bot/webhook` |
| **Авторизация** | Не требуется | Ссылки с токенами (веб↔бот) |
| **Связь с Account** | через Chat | через Membership/owner |

### Как TelegramUser работает в двух контекстах:

```ruby
# Пример 1: Иван - КЛИЕНТ автосервиса "Автосервис А"
telegram_user_1 = TelegramUser.find(123456)
telegram_user_1.chats.count #=> 1 (диалог с ботом "Автосервис А")
telegram_user_1.owned_accounts.count #=> 0 (не владелец)
telegram_user_1.memberships.count #=> 0 (не менеджер)

# Пример 2: Петр - ВЛАДЕЛЕЦ автосервиса "Автосервис Б"
telegram_user_2 = TelegramUser.find(789012)
telegram_user_2.chats.count #=> 0 (не писал в Service Bots)
telegram_user_2.owned_accounts.count #=> 1 (владелец "Автосервис Б")
telegram_user_2.memberships.count #=> 1 (admin в своем аккаунте)

# Пример 3: Мария - МЕНЕДЖЕР в "Автосервис Б" и КЛИЕНТ в "Автосервис А"
telegram_user_3 = TelegramUser.find(345678)
telegram_user_3.chats.count #=> 1 (диалог с ботом "Автосервис А")
telegram_user_3.owned_accounts.count #=> 0 (не владелец)
telegram_user_3.memberships.count #=> 1 (support в "Автосервис Б")
telegram_user_3.accounts.count #=> 1 (доступ к "Автосервис Б")
```

## 🔧 Технические требования

### Database Schema:

```ruby
# Генерируется через: rails generate model Membership
create_table :memberships do |t|
  t.bigint :account_id, null: false
  t.bigint :telegram_user_id, null: false
  t.string :role, default: 'admin', null: false # admin, support

  t.timestamps
end

add_index :memberships, [:account_id, :telegram_user_id], unique: true
add_index :memberships, :account_id
add_index :memberships, :telegram_user_id
add_foreign_key :memberships, :accounts, on_delete: :cascade
add_foreign_key :memberships, :telegram_users, on_delete: :cascade

# Обновление TelegramUser (добавить поля для веб-авторизации)
add_column :telegram_users, :locale, :string, default: 'ru', null: false
add_column :telegram_users, :last_login_at, :datetime
add_column :telegram_users, :last_login_from_ip, :string

# Обновление Account (добавить owner_id если еще нет из FIP-002)
# Если FIP-002 уже реализован с owner_id, проверить что foreign_key на telegram_users
add_column :accounts, :owner_id, :bigint
add_index :accounts, :owner_id
add_foreign_key :accounts, :telegram_users, column: :owner_id, on_delete: :restrict
```

### Роли в Membership:

```ruby
class Membership < ApplicationRecord
  ROLES = %w[admin support].freeze

  enum :role, ROLES.each_with_object({}) { |key, a| a[key] = key }

  # admin - полный доступ к аккаунту:
  #   - изменение настроек Account
  #   - управление командой (добавление/удаление членов)
  #   - просмотр всех бронирований и аналитики
  #   - изменение прайс-листа и промптов

  # support - ограниченный доступ:
  #   - просмотр бронирований
  #   - общение с клиентами (в будущем)
  #   - НЕТ доступа к настройкам
  #   - НЕТ доступа к управлению командой
end
```

### Core Models:

**app/models/membership.rb:**
```ruby
# frozen_string_literal: true

# Модель членства пользователя в команде аккаунта
#
# Представляет связь между TelegramUser и Account с определенной ролью.
# Позволяет владельцу аккаунта добавлять менеджеров в свою команду.
#
# @attr [BigInt] account_id ID аккаунта
# @attr [BigInt] telegram_user_id ID пользователя Telegram
# @attr [String] role роль пользователя в команде (admin, support)
#
# @example Создание нового члена команды
#   membership = Membership.create!(
#     account: account,
#     telegram_user: user,
#     role: 'support'
#   )
#
# @author Danil Pismenny
# @since 0.2.0
class Membership < ApplicationRecord
  belongs_to :account
  belongs_to :telegram_user

  # Роли в команде аккаунта
  ROLES = %w[admin support].freeze
  enum :role, ROLES.each_with_object({}) { |key, a| a[key] = key }

  validates :account_id, presence: true
  validates :telegram_user_id, presence: true,
            uniqueness: { scope: :account_id,
                         message: 'уже является членом команды' }
  validates :role, presence: true, inclusion: { in: ROLES }

  # Проверяет может ли пользователь управлять командой
  #
  # @return [Boolean] true если admin
  # @example
  #   membership.can_manage_team? #=> true
  def can_manage_team?
    admin?
  end

  # Проверяет может ли пользователь изменять настройки аккаунта
  #
  # @return [Boolean] true если admin
  # @example
  #   membership.can_edit_settings? #=> true
  def can_edit_settings?
    admin?
  end
end
```

**Обновления в app/models/telegram_user.rb:**
```ruby
class TelegramUser < ApplicationRecord
  # Existing associations
  has_many :chats, dependent: :destroy

  # NEW: Memberships and Accounts (для владельцев/менеджеров)
  has_many :owned_accounts, class_name: 'Account', foreign_key: :owner_id,
           dependent: :restrict_with_error, inverse_of: :owner
  has_many :memberships, dependent: :destroy
  has_many :accounts, through: :memberships

  # ... existing methods ...

  # NEW: Возвращает аккаунт по умолчанию для пользователя
  #
  # @return [Account, nil] первый доступный аккаунт или nil
  # @example
  #   user.default_account #=> #<Account>
  def default_account
    owned_accounts.order(:created_at).first || accounts.order(:created_at).first
  end

  # NEW: Проверяет имеет ли пользователь доступ к аккаунту
  #
  # @param account [Account] проверяемый аккаунт
  # @return [Boolean] true если есть доступ
  # @example
  #   user.has_access_to?(account) #=> true
  def has_access_to?(account)
    id == account.owner_id || memberships.exists?(account_id: account.id)
  end

  # NEW: Проверяет является ли пользователь админом аккаунта
  #
  # @param account [Account] проверяемый аккаунт
  # @return [Boolean] true если admin
  # @example
  #   user.admin_of?(account) #=> true
  def admin_of?(account)
    id == account.owner_id ||
      memberships.exists?(account_id: account.id, role: 'admin')
  end

  # NEW: Проверяет является ли пользователь владельцем аккаунта
  #
  # @param account [Account] проверяемый аккаунт
  # @return [Boolean] true если owner
  # @example
  #   user.owner_of?(account) #=> true
  def owner_of?(account)
    account.owner_id == id
  end
end
```

**Обновления в app/models/account.rb (из FIP-002):**
```ruby
class Account < ApplicationRecord
  # ... existing code ...

  belongs_to :owner, class_name: 'TelegramUser', foreign_key: :owner_id,
             optional: true # ДОБАВИТЬ/ОБНОВИТЬ
  has_many :memberships, dependent: :destroy # ДОБАВИТЬ
  has_many :members, through: :memberships, source: :telegram_user # ДОБАВИТЬ

  # Автоматически добавлять владельца в members после создания
  after_create :add_owner_to_members, if: :owner_id?

  # ... existing code ...

  private

  # Добавляет владельца в члены команды с ролью admin
  #
  # @return [void]
  # @api private
  def add_owner_to_members
    memberships.create!(telegram_user: owner, role: 'admin')
  rescue ActiveRecord::RecordInvalid => e
    log_error(e, {
      model: 'Account',
      method: 'add_owner_to_members',
      account_id: id,
      owner_id: owner_id
    })
  end
end
```

### Механизм авторизации через ссылки с токенами:

**Схема авторизации (веб ↔ BossBot):**

```
┌─────────────────────────────────────────────────────────────┐
│                    FLOW 1: Веб → BossBot → Веб               │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  1. User на сайте нажимает "Войти через Telegram"           │
│  2. Сайт генерирует auth_token (TTL: 5 минут)              │
│  3. Сайт редиректит на:                                      │
│     https://t.me/ValeraBossBot?start=AUTH_TOKEN             │
│  4. BossBot получает /start AUTH_TOKEN                       │
│  5. BossBot верифицирует AUTH_TOKEN                         │
│  6. BossBot отправляет ссылку с confirm_token:               │
│     https://yoursite.com/auth/confirm?token=CONFIRM_TOKEN   │
│  7. User кликает → сайт верифицирует CONFIRM_TOKEN          │
│  8. Сайт создает сессию для telegram_user_id                │
│                                                              │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                    FLOW 2: BossBot → Веб                     │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  1. User пишет /start в BossBot (без токена)                │
│  2. BossBot генерирует confirm_token (TTL: 5 минут)         │
│  3. BossBot отправляет ссылку:                               │
│     https://yoursite.com/auth/confirm?token=CONFIRM_TOKEN   │
│  4. User кликает → сайт верифицирует CONFIRM_TOKEN          │
│  5. Сайт создает сессию для telegram_user_id                │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

**Безопасность токенов:**
- Используется `Rails.application.message_verifier(:telegram_auth)`
- TTL: 5 минут (configurable через `TELEGRAM_AUTH_EXPIRATION`)
- Токены подписываются secret_key_base
- Невозможно подделать или изменить токен

### Детальные алгоритмы авторизации (с edge cases):

#### **FLOW 1: Веб → BossBot → Веб**

**Шаг 1: Пользователь на сайте нажимает "Войти через Telegram"**
```
GET /auth/login
```

**Обработка в Auth::TelegramController#login:**
```ruby
def login
  # Edge case 1: User уже авторизован
  if telegram_user_signed_in?
    redirect_to dashboard_accounts_path
    return
  end

  # Генерируем auth_token
  auth_token = generate_auth_token(session.id.to_s)

  # Edge case 2: Ошибка генерации токена
  unless auth_token
    redirect_to root_path, alert: 'Ошибка генерации токена'
    return
  end

  # Редиректим на BossBot
  boss_bot_url = "https://t.me/#{ApplicationConfig.boss_bot_username}?start=#{auth_token}"
  redirect_to boss_bot_url, allow_other_host: true
end
```

**Шаг 2: User открывает BossBot в Telegram, бот получает /start AUTH_TOKEN**
```
/start eyJfcmFpbHMiOnsibWVzc2FnZSI6IklqRXlNelFoIn0...
```

**Обработка в Telegram::BossBotController#start:**
```ruby
def start(payload = '')
  telegram_user = current_telegram_user

  # Edge case 1: Telegram user не найден/не создан
  unless telegram_user
    respond_with :message, text: 'Ошибка авторизации. Попробуйте еще раз.'
    return
  end

  if payload.present?
    # Edge case 2: Токен невалидный или истек
    unless verify_auth_token(payload)
      respond_with :message,
                   text: 'Токен авторизации устарел или неверен. Попробуйте заново войти на сайт.'
      return
    end

    # Токен валиден, отправляем ссылку на сайт
    send_confirm_link(telegram_user)
  else
    # Flow 2: без payload
    send_confirm_link(telegram_user)
  end
end

private

def verify_auth_token(token)
  verifier = Rails.application.message_verifier(:telegram_auth)
  data = verifier.verify(token, purpose: :telegram_auth)

  # Edge case 3: Токен валиден но неправильного типа
  return false unless data['type'] == 'auth_request'

  true
rescue ActiveSupport::MessageVerifier::InvalidSignature
  # Edge case 4: Токен подделан
  false
rescue ActiveSupport::MessageExpired
  # Edge case 5: Токен истек (> 5 минут)
  false
end

def send_confirm_link(telegram_user)
  # Edge case 6: TelegramUser без ID
  unless telegram_user.id
    respond_with :message, text: 'Ошибка: пользователь не сохранен'
    return
  end

  confirm_token = generate_confirm_token(telegram_user.id)

  # Edge case 7: Ошибка генерации confirm_token
  unless confirm_token
    respond_with :message, text: 'Ошибка генерации ссылки. Попробуйте еще раз.'
    return
  end

  # Edge case 8: web_host не настроен
  unless ApplicationConfig.web_host.present?
    respond_with :message, text: 'Ошибка конфигурации сервера. Обратитесь к администратору.'
    return
  end

  confirm_url = Rails.application.routes.url_helpers.auth_confirm_url(
    token: confirm_token,
    host: ApplicationConfig.web_host
  )

  respond_with :message,
               text: "Для входа в панель управления нажмите на ссылку:\n\n#{confirm_url}\n\nСсылка действительна 5 минут."
end
```

**Шаг 3: User кликает ссылку → открывается сайт**
```
GET /auth/confirm?token=CONFIRM_TOKEN
```

**Обработка в Auth::TelegramController#confirm:**
```ruby
def confirm
  token = params[:token].to_s

  # Edge case 1: Токен пустой
  if token.blank?
    redirect_to root_path, alert: 'Неверный токен авторизации'
    return
  end

  # Верифицируем токен
  telegram_user_id = verify_confirm_token(token)

  # Edge case 2: Токен невалидный или истек
  unless telegram_user_id
    redirect_to root_path, alert: 'Токен авторизации устарел или неверен. Попробуйте заново.'
    return
  end

  # Edge case 3: TelegramUser не существует в БД
  telegram_user = TelegramUser.find_by(id: telegram_user_id)
  unless telegram_user
    redirect_to root_path, alert: 'Пользователь не найден. Попробуйте заново авторизоваться через бот.'
    return
  end

  # Edge case 4: У пользователя нет аккаунта - создаем первый
  if telegram_user.default_account.blank?
    begin
      Account.create!(
        owner: telegram_user,
        name: "Автосервис #{telegram_user.full_name}",
        bot_token: 'PLACEHOLDER',
        bot_id: 'PLACEHOLDER',
        llm_provider: ApplicationConfig.llm_provider,
        llm_model: ApplicationConfig.llm_model,
        system_prompt: File.read(ApplicationConfig.system_prompt_path),
        company_info: File.read(ApplicationConfig.company_info_path),
        welcome_message: File.read(ApplicationConfig.welcome_message_path),
        price_list: JSON.parse(File.read(ApplicationConfig.price_list_path))
      )
    rescue ActiveRecord::RecordInvalid => e
      # Edge case 5: Ошибка создания Account
      Rails.logger.error "Failed to create Account: #{e.message}"
      redirect_to root_path, alert: 'Ошибка создания аккаунта. Попробуйте еще раз.'
      return
    end
  end

  # Edge case 6: Session уже существует для другого пользователя
  if session[:telegram_user_id] && session[:telegram_user_id] != telegram_user.id
    # Логаут предыдущего пользователя
    session.delete(:telegram_user_id)
  end

  # Создаем сессию
  session[:telegram_user_id] = telegram_user.id
  telegram_user.update!(
    last_login_at: Time.current,
    last_login_from_ip: request.remote_ip
  )

  redirect_to dashboard_accounts_path,
              notice: "Добро пожаловать, #{telegram_user.full_name}!"
rescue StandardError => e
  # Edge case 7: Любая другая ошибка
  Rails.logger.error "Telegram auth error: #{e.message}\n#{e.backtrace.join("\n")}"
  redirect_to root_path, alert: 'Ошибка авторизации. Попробуйте еще раз.'
end

private

def verify_confirm_token(token)
  verifier = Rails.application.message_verifier(:telegram_auth)
  data = verifier.verify(token, purpose: :telegram_confirm)

  # Edge case 8: Токен валиден но неправильного типа
  return nil unless data['type'] == 'confirm'

  # Edge case 9: telegram_user_id отсутствует в токене
  return nil unless data['telegram_user_id'].present?

  data['telegram_user_id']
rescue ActiveSupport::MessageVerifier::InvalidSignature
  # Edge case 10: Токен подделан
  nil
rescue ActiveSupport::MessageExpired
  # Edge case 11: Токен истек
  nil
end
```

---

#### **FLOW 2: BossBot → Веб (упрощенный)**

**Шаг 1: User пишет /start в BossBot (без payload)**
```
/start
```

**Обработка в Telegram::BossBotController#start:**
```ruby
def start(payload = '')
  telegram_user = current_telegram_user

  # Edge case 1: Telegram user не найден/не создан
  unless telegram_user
    respond_with :message, text: 'Ошибка авторизации. Попробуйте еще раз.'
    return
  end

  # payload пустой → Flow 2
  if payload.blank?
    send_confirm_link(telegram_user)
  else
    # Flow 1
    handle_auth_token(telegram_user, payload)
  end
end
```

**Шаг 2: User кликает ссылку → открывается сайт**
```
GET /auth/confirm?token=CONFIRM_TOKEN
```

Обработка идентична Flow 1, Шаг 3 (см. выше).

---

#### **Дополнительные Edge Cases:**

**1. Одновременные запросы:**
```ruby
# Если user открыл несколько вкладок и кликнул "Войти" в каждой
# Каждая генерирует свой auth_token
# Но в BossBot они все отправляют confirm_token для одного telegram_user_id
# Результат: все вкладки могут успешно авторизоваться (последняя установит сессию)
```

**2. Повторное использование токена:**
```ruby
# message_verifier не предотвращает повторное использование до истечения TTL
# Поэтому confirm_token можно использовать несколько раз в течение 5 минут
# Решение: можно добавить Redis для отслеживания использованных токенов (optional)
```

**3. Race condition при создании Account:**
```ruby
# Если user кликнул confirm_token в двух вкладках одновременно
# Может попытаться создать два Account с одним owner
# Решение: используем transaction и unique constraint на owner_id (optional)
```

**4. Смена telegram username:**
```ruby
# User может изменить username между Flow 1 и Flow 2
# TelegramUser обновится автоматически при find_or_create_by_telegram_data!
# Сессия привязана к telegram_user.id, поэтому проблемы нет
```

**5. Удаление TelegramUser из БД во время flow:**
```ruby
# Edge case: TelegramUser удален между генерацией confirm_token и confirm
# Результат: ActiveRecord::RecordNotFound в confirm
# Обрабатывается: rescue блок редиректит с ошибкой
```

**6. Отключение Javascript в браузере:**
```ruby
# confirm_url - обычная GET ссылка, работает без JS
# Проблем не будет
```

**7. Истечение сессии между login и confirm:**
```ruby
# session.id используется только для генерации auth_token
# Даже если сессия очистится, confirm создаст новую сессию
# Проблем не будет
```

**8. Попытка авторизации уже авторизованного user:**
```ruby
# В login: проверяем telegram_user_signed_in? → редирект в dashboard
# В confirm: если сессия существует для другого user → logout предыдущего
```

### Routes (config/routes.rb):

```ruby
# BossBot webhook (для обработки /start команды)
post 'telegram/boss_bot/webhook', to: 'telegram/boss_bot#webhook'

# BossBot авторизация
namespace :auth do
  get 'login', to: 'telegram#login', as: :telegram_login # генерирует ссылку на BossBot
  get 'confirm', to: 'telegram#confirm' # верифицирует токен из бота
end

# Веб-интерфейс управления (требует авторизации)
authenticate :telegram_user do
  namespace :dashboard do
    resources :accounts do
      resources :memberships, only: [:index, :create, :destroy]
      resources :bookings, only: [:index, :show]
      resource :settings, only: [:show, :update]
    end
  end
end

# Logout
delete '/logout', to: 'sessions#destroy', as: :logout
```

### Controllers для авторизации:

**app/controllers/auth/telegram_controller.rb:**
```ruby
# frozen_string_literal: true

# Контроллер авторизации через Telegram (BossBot)
#
# Обрабатывает авторизацию через ссылки с токенами.
# Два flow: веб→бот→веб и бот→веб.
#
# @example Начало авторизации с веба
#   GET /auth/login
#   → редирект на t.me/ValeraBossBot?start=TOKEN
#
# @example Подтверждение авторизации из бота
#   GET /auth/confirm?token=TOKEN
#   → создание сессии
#
# @author Danil Pismenny
# @since 0.2.0
class Auth::TelegramController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :redirect_if_authenticated, only: [:login]

  # Генерирует ссылку на BossBot для авторизации (Flow 1: веб→бот)
  #
  # @return [void] редирект на t.me/ValeraBossBot?start=TOKEN
  # @example
  #   GET /auth/login
  def login
    # Сохраняем текущую сессию ID для проверки в confirm
    auth_token = generate_auth_token(session.id.to_s)

    boss_bot_url = "https://t.me/#{ApplicationConfig.boss_bot_username}?start=#{auth_token}"
    redirect_to boss_bot_url, allow_other_host: true
  end

  # Подтверждает авторизацию по токену из BossBot (Flow 1 и 2)
  #
  # @return [void] создает сессию и редиректит в dashboard
  # @raise [ActionController::BadRequest] при невалидном токене
  # @example
  #   GET /auth/confirm?token=CONFIRM_TOKEN
  def confirm
    token = params[:token].to_s

    if token.blank?
      redirect_to root_path, alert: 'Неверный токен авторизации'
      return
    end

    # Верифицируем токен и получаем telegram_user_id
    telegram_user_id = verify_confirm_token(token)

    unless telegram_user_id
      redirect_to root_path, alert: 'Токен авторизации устарел или неверен'
      return
    end

    # Находим или создаем пользователя
    telegram_user = TelegramUser.find(telegram_user_id)

    # Создаем Account если у пользователя нет ни одного
    if telegram_user.default_account.blank?
      Account.create!(
        owner: telegram_user,
        name: "Автосервис #{telegram_user.full_name}",
        bot_token: 'PLACEHOLDER', # TODO: заменить на реальный при настройке
        bot_id: 'PLACEHOLDER',
        llm_provider: ApplicationConfig.llm_provider,
        llm_model: ApplicationConfig.llm_model,
        system_prompt: File.read(ApplicationConfig.system_prompt_path),
        company_info: File.read(ApplicationConfig.company_info_path),
        welcome_message: File.read(ApplicationConfig.welcome_message_path),
        price_list: JSON.parse(File.read(ApplicationConfig.price_list_path))
      )
    end

    # Создаем сессию
    session[:telegram_user_id] = telegram_user.id
    telegram_user.update!(
      last_login_at: Time.current,
      last_login_from_ip: request.remote_ip
    )

    redirect_to dashboard_accounts_path,
                notice: "Добро пожаловать, #{telegram_user.full_name}!"
  rescue ActiveRecord::RecordNotFound
    Rails.logger.error "TelegramUser not found: #{telegram_user_id}"
    redirect_to root_path, alert: 'Пользователь не найден. Попробуйте еще раз.'
  rescue StandardError => e
    Rails.logger.error "Telegram auth error: #{e.message}"
    redirect_to root_path, alert: 'Ошибка авторизации. Попробуйте еще раз.'
  end

  private

  # Генерирует auth_token для Flow 1 (веб→бот)
  #
  # @param session_id [String] ID текущей сессии
  # @return [String] подписанный токен
  # @api private
  def generate_auth_token(session_id)
    verifier = Rails.application.message_verifier(:telegram_auth)
    verifier.generate({
      type: 'auth_request',
      session_id: session_id,
      timestamp: Time.current.to_i
    }, purpose: :telegram_auth, expires_in: ApplicationConfig.telegram_auth_expiration.seconds)
  end

  # Верифицирует confirm_token и возвращает telegram_user_id
  #
  # @param token [String] токен из BossBot
  # @return [Integer, nil] telegram_user_id или nil если токен невалиден
  # @api private
  def verify_confirm_token(token)
    verifier = Rails.application.message_verifier(:telegram_auth)
    data = verifier.verify(token, purpose: :telegram_confirm)
    data['telegram_user_id']
  rescue ActiveSupport::MessageVerifier::InvalidSignature, ActiveSupport::MessageExpired
    nil
  end

  # Редиректит в dashboard если уже авторизован
  #
  # @return [void]
  # @api private
  def redirect_if_authenticated
    redirect_to dashboard_accounts_path if telegram_user_signed_in?
  end
end
```

**app/controllers/telegram/boss_bot_controller.rb:**
```ruby
# frozen_string_literal: true

# Контроллер для обработки webhook BossBot
#
# Обрабатывает команду /start с токенами для авторизации.
# Два сценария:
# 1. /start AUTH_TOKEN - проверяет токен, отправляет ссылку на сайт
# 2. /start - отправляет ссылку на сайт с новым токеном
#
# @author Danil Pismenny
# @since 0.2.0
class Telegram::BossBotController < Telegram::WebhookController
  include ErrorLogger

  # Обработка /start команды
  #
  # @param payload [String] auth_token или пустая строка
  # @return [void] отправляет сообщение в Telegram
  def start(payload = '')
    telegram_user = current_telegram_user

    if payload.present?
      # Flow 1: веб→бот→веб (проверяем auth_token)
      handle_auth_token(telegram_user, payload)
    else
      # Flow 2: бот→веб (просто отправляем ссылку)
      send_confirm_link(telegram_user)
    end
  rescue StandardError => e
    log_error(e, {
      controller: 'Telegram::BossBotController',
      method: 'start',
      telegram_user_id: telegram_user&.id,
      payload: payload
    })

    respond_with :message,
                 text: 'Произошла ошибка. Попробуйте еще раз позже.'
  end

  private

  # Возвращает текущего пользователя Telegram из update
  #
  # @return [TelegramUser] текущий пользователь
  # @api private
  def current_telegram_user
    from = update['message']['from']
    TelegramUser.find_or_create_by_telegram_data!(from)
  end

  # Обрабатывает auth_token из веба (Flow 1)
  #
  # @param telegram_user [TelegramUser] текущий пользователь
  # @param auth_token [String] токен из веб-страницы
  # @return [void]
  # @api private
  def handle_auth_token(telegram_user, auth_token)
    # Верифицируем auth_token
    unless verify_auth_token(auth_token)
      respond_with :message,
                   text: 'Токен авторизации устарел или неверен. Попробуйте еще раз.'
      return
    end

    # Токен валиден, отправляем ссылку на сайт
    send_confirm_link(telegram_user)
  end

  # Отправляет ссылку на сайт с confirm_token
  #
  # @param telegram_user [TelegramUser] пользователь для авторизации
  # @return [void]
  # @api private
  def send_confirm_link(telegram_user)
    confirm_token = generate_confirm_token(telegram_user.id)
    confirm_url = Rails.application.routes.url_helpers.auth_confirm_url(
      token: confirm_token,
      host: ApplicationConfig.web_host
    )

    respond_with :message,
                 text: "Для входа в панель управления нажмите на ссылку:\n\n#{confirm_url}\n\nСсылка действительна 5 минут."
  end

  # Верифицирует auth_token из веба
  #
  # @param token [String] токен для проверки
  # @return [Boolean] true если токен валиден
  # @api private
  def verify_auth_token(token)
    verifier = Rails.application.message_verifier(:telegram_auth)
    data = verifier.verify(token, purpose: :telegram_auth)
    data['type'] == 'auth_request'
  rescue ActiveSupport::MessageVerifier::InvalidSignature, ActiveSupport::MessageExpired
    false
  end

  # Генерирует confirm_token для авторизации на сайте
  #
  # @param telegram_user_id [Integer] ID пользователя Telegram
  # @return [String] подписанный токен
  # @api private
  def generate_confirm_token(telegram_user_id)
    verifier = Rails.application.message_verifier(:telegram_auth)
    verifier.generate({
      type: 'confirm',
      telegram_user_id: telegram_user_id,
      timestamp: Time.current.to_i
    }, purpose: :telegram_confirm, expires_in: ApplicationConfig.telegram_auth_expiration.seconds)
  end
end
```

**app/controllers/application_controller.rb (добавить helpers):**
```ruby
class ApplicationController < ActionController::Base
  # ... existing code ...

  helper_method :current_telegram_user, :telegram_user_signed_in?

  private

  # Возвращает текущего авторизованного пользователя
  #
  # @return [TelegramUser, nil] текущий пользователь или nil
  def current_telegram_user
    @current_telegram_user ||= TelegramUser.find_by(id: session[:telegram_user_id]) if session[:telegram_user_id]
  end

  # Проверяет авторизован ли пользователь
  #
  # @return [Boolean] true если пользователь авторизован
  def telegram_user_signed_in?
    current_telegram_user.present?
  end

  # Требует авторизации для доступа к экшену
  #
  # @return [void] редирект на root если не авторизован
  def authenticate_telegram_user!
    return if telegram_user_signed_in?

    redirect_to root_path, alert: 'Необходима авторизация через BossBot'
  end
end
```

### ApplicationConfig (добавить настройки для BossBot):

```ruby
# config/configs/application_config.rb

class ApplicationConfig < Anyway::Config
  # ... existing code ...

  # BossBot settings (для авторизации владельцев/менеджеров)
  attr_config :boss_bot_token,
              :boss_bot_username,
              :web_host, # хост веб-приложения для генерации ссылок (example.com)
              :telegram_auth_expiration # в секундах, default: 300 (5 минут)

  # ... existing code ...
end
```

**.env.sample (добавить):**
```bash
# BossBot (для авторизации владельцев/менеджеров)
BOSS_BOT_TOKEN=YOUR_BOSS_BOT_TOKEN
BOSS_BOT_USERNAME=valera_boss_bot
WEB_HOST=localhost:3000 # для development, в production - ваш домен
TELEGRAM_AUTH_EXPIRATION=300 # 5 минут
```

## ⚡ Implementation Plan (3-4 дня)

### **Phase 1: Database & Membership Model (День 1)**

**Утро (4 часа):**
- [ ] Создать модель Membership через `rails generate model`:
  ```bash
  rails generate model Membership \
    account:references \
    telegram_user:references \
    role:string
  ```
- [ ] Обновить миграцию Membership (unique index, defaults, NOT NULL)
- [ ] Создать миграцию для обновления TelegramUser:
  ```bash
  rails generate migration AddAuthFieldsToTelegramUsers \
    locale:string \
    last_login_at:datetime \
    last_login_from_ip:string
  ```
- [ ] Обновить миграцию (добавить defaults)
- [ ] `rails db:migrate`

**После обеда (4 часа):**
- [ ] Реализовать Membership model (валидации, enums, permissions)
- [ ] Обновить TelegramUser (добавить memberships, owned_accounts, методы)
- [ ] Обновить Account (добавить owner, memberships, members, callbacks)
- [ ] Написать тесты для Membership
- [ ] Написать тесты для TelegramUser (новые методы)
- [ ] Создать fixtures для Membership

### **Phase 2: BossBot Authentication (День 2)**

**Утро (4 часа):**
- [ ] Добавить настройки BossBot в ApplicationConfig (boss_bot_token, boss_bot_username, web_host)
- [ ] Создать контроллер Auth::TelegramController (login, confirm)
- [ ] Создать контроллер Telegram::BossBotController (webhook, /start)
- [ ] Добавить routes для авторизации (login, confirm, boss_bot webhook)
- [ ] Добавить helpers в ApplicationController (current_telegram_user, etc.)

**После обеда (4 часа):**
- [ ] Реализовать генерацию и верификацию токенов (message_verifier)
- [ ] Создать view со ссылкой "Войти через Telegram" на главной странице
- [ ] Реализовать создание Account при первом входе
- [ ] Добавить after_create callback в Account для add_owner_to_members
- [ ] Настроить webhook для BossBot
- [ ] Написать интеграционные тесты обоих flow авторизации
- [ ] Протестировать flow вручную с реальным BossBot

### **Phase 3: Dashboard & Memberships Management (День 3)**

**Утро (4 часа):**
- [ ] Создать Dashboard::AccountsController
- [ ] Создать Dashboard::MembershipsController
- [ ] Добавить views для списка аккаунтов
- [ ] Добавить views для управления командой (список членов)
- [ ] Реализовать добавление члена команды по telegram_user_id

**После обеда (4 часа):**
- [ ] Добавить форму добавления члена команды (поиск по username/id)
- [ ] Реализовать удаление члена команды
- [ ] Реализовать смену роли (admin/support)
- [ ] Добавить подтверждение критических действий
- [ ] Написать тесты для контроллеров
- [ ] Добавить интеграционные тесты для memberships flow

### **Phase 4: Authorization & Testing (День 4)**

**Утро (4 часа):**
- [ ] Создать concern Authorization для проверки прав
- [ ] Добавить before_action фильтры в контроллеры
- [ ] Реализовать разделение прав admin vs support
- [ ] Добавить scope для фильтрации по доступу пользователя
- [ ] Обновить все dashboard контроллеры для работы с memberships

**После обеда (4 часа):**
- [ ] End-to-end тестирование всего flow
- [ ] Написать документацию (как настроить BossBot, как управлять командой)
- [ ] Code review самого себя
- [ ] Обновить seeds.rb с примерами Membership
- [ ] Проверить все существующие тесты (должны проходить)

## 📊 Success Metrics & Acceptance Criteria

### **Technical Acceptance Criteria:**
- [ ] TelegramUser может быть owner нескольких Account'ов
- [ ] TelegramUser может быть member нескольких Account'ов через Membership
- [ ] Membership имеет роли: admin, support
- [ ] Owner автоматически добавляется в members при создании Account
- [ ] Авторизация через BossBot работает корректно (оба flow)
- [ ] Токены генерируются с TTL и подписываются (message_verifier)
- [ ] Токены верифицируются перед авторизацией
- [ ] Все существующие тесты проходят
- [ ] Новые тесты покрывают memberships и авторизацию (>90%)

### **Business Acceptance Criteria:**
- [ ] Владелец может авторизоваться через BossBot
- [ ] При первом входе автоматически создается Account
- [ ] Владелец может добавить менеджера в свою команду
- [ ] Менеджер с ролью admin имеет полный доступ к аккаунту
- [ ] Менеджер с ролью support имеет ограниченный доступ
- [ ] Владелец может удалить члена команды
- [ ] Владелец может изменить роль члена команды

### **Security Criteria:**
- [ ] Токены подписываются secret_key_base (невозможно подделать)
- [ ] Токены имеют ограниченный TTL (5 минут, configurable)
- [ ] Токены имеют purpose для разделения типов (telegram_auth, telegram_confirm)
- [ ] Только admin и owner могут управлять командой
- [ ] Support не может изменять настройки аккаунта
- [ ] Нет утечки данных между аккаунтами

## 🔗 Dependencies & Risks

### **Dependencies:**
- **FIP-002 (Multi-Tenancy)** - MUST быть реализован до начала FIP-003
- **BossBot** - нужно создать отдельного бота в BotFather
- **BossBot webhook** - настроить webhook для обработки /start команды
- **ApplicationConfig** - добавление настроек для BossBot (bot_token, web_host, etc.)
- **Rails message_verifier** - встроенная функциональность Rails для токенов

### **Technical Risks:**
- **TelegramUser в двух контекстах** - может быть путаница (клиент vs владелец)
- **Сложность permission logic** - нужны хорошие тесты
- **Breaking changes в Account** - может сломать существующий код из FIP-002

### **Mitigation Strategies:**
- **Четкая документация** - описать два использования TelegramUser
- **Comprehensive tests** - unit + integration + e2e
- **Incremental implementation** - поэтапное внедрение
- **Monitoring** - логирование всех операций авторизации

## 🔗 Связанные документы

### **Reference Projects:**
- **~/code/vilna** - Пример Membership и Telegram авторизации
- **FIP-002** - Multi-Tenancy (зависимость)

### **Internal Documentation:**
- **[Product Constitution](../product/constitution.md)** - Базовые принципы
- **[CLAUDE.md](../../CLAUDE.md)** - Правило про `rails generate model`
- **[Memory Bank](../../.claude/memory-bank.md)** - Архитектурные решения
- **[FLOW.md](../FLOW.md)** - Процесс работы

### **External Documentation:**
- **[Telegram Bot API - /start command](https://core.telegram.org/bots/features#deep-linking)** - Deep linking через /start
- **[Telegram Bot API](https://core.telegram.org/bots/api)** - API документация
- **[Rails MessageVerifier](https://api.rubyonrails.org/classes/ActiveSupport/MessageVerifier.html)** - Документация Rails

---

## ✅ Checklist перед началом

- [ ] FIP-002 (Multi-Tenancy) реализован и работает
- [ ] Создан BossBot в BotFather (@valera_boss_bot)
- [ ] Получен BOT_TOKEN для BossBot
- [ ] Понял что TelegramUser используется в двух контекстах (клиент + владелец)
- [ ] Понял разницу между Service Bots и BossBot
- [ ] Изучил vilna (Membership и Telegram auth)
- [ ] Готов использовать `rails generate model`

---

**Версия:** 1.0
**Дата создания:** 27.10.2025 02:00
**Тип документа:** Feature Implementation Plan (FIP)
**Статус:** Draft - ready for review

**Основные решения:**
- ✅ Два типа ботов: Service Bots (для клиентов) и BossBot (для владельцев)
- ✅ **БЕЗ модели User** - используем TelegramUser для всех
- ✅ TelegramUser работает в двух контекстах: клиент (через Chat) и владелец/менеджер (через Membership)
- ✅ Membership с ролями: admin, support
- ✅ **Авторизация через ссылки с токенами** (веб↔бот) вместо Telegram Login Widget
- ✅ Два flow авторизации: веб→бот→веб и бот→веб
- ✅ Токены с TTL (5 минут) и подписью (message_verifier)
- ✅ Owner автоматически добавляется в members при создании Account
- ✅ Account.owner_id указывает на TelegramUser
- ✅ Разделение прав: admin (полный доступ), support (ограниченный)
