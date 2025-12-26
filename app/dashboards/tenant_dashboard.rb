# frozen_string_literal: true

require 'administrate/base_dashboard'
require_relative '../fields/url_field'
require_relative '../fields/telegram_bot_field'
require_relative '../fields/counter_link_field'
require_relative '../fields/subdomain_field'
require_relative '../fields/secure_token_field'
require_relative '../fields/field_row_field'
require_relative '../fields/text_with_default_field'

class TenantDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    name: Field::String,
    subdomain: SubdomainField,
    dashboard_url: UrlField.with_options(link_text: ->(field) { "#{URI.parse(field.data).host} ↗" }),
    bot_username: TelegramBotField,
    bot_token: SecureTokenField,
    webhook_secret: Field::Password, # Hide sensitive secret
    admin_chat_id: Field::Number,
    owner: Field::BelongsTo,
    manager: Field::BelongsTo,
    owner_and_manager: FieldRowField.with_options(
      fields: %i[owner manager],
      field_types: { owner: Field::BelongsTo, manager: Field::BelongsTo }
    ),
    company_info: TextWithDefaultField.with_options(
      default_method: :company_info_or_default,
      rows: 30,
      hint: 'Название, адрес, телефон, email, реквизиты, время работы — всё что AI должен знать о компании'
    ),
    price_list: TextWithDefaultField.with_options(
      default_method: :price_list_or_default,
      rows: 30,
      hint: 'CSV формат: услуга, цена по классам авто. AI использует для расчёта стоимости'
    ),
    system_prompt: TextWithDefaultField.with_options(
      default_method: :system_prompt_or_default,
      rows: 30,
      hint: '<strong>Доступные переменные:</strong> ' \
            '<code>{{COMPANY_INFO}}</code> — информация о компании, ' \
            '<code>{{PRICE_LIST}}</code> — прайс-лист, ' \
            '<code>{{CURRENT_TIME}}</code> — текущее время'
    ),
    welcome_message: TextWithDefaultField.with_options(
      default_method: :welcome_message_or_default,
      rows: 30,
      hint: 'Первое сообщение при старте диалога. Поддерживает Markdown форматирование'
    ),
    clients: Field::HasMany,
    chats: Field::HasMany,
    chats_count: CounterLinkField.with_options(resource_name: :chats),
    clients_count: CounterLinkField.with_options(resource_name: :clients),
    bookings_count: CounterLinkField.with_options(resource_name: :bookings),
    last_message_at: Field::DateTime,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    name
    dashboard_url
    bot_username
    chats_count
    clients_count
    bookings_count
    owner
    manager
    last_message_at
  ].freeze

  SHOW_PAGE_ATTRIBUTES = {
    "" => %i[
      id
      name
      subdomain
      dashboard_url
      chats_count
      clients_count
      bookings_count
      last_message_at
      owner
      manager
      created_at
      updated_at
    ],
    "Telegram" => %i[
      bot_username
      bot_token
      webhook_secret
      admin_chat_id
    ],
    "Информация о компании" => %i[company_info],
    "Прайс-лист" => %i[price_list],
    "Приветствие" => %i[welcome_message],
    "Системный промпт" => %i[system_prompt]
  }.freeze

  FORM_ATTRIBUTES = {
    "Основное" => %i[
      name
      subdomain
      owner_and_manager
    ],
    "Telegram" => %i[
      bot_token
      bot_username
      admin_chat_id
    ],
    "Информация о компании" => %i[company_info],
    "Прайс-лист" => %i[price_list],
    "Приветствие" => %i[welcome_message],
    "Системный промпт" => %i[system_prompt]
  }.freeze

  COLLECTION_FILTERS = {}.freeze

  def display_resource(tenant)
    tenant.name
  end
end
