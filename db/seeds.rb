# frozen_string_literal: true

# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

Rails.logger.info '[Seeds] Starting database seeding...'

# =============================================================================
# Global Chat Topics (дефолтные темы для классификации диалогов)
# =============================================================================
Rails.logger.info '[Seeds] Creating global chat topics...'

DEFAULT_CHAT_TOPICS = [
  { key: 'service_booking', label: 'Запись на обслуживание' },
  { key: 'price_inquiry', label: 'Запрос цены/стоимости' },
  { key: 'diagnostics', label: 'Диагностика/проверка' },
  { key: 'repair', label: 'Ремонт' },
  { key: 'parts', label: 'Запчасти/расходники' },
  { key: 'schedule', label: 'График работы/адрес' },
  { key: 'feedback', label: 'Отзыв/жалоба' },
  { key: 'general_question', label: 'Общий вопрос' },
  { key: 'other', label: 'Другое' }
].freeze

DEFAULT_CHAT_TOPICS.each do |topic_data|
  ChatTopic.find_or_create_by!(key: topic_data[:key], tenant_id: nil) do |topic|
    topic.label = topic_data[:label]
    topic.active = true
  end
end

Rails.logger.info "[Seeds] Created #{DEFAULT_CHAT_TOPICS.size} global chat topics"

# Создаём владельца для default tenant
owner = User.find_or_create_by!(email: 'tenant@super-valera.ru') do |user|
  user.name = 'Администратор Super Valera'
end

# В development устанавливаем пароль для удобства тестирования
if Rails.env.development? && owner.password_digest.blank?
  owner.update!(password: 'password')
  Rails.logger.info "[Seeds] Owner password set to 'password'"
end
Rails.logger.info "[Seeds] Owner user: #{owner.email} (id: #{owner.id})"

# В multi-tenant режиме tenants создаются через UI/API с реальным bot_token
# Для development можно создать tenant вручную:
#   Tenant.create!(name: 'Dev Tenant', owner: owner, bot_token: 'YOUR_BOT_TOKEN')

# Попытка получить bot_token из ENV (для development/staging)
bot_token = ENV.fetch('TELEGRAM_BOT_TOKEN', nil)

if bot_token.present?
  tenant = Tenant.create_with(name: 'Кузник', owner: owner).find_or_create_by!(bot_token: bot_token)
  Rails.logger.info "[Seeds] Tenant created: #{tenant.name} (key: #{tenant.key}, bot: @#{tenant.bot_username})"
elsif Rails.env.development? || Rails.env.test?
  # В development/test создаём tenant с фейковым токеном (без обращения к Telegram API)
  fake_token = "123456789:fake_dev_token_#{SecureRandom.hex(8)}"
  tenant = Tenant.find_by(key: 'dev') || Tenant.new(
    name: 'Dev Автосервис',
    key: 'dev',
    owner: owner,
    bot_token: fake_token,
    bot_username: 'dev_valera_bot'
  )

  if tenant.new_record?
    # Пропускаем fetch_bot_username callback для фейкового токена
    tenant.class.skip_callback(:validation, :before, :fetch_bot_username, raise: false)
    tenant.save!
    tenant.class.set_callback(:validation, :before, :fetch_bot_username, if: :should_fetch_bot_username?)
    Rails.logger.info "[Seeds] Dev tenant created: #{tenant.name} (key: #{tenant.key}, bot: @#{tenant.bot_username})"
  else
    Rails.logger.info "[Seeds] Dev tenant exists: #{tenant.name} (key: #{tenant.key})"
  end
else
  tenant = Tenant.first
  Rails.logger.info '[Seeds] TELEGRAM_BOT_TOKEN not set, using existing tenant' if tenant
end

# Create default admin user for development/staging
# IMPORTANT: Change password in production!
AdminUser.find_or_create_by!(email: 'admin@example.com') do |admin|
  admin.name = 'Главный Администратор'
  admin.password = 'password'
  admin.password_confirmation = 'password'
  admin.role = :superuser
end
Rails.logger.info '[Seeds] Default AdminUser created: admin@example.com / password (superuser)'

# =============================================================================
# Dashboard Demo Data (для визуализации dashboard с заполненными данными)
# =============================================================================
if tenant && Rails.env.development?
  # Load demo data seeder
  require_relative 'seeds/demo_data'

  # Create demo data from YAML file
  DemoDataSeeder.seed!(tenant)

  # Generate additional historical messages for activity charts
  DemoHistoricalData.generate!(tenant, days: 30, daily_messages: 5..15)
end

Rails.logger.info '[Seeds] Database seeding completed!'
