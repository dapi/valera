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
  Rails.logger.info '[Seeds] Creating dashboard demo data...'

  # Создаём Model для сообщений (если не существует)
  model = Model.find_or_create_by!(
    provider: ApplicationConfig.llm_provider,
    model_id: ApplicationConfig.llm_model
  ) do |m|
    m.name = ApplicationConfig.llm_model
  end

  # Имена клиентов для demo
  client_names = [
    { first: 'Иван', last: 'Петров', username: 'ivan_petrov' },
    { first: 'Мария', last: 'Сидорова', username: 'maria_s' },
    { first: 'Алексей', last: 'Козлов', username: 'alex_kozlov' },
    { first: 'Елена', last: 'Новикова', username: 'elena_n' },
    { first: 'Дмитрий', last: 'Морозов', username: 'dmitry_m' },
    { first: 'Анна', last: 'Волкова', username: 'anna_volkova' },
    { first: 'Сергей', last: 'Лебедев', username: 'sergey_l' },
    { first: 'Ольга', last: 'Кузнецова', username: 'olga_k' }
  ]

  # Создаём клиентов с разными датами (для статистики)
  clients = client_names.map.with_index do |name_data, index|
    tg_user = TelegramUser.find_or_create_by!(username: "demo_#{name_data[:username]}") do |u|
      u.first_name = name_data[:first]
      u.last_name = name_data[:last]
    end

    # Разброс дат создания: часть сегодня, часть за неделю, часть раньше
    created_at = case index
    when 0..1 then Time.current - rand(0..12).hours  # сегодня
    when 2..4 then Time.current - rand(1..6).days    # за неделю
    else Time.current - rand(8..30).days              # раньше
    end

    client = Client.find_or_create_by!(tenant: tenant, telegram_user: tg_user) do |c|
      c.name = "#{name_data[:first]} #{name_data[:last]}"
      c.phone = "+7(9#{rand(10..99)})#{rand(100..999)}-#{rand(10..99)}-#{rand(10..99)}"
    end
    client.update_column(:created_at, created_at) if client.created_at > created_at
    client
  end

  Rails.logger.info "[Seeds] Created #{clients.size} demo clients"

  # Примеры диалогов
  conversations = [
    {
      messages: [
        { role: 'user', content: 'Здравствуйте! Хочу записаться на ТО для своей машины' },
        { role: 'assistant', content: 'Добрый день! Конечно, помогу вам записаться. Какая у вас марка и модель автомобиля?' },
        { role: 'user', content: 'Toyota Camry 2020 года' },
        { role: 'assistant', content: 'Отлично! Для Toyota Camry 2020 рекомендую плановое ТО. Когда вам будет удобно приехать?' },
        { role: 'user', content: 'Можно в субботу утром?' },
        { role: 'assistant', content: 'Записал вас на субботу на 10:00. Адрес: ул. Автосервисная, 15. Ждём вас!' }
      ],
      created_ago: rand(1..4).hours
    },
    {
      messages: [
        { role: 'user', content: 'Добрый день, у меня загорелся check engine' },
        { role: 'assistant', content: 'Здравствуйте! Check Engine может указывать на разные проблемы. Можете подъехать на диагностику?' },
        { role: 'user', content: 'Да, когда можно?' },
        { role: 'assistant', content: 'Сегодня есть окно в 15:00. Диагностика займёт около 30 минут. Подходит?' }
      ],
      created_ago: rand(5..12).hours
    },
    {
      messages: [
        { role: 'user', content: 'Сколько стоит замена масла?' },
        { role: 'assistant', content: 'Замена масла от 2500₽ (включая масло и фильтр). Цена зависит от марки автомобиля. Какая у вас машина?' },
        { role: 'user', content: 'Kia Rio 2019' },
        { role: 'assistant', content: 'Для Kia Rio замена масла обойдётся в 2800₽. Записать вас?' }
      ],
      created_ago: rand(1..2).days
    }
  ]

  # Создаём чаты с сообщениями
  conversations.each_with_index do |conv_data, index|
    client = clients[index % clients.size]
    chat = Chat.find_or_create_by!(tenant: tenant, client: client)

    # Очищаем старые demo сообщения
    chat.messages.where("content LIKE '%demo%' OR content LIKE '%ТО%' OR content LIKE '%check engine%'").destroy_all

    base_time = Time.current - conv_data[:created_ago]
    conv_data[:messages].each_with_index do |msg_data, msg_index|
      chat.messages.create!(
        role: msg_data[:role],
        content: msg_data[:content],
        model: model,
        created_at: base_time + (msg_index * 2.minutes)
      )
    end
  end

  Rails.logger.info "[Seeds] Created #{conversations.size} demo conversations"

  # Создаём bookings
  booking_data = [
    { details: 'Плановое ТО для Toyota Camry', created_ago: 2.hours },
    { details: 'Диагностика двигателя BMW X5', created_ago: 1.day },
    { details: 'Замена тормозных колодок Hyundai Solaris', created_ago: 3.days }
  ]

  bookings_created = 0
  booking_data.each_with_index do |data, index|
    client = clients[index % clients.size]
    chat = client.chats.first || Chat.create!(tenant: tenant, client: client)

    existing = Booking.exists?(tenant: tenant, client: client, details: data[:details])
    next if existing

    booking = Booking.create!(
      tenant: tenant,
      client: client,
      chat: chat,
      details: data[:details]
    )
    booking.update_column(:created_at, Time.current - data[:created_ago])
    bookings_created += 1
  end

  Rails.logger.info "[Seeds] Created #{bookings_created} demo bookings"

  # Создаём дополнительные сообщения для графика активности (за последние 7-30 дней)
  (1..30).each do |days_ago|
    # Случайное количество сообщений в день (от 0 до 15)
    message_count = rand(0..15)
    next if message_count.zero?

    client = clients.sample
    chat = client.chats.first || Chat.create!(tenant: tenant, client: client)

    message_count.times do |i|
      created_at = days_ago.days.ago + rand(0..23).hours + rand(0..59).minutes
      role = i.even? ? 'user' : 'assistant'
      content = role == 'user' ? "Тестовое сообщение #{i + 1}" : "Ответ бота #{i + 1}"

      chat.messages.create!(
        role: role,
        content: content,
        model: model,
        created_at: created_at
      )
    end
  end

  Rails.logger.info '[Seeds] Created historical messages for activity chart'
end

Rails.logger.info '[Seeds] Database seeding completed!'
