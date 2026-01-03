# frozen_string_literal: true

# Demo data seeder for dashboard testing
#
# Creates realistic demo data from LLM-generated dialogs:
# - db/seeds/generated_dialogs/*.yml (100+ dialogs by customer profile)
#
# Usage: Called from db/seeds.rb in development environment
#
# @see docs/product/customer-profiles.md for profile definitions
# @see db/seeds/README.md for LLM generator documentation

class DemoDataSeeder
  GENERATED_DIALOGS_DIR = Rails.root.join('db/seeds/generated_dialogs')

  def initialize(tenant)
    @tenant = tenant || raise('No tenant')
    @model = find_or_create_model
    @stats = { clients: 0, chats: 0, messages: 0, bookings: 0, vehicles: 0 }
  end

  def seed!
    Rails.logger.info '[DemoData] Starting demo data seeding...'

    dialogs = load_dialogs
    if dialogs.empty?
      Rails.logger.warn '[DemoData] No dialogs found in YAML file'
      return
    end

    ActiveRecord::Base.transaction do
      dialogs.each_with_index do |dialog_data, index|
        process_dialog(dialog_data, index)
        print_progress(index + 1, dialogs.size)
      end
    end

    print_summary
  end

  private

  def load_dialogs
    dialogs = load_generated_dialogs
    Rails.logger.info "[DemoData] Loaded #{dialogs.size} dialogs"
    dialogs
  end

  def load_generated_dialogs
    return [] unless Dir.exist?(GENERATED_DIALOGS_DIR)

    dialogs = []
    Dir.glob(GENERATED_DIALOGS_DIR.join('*.yml')).each do |file|
      next if File.basename(file) == '.gitkeep'

      data = YAML.load_file(file, permitted_classes: [Symbol, Time, DateTime])
      file_dialogs = data[:dialogs] || data['dialogs'] || []
      dialogs += file_dialogs.map { |d| normalize_dialog(d) }
    rescue StandardError => e
      Rails.logger.error "[DemoData] Error loading #{file}: #{e.message}"
    end

    Rails.logger.info "[DemoData] Loaded #{dialogs.size} generated dialogs from #{GENERATED_DIALOGS_DIR}"
    dialogs
  end

  # Normalize dialog from YAML to unified structure
  def normalize_dialog(dialog)
    profile = dialog[:profile]&.to_s || 'one_time_client'
    messages = (dialog[:messages] || []).map do |msg|
      {
        'role' => msg[:role]&.to_s,
        'content' => msg[:content]&.to_s
      }
    end

    # Generate client name from profile
    client_name = generate_client_name_from_profile(profile)

    {
      'profile' => profile,
      'client' => {
        'first_name' => client_name[:first],
        'last_name' => client_name[:last],
        'username' => "gen_#{dialog[:id]&.to_s&.first(8) || SecureRandom.hex(4)}"
      },
      'messages' => messages,
      'has_booking' => dialog[:booking_expected] == true,
      'booking_details' => "Заявка от #{profile.humanize}",
      'created_days_ago' => rand(1..30)
    }
  end

  # Generate realistic Russian names based on profile
  def generate_client_name_from_profile(profile)
    first_names = {
      male: %w[Александр Дмитрий Максим Артём Иван Михаил Даниил Кирилл Андрей Егор],
      female: %w[Анна Мария Елена Ольга Наталья Екатерина Татьяна Светлана Ирина Юлия]
    }
    last_names = %w[Иванов Петров Сидоров Козлов Новиков Морозов Волков Соколов Лебедев Попов]

    # Some profiles suggest gender
    gender = case profile
             when 'emotional_female_client' then :female
             when 'busy_businessman', 'tech_savvy_client' then :male
             else %i[male female].sample
             end

    {
      first: first_names[gender].sample,
      last: last_names.sample + (gender == :female ? 'а' : '')
    }
  end

  def process_dialog(dialog_data, index)
    client_data = dialog_data['client'] || {}
    vehicle_data = dialog_data['vehicle']
    messages_data = dialog_data['messages'] || []
    created_days_ago = dialog_data['created_days_ago'] || rand(1..30)

    # Create telegram user
    telegram_user = find_or_create_telegram_user(client_data, index)

    # Create client
    client = find_or_create_client(telegram_user, client_data)

    # Create vehicle if specified
    vehicle = create_vehicle(client, vehicle_data) if vehicle_data

    # Create chat with messages
    chat = create_chat_with_messages(client, messages_data, created_days_ago)

    # Create booking if specified
    create_booking(client, chat, vehicle, dialog_data, created_days_ago) if dialog_data['has_booking']
  end

  def find_or_create_telegram_user(client_data, index)
    username = client_data['username'] || "demo_user_#{index}"
    first_name = client_data['first_name'] || "Demo#{index}"
    last_name = client_data['last_name']

    tg_user = TelegramUser.find_or_create_by!(username: "demo_#{username}") do |u|
      u.first_name = first_name
      u.last_name = last_name
    end

    # Update name if changed
    if tg_user.first_name != first_name || tg_user.last_name != last_name
      tg_user.update!(first_name: first_name, last_name: last_name)
    end

    tg_user
  end

  def find_or_create_client(telegram_user, client_data)
    client = Client.find_or_create_by!(tenant: @tenant, telegram_user: telegram_user) do |c|
      c.name = build_client_name(client_data, telegram_user)
      c.phone = client_data['phone']
    end

    @stats[:clients] += 1 if client.previously_new_record?
    client
  end

  def build_client_name(client_data, telegram_user)
    first = client_data['first_name'] || telegram_user.first_name
    last = client_data['last_name'] || telegram_user.last_name
    [first, last].compact.join(' ').presence
  end

  def create_vehicle(client, vehicle_data)
    return nil unless vehicle_data

    vehicle = Vehicle.find_or_create_by!(
      client: client,
      brand: vehicle_data['brand'],
      model: vehicle_data['model']
    ) do |v|
      v.year = vehicle_data['year']
      v.vin = vehicle_data['vin']
      v.plate_number = vehicle_data['plate_number']
    end

    @stats[:vehicles] += 1 if vehicle.previously_new_record?
    vehicle
  end

  def create_chat_with_messages(client, messages_data, created_days_ago)
    chat = Chat.find_or_create_by!(tenant: @tenant, client: client)
    @stats[:chats] += 1 if chat.previously_new_record?

    return chat if messages_data.empty?

    # Skip if chat already has messages (idempotent)
    return chat if chat.messages.exists?

    base_time = created_days_ago.days.ago + rand(0..12).hours
    messages_data.each_with_index do |msg_data, msg_index|
      create_message(chat, msg_data, base_time, msg_index)
    end

    chat
  end

  def create_message(chat, msg_data, base_time, msg_index)
    # Calculate timestamp with realistic intervals
    message_time = base_time + (msg_index * rand(30..180).seconds)

    chat.messages.create!(
      role: msg_data['role'],
      content: msg_data['content'],
      model: @model,
      created_at: message_time
    )

    @stats[:messages] += 1
  end

  def create_booking(client, chat, vehicle, dialog_data, created_days_ago)
    details = dialog_data['booking_details'] || "Demo booking for #{client.display_name}"

    # Skip if booking with same details already exists (idempotent)
    return if Booking.exists?(tenant: @tenant, client: client, details: details)

    booking_time = created_days_ago.days.ago + rand(1..23).hours

    # Use insert_all to skip callbacks (notifications, jobs)
    # Then reload to get the created record
    booking_attrs = {
      tenant_id: @tenant.id,
      client_id: client.id,
      chat_id: chat.id,
      vehicle_id: vehicle&.id,
      details: details,
      number: (@tenant.bookings.maximum(:number) || 0) + 1,
      created_at: booking_time,
      updated_at: booking_time
    }
    booking_attrs[:public_number] = "#{@tenant.id}-#{booking_attrs[:number]}"

    Booking.insert!(booking_attrs)

    # Update chat booking timestamps manually
    Chat.where(id: chat.id).update_all([
      'first_booking_at = COALESCE(first_booking_at, ?), last_booking_at = ?',
      booking_time, booking_time
    ])

    @stats[:bookings] += 1
  end

  def find_or_create_model
    Model.find_or_create_by!(
      provider: ApplicationConfig.llm_provider,
      model_id: ApplicationConfig.llm_model
    ) do |m|
      m.name = ApplicationConfig.llm_model
    end
  end

  def print_progress(current, total)
    progress = (current.to_f / total * 100).round
    print "\r[DemoData] Progress: #{current}/#{total} (#{progress}%)"
    puts if current == total
  end

  def print_summary
    Rails.logger.info <<~SUMMARY
      [DemoData] Demo data seeding completed!
      [DemoData] Stats:
        - Clients: #{@stats[:clients]}
        - Chats: #{@stats[:chats]}
        - Messages: #{@stats[:messages]}
        - Bookings: #{@stats[:bookings]}
        - Vehicles: #{@stats[:vehicles]}
    SUMMARY
  end

  # Class method for easy invocation
  def self.seed!(tenant)
    new(tenant).seed!
  end
