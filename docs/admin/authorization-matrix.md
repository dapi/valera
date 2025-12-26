# Матрица авторизации Admin Panel

**Дата обновления:** 2025-12-26

## Роли AdminUser

| Роль | Код | Описание |
|------|-----|----------|
| **Manager** | 0 | Базовый администратор с ограниченными правами |
| **Superuser** | 1 | Полный доступ ко всем функциям |

## Матрица доступа по ресурсам

### Легенда

| Символ | Значение |
|--------|----------|
| ✅ | Полный доступ (CRUD) |
| 👁️ | Только просмотр (index, show) |
| 🔒 | Только свой профиль |
| ❌ | Нет доступа |

### Права доступа

| Ресурс | Manager | Superuser | Примечания |
|--------|---------|-----------|------------|
| **AdminUsers** | 👁️ + 🔒 edit | ✅ | Manager: index/show всех, edit/update только себя, НЕ может менять role |
| **Impersonations** | ❌ | ✅ | Только superuser может входить под другим пользователем |
| **Tenants** | ✅ | ✅ | Полный CRUD |
| **Leads** | ✅ | ✅ | Полный CRUD |
| **Users** | 👁️ | ✅ | Manager: только просмотр |
| **TenantMemberships** | 👁️ | ✅ | Manager: только просмотр |
| **TenantInvites** | 👁️ | 👁️ | Read-only для всех (через routes) |
| **Clients** | 👁️ | 👁️ | Read-only для всех (через routes) |
| **Chats** | 👁️ | 👁️ | Read-only для всех (через routes) |
| **Vehicles** | 👁️ | 👁️ | Read-only для всех (через routes) |
| **Bookings** | 👁️ | 👁️ | Read-only для всех (через routes) |
| **TelegramUsers** | 👁️ | 👁️ | Read-only для всех (через routes) |

## Детальная матрица по actions

### AdminUsers

| Action | Manager | Superuser |
|--------|---------|-----------|
| index | ✅ | ✅ |
| show | ✅ | ✅ |
| new | ❌ | ✅ |
| create | ❌ | ✅ |
| edit | 🔒 только себя | ✅ |
| update | 🔒 только себя | ✅ |
| destroy | ❌ | ✅ |
| **role field** | ❌ не может менять | ✅ |

### Users, TenantMemberships

| Action | Manager | Superuser |
|--------|---------|-----------|
| index | ✅ | ✅ |
| show | ✅ | ✅ |
| new | ❌ | ✅ |
| create | ❌ | ✅ |
| edit | ❌ | ✅ |
| update | ❌ | ✅ |
| destroy | ❌ | ✅ |

### Tenants, Leads (полный CRUD)

| Action | Manager | Superuser |
|--------|---------|-----------|
| index | ✅ | ✅ |
| show | ✅ | ✅ |
| new | ✅ | ✅ |
| create | ✅ | ✅ |
| edit | ✅ | ✅ |
| update | ✅ | ✅ |
| destroy | ✅ | ✅ |

### Read-only ресурсы (через routes)

Следующие ресурсы ограничены на уровне routes (`only: %i[index show]`):

- Clients
- Chats
- Vehicles
- Bookings
- TelegramUsers
- TenantInvites

## Реализация

### Базовый метод авторизации

```ruby
# app/controllers/admin/application_controller.rb
def authorize_superuser!
  user_to_check = impersonating? ? original_admin_user : current_admin_user
  return if user_to_check&.superuser?
  redirect_to admin_root_path, alert: 'Access denied. Superuser privileges required.'
end
```

### Применение в контроллерах

```ruby
# Полная блокировка write-actions для manager
before_action :authorize_superuser!, only: %i[new create edit update destroy]

# Только создание и удаление для superuser
before_action :authorize_superuser!, only: %i[new create destroy]
```

### Защита поля role

```ruby
# app/controllers/admin/admin_users_controller.rb
def resource_params
  params_hash = super
  params_hash.delete(:role) unless current_admin_user&.superuser?
  params_hash
end
```

## Файлы конфигурации

| Файл | Назначение |
|------|------------|
| `app/controllers/admin/application_controller.rb` | Базовый метод `authorize_superuser!` |
| `app/controllers/admin/admin_users_controller.rb` | Авторизация AdminUsers |
| `app/controllers/admin/users_controller.rb` | Авторизация Users |
| `app/controllers/admin/tenant_memberships_controller.rb` | Авторизация TenantMemberships |
| `app/controllers/admin/impersonations_controller.rb` | Авторизация имперсонации |
| `config/routes.rb` | Read-only routes для некоторых ресурсов |

## Тесты

- `test/controllers/admin/admin_users_controller_test.rb`
- `test/controllers/admin/manager_authorization_test.rb`
- `test/controllers/admin/impersonations_controller_test.rb`
