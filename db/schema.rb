# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2025_12_19_193913) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "analytics_events", force: :cascade do |t|
    t.bigint "chat_id", null: false
    t.datetime "created_at", null: false
    t.string "event_name", limit: 50, null: false
    t.datetime "occurred_at", precision: nil, null: false
    t.string "platform", limit: 20, default: "telegram"
    t.jsonb "properties", default: {}, null: false
    t.string "session_id", limit: 64
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["chat_id", "event_name", "occurred_at"], name: "idx_analytics_funnel"
    t.index ["chat_id"], name: "index_analytics_events_on_chat_id"
    t.index ["event_name", "occurred_at"], name: "idx_analytics_events_by_type"
    t.index ["event_name"], name: "index_analytics_events_on_event_name"
    t.index ["occurred_at", "event_name"], name: "idx_analytics_timeline"
    t.index ["occurred_at"], name: "index_analytics_events_on_occurred_at"
    t.index ["properties"], name: "index_analytics_events_on_properties", using: :gin
    t.index ["session_id"], name: "index_analytics_events_on_session_id"
    t.index ["tenant_id"], name: "index_analytics_events_on_tenant_id"
  end

  create_table "bookings", force: :cascade do |t|
    t.bigint "chat_id"
    t.bigint "client_id", null: false
    t.text "context"
    t.datetime "created_at", null: false
    t.text "details"
    t.jsonb "meta", default: {}, null: false
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "vehicle_id"
    t.index ["chat_id"], name: "index_bookings_on_chat_id"
    t.index ["client_id"], name: "index_bookings_on_client_id"
    t.index ["tenant_id"], name: "index_bookings_on_tenant_id"
    t.index ["vehicle_id"], name: "index_bookings_on_vehicle_id"
  end

  create_table "chats", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.datetime "created_at", null: false
    t.bigint "model_id"
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_chats_on_client_id"
    t.index ["model_id"], name: "index_chats_on_model_id"
    t.index ["tenant_id"], name: "index_chats_on_tenant_id"
  end

  create_table "clients", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.string "phone"
    t.bigint "telegram_user_id", null: false
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["telegram_user_id"], name: "index_clients_on_telegram_user_id"
    t.index ["tenant_id", "telegram_user_id"], name: "index_clients_on_tenant_id_and_telegram_user_id", unique: true
    t.index ["tenant_id"], name: "index_clients_on_tenant_id"
  end

  create_table "messages", force: :cascade do |t|
    t.bigint "chat_id", null: false
    t.text "content"
    t.datetime "created_at", null: false
    t.integer "input_tokens"
    t.bigint "model_id"
    t.integer "output_tokens"
    t.string "role", null: false
    t.bigint "tool_call_id"
    t.datetime "updated_at", null: false
    t.index ["chat_id", "created_at"], name: "idx_messages_chat_created_at"
    t.index ["chat_id", "role"], name: "idx_messages_chat_role"
    t.index ["chat_id"], name: "index_messages_on_chat_id"
    t.index ["model_id"], name: "index_messages_on_model_id"
    t.index ["role"], name: "index_messages_on_role"
    t.index ["tool_call_id"], name: "index_messages_on_tool_call_id"
  end

  create_table "models", force: :cascade do |t|
    t.jsonb "capabilities", default: []
    t.integer "context_window"
    t.datetime "created_at", null: false
    t.string "family"
    t.date "knowledge_cutoff"
    t.integer "max_output_tokens"
    t.jsonb "metadata", default: {}
    t.jsonb "modalities", default: {}
    t.datetime "model_created_at"
    t.string "model_id", null: false
    t.string "name", null: false
    t.jsonb "pricing", default: {}
    t.string "provider", null: false
    t.datetime "updated_at", null: false
    t.index ["capabilities"], name: "index_models_on_capabilities", using: :gin
    t.index ["family"], name: "index_models_on_family"
    t.index ["modalities"], name: "index_models_on_modalities", using: :gin
    t.index ["provider", "model_id"], name: "index_models_on_provider_and_model_id", unique: true
    t.index ["provider"], name: "index_models_on_provider"
  end

  create_table "telegram_users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "photo_url"
    t.datetime "updated_at", null: false
    t.string "username"
  end

  create_table "tenants", force: :cascade do |t|
    t.bigint "admin_chat_id"
    t.string "bot_token", null: false
    t.string "bot_username", null: false
    t.text "company_info"
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.string "name"
    t.bigint "owner_id"
    t.text "price_list"
    t.text "system_prompt"
    t.datetime "updated_at", null: false
    t.string "webhook_secret", null: false
    t.text "welcome_message"
    t.index ["key"], name: "index_tenants_on_key", unique: true
    t.index ["owner_id"], name: "index_tenants_on_owner_id"
  end

  create_table "tool_calls", force: :cascade do |t|
    t.jsonb "arguments", default: {}
    t.datetime "created_at", null: false
    t.bigint "message_id", null: false
    t.string "name", null: false
    t.string "tool_call_id", null: false
    t.datetime "updated_at", null: false
    t.index ["message_id"], name: "index_tool_calls_on_message_id"
    t.index ["name"], name: "index_tool_calls_on_name"
    t.index ["tool_call_id"], name: "index_tool_calls_on_tool_call_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "vehicles", force: :cascade do |t|
    t.string "brand"
    t.bigint "client_id", null: false
    t.datetime "created_at", null: false
    t.string "model"
    t.text "notes"
    t.string "plate_number"
    t.datetime "updated_at", null: false
    t.string "vin"
    t.integer "year"
    t.index ["client_id"], name: "index_vehicles_on_client_id"
  end

  add_foreign_key "analytics_events", "tenants"
  add_foreign_key "bookings", "clients"
  add_foreign_key "bookings", "tenants"
  add_foreign_key "bookings", "vehicles"
  add_foreign_key "chats", "clients"
  add_foreign_key "chats", "tenants"
  add_foreign_key "clients", "telegram_users"
  add_foreign_key "clients", "tenants"
  add_foreign_key "messages", "chats"
  add_foreign_key "tenants", "users", column: "owner_id"
  add_foreign_key "vehicles", "clients"
end
