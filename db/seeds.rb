# frozen_string_literal: true

# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

Rails.logger.info '[Seeds] Starting database seeding...'

# Создаём владельца для default tenant
owner = User.find_or_create_by!(email: 'tenant@super-valera.ru') do |user|
  user.name = 'Администратор Super Valera'
end
Rails.logger.info "[Seeds] Owner user: #{owner.email} (id: #{owner.id})"

# В multi-tenant режиме tenants создаются через UI/API с реальным bot_token
# Для development можно создать tenant вручную:
#   Tenant.create!(name: 'Dev Tenant', owner: owner, bot_token: 'YOUR_BOT_TOKEN')

Rails.logger.info '[Seeds] Database seeding completed!'
Rails.logger.info '[Seeds] Note: Create tenants via UI or console with real bot_token'