end

# Module for additional historical data generation
module DemoHistoricalData
  # Generate additional messages spread over time for activity charts
  def self.generate!(tenant, days: 30, daily_messages: 5..15)
    return unless tenant

    model = Model.find_by(
      provider: ApplicationConfig.llm_provider,
      model_id: ApplicationConfig.llm_model
    )
    return unless model

    clients = tenant.clients.includes(:chats).to_a
    return if clients.empty?

    # Skip if we already have enough historical messages (idempotent)
    existing_historical_count = Message.joins(chat: :client)
                                       .where(clients: { tenant_id: tenant.id })
                                       .where('messages.created_at < ?', 1.day.ago)
                                       .count
    if existing_historical_count > 100
      Rails.logger.info "[DemoData] Historical messages already exist (#{existing_historical_count}), skipping generation"
      return
    end

    Rails.logger.info "[DemoData] Generating historical messages for #{days} days..."

    messages_created = 0

    (1..days).each do |days_ago|
      message_count = rand(daily_messages)
      next if message_count.zero?

      client = clients.sample
      chat = client.chats.first
      next unless chat

      message_count.times do |i|
        created_at = days_ago.days.ago + rand(8..20).hours + rand(0..59).minutes
        role = i.even? ? 'user' : 'assistant'
        content = generate_historical_content(role, i)

        chat.messages.create!(
          role: role,
          content: content,
          model: model,
          created_at: created_at
        )
        messages_created += 1
      end
    end

    Rails.logger.info "[DemoData] Created #{messages_created} historical messages"
  end

  def self.generate_historical_content(role, index)
    if role == 'user'
      user_messages = [
        'Подскажите по стоимости ремонта',
        'Когда можно записаться?',
        'А сколько времени займет работа?',
        'Какие гарантии даете?',
        'Можно приехать без записи?',
        'Работаете в выходные?',
        'А оригинальные запчасти используете?',
        'Скиньте адрес пожалуйста'
      ]
      user_messages[index % user_messages.size]
    else
      assistant_messages = [
        'Здравствуйте! С удовольствием помогу вам.',
        'Стоимость зависит от объема работ, давайте уточним детали.',
        'Работа займет от 2 до 4 часов.',
        'Даем гарантию на все виды работ.',
        'Лучше записаться заранее, но можно и без записи.',
        'Да, работаем ежедневно с 9 до 20.',
        'Используем как оригинальные, так и качественные аналоги.',
        'Наш адрес: ул. Автосервисная, 15. Ждем вас!'
      ]
      assistant_messages[index % assistant_messages.size]
    end
  end
end
