# frozen_string_literal: true

# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

Rails.logger.info '[Seeds] Starting database seeding...'

require_relative 'seeds/chat_topics'

# Создаём владельца для demo tenant
owner = User.
  create_with(name: 'Администратор Super Valera', password: ENV.fetch('TENANT_DEMO_USER_PASSWORD', 'password')).
  find_or_create_by!(email: ENV.fetch('TENANT_DEMO_USER_EMAIL', 'tenant@super-valera.ru'))
Rails.logger.info "[Seeds] Owner: #{owner.email} (id: #{owner.id})"

# =============================================================================
# Demo Tenant (для демонстрации и тестирования dashboard)
# =============================================================================
# Создаём demo tenant с фейковым токеном (без обращения к Telegram API)
# Callback fetch_bot_username пропускается т.к. bot_username уже указан и new_record? = true
demo_tenant = Tenant.create_with(
  name: 'Demo Автосервис',
  owner: owner,
  bot_token: '123456789:fake_demo_token',
  bot_username: 'demo_valera_bot'
).find_or_create_by!(key: 'demo')
Rails.logger.info "[Seeds] Demo tenant: #{demo_tenant.name} (key: #{demo_tenant.key}, bot: @#{demo_tenant.bot_username})"

# Create default admin user for development/staging
# IMPORTANT: Change password in production!
admin = AdminUser.create_with(
  name: 'Главный Администратор',
  password: ENV.fetch('ADMIN_PASSWORD', 'password'),
  password_confirmation: ENV.fetch('ADMIN_PASSWORD', 'password'),
  role: :superuser
).find_or_create_by!(email: ENV.fetch('ADMIN_EMAIL', 'admin@example.com'))
Rails.logger.info "[Seeds] AdminUser: #{admin.email} (#{admin.role})"

# =============================================================================
# Dashboard Demo Data (для визуализации dashboard с заполненными данными)
# Сидируется только для demo tenant, безопасно для production
# =============================================================================
require_relative 'seeds/demo_data'
DemoDataSeeder.seed!(demo_tenant) if demo_tenant.clients.size < 10

# Уже сидировали из yaml
# DemoHistoricalData.generate!(demo_tenant, days: 30, daily_messages: 5..15)

Rails.logger.info '[Seeds] Database seeding completed!'
