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

ActiveRecord::Schema[8.1].define(version: 2025_12_28_190730) do
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

  create_table "admin_users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.integer "managed_tenants_count", default: 0, null: false
    t.string "name"
    t.string "password_digest"
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admin_users_on_email", unique: true
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
    t.integer "number", null: false
    t.string "public_number", null: false
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "vehicle_id"
    t.index ["chat_id"], name: "index_bookings_on_chat_id"
    t.index ["client_id"], name: "index_bookings_on_client_id"
    t.index ["public_number"], name: "index_bookings_on_public_number", unique: true
    t.index ["tenant_id", "number"], name: "index_bookings_on_tenant_id_and_number", unique: true
    t.index ["tenant_id"], name: "index_bookings_on_tenant_id"
    t.index ["vehicle_id"], name: "index_bookings_on_vehicle_id"
  end

  create_table "chat_topics", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.string "label", null: false
    t.bigint "tenant_id"
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_chat_topics_on_active"
    t.index ["tenant_id", "key"], name: "index_chat_topics_on_tenant_id_and_key", unique: true
    t.index ["tenant_id"], name: "index_chat_topics_on_tenant_id"
  end

  create_table "chats", force: :cascade do |t|
    t.integer "bookings_count", default: 0, null: false
    t.bigint "chat_topic_id"
    t.bigint "client_id", null: false
    t.datetime "created_at", null: false
    t.datetime "first_booking_at"
    t.datetime "last_booking_at"
    t.datetime "last_message_at"
    t.bigint "model_id"
    t.bigint "tenant_id", null: false
    t.datetime "topic_classified_at"
    t.datetime "updated_at", null: false
    t.index ["bookings_count"], name: "index_chats_on_bookings_count"
    t.index ["chat_topic_id", "last_message_at"], name: "index_chats_on_chat_topic_id_and_last_message_at"
    t.index ["chat_topic_id"], name: "index_chats_on_chat_topic_id"
    t.index ["client_id"], name: "index_chats_on_client_id"
    t.index ["first_booking_at"], name: "index_chats_on_first_booking_at"
    t.index ["last_booking_at"], name: "index_chats_on_last_booking_at"
    t.index ["model_id"], name: "index_chats_on_model_id"
    t.index ["tenant_id", "last_message_at"], name: "index_chats_on_tenant_id_and_last_message_at"
    t.index ["tenant_id"], name: "index_chats_on_tenant_id"
    t.index ["topic_classified_at"], name: "index_chats_on_topic_classified_at"
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

  create_table "good_job_batches", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "callback_priority"
    t.text "callback_queue_name"
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "discarded_at"
    t.datetime "enqueued_at"
    t.datetime "finished_at"
    t.datetime "jobs_finished_at"
    t.text "on_discard"
    t.text "on_finish"
    t.text "on_success"
    t.jsonb "serialized_properties"
    t.datetime "updated_at", null: false
  end

  create_table "good_job_executions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "active_job_id", null: false
    t.datetime "created_at", null: false
    t.interval "duration"
    t.text "error"
    t.text "error_backtrace", array: true
    t.integer "error_event", limit: 2
    t.datetime "finished_at"
    t.text "job_class"
    t.uuid "process_id"
    t.text "queue_name"
    t.datetime "scheduled_at"
    t.jsonb "serialized_params"
    t.datetime "updated_at", null: false
    t.index ["active_job_id", "created_at"], name: "index_good_job_executions_on_active_job_id_and_created_at"
    t.index ["process_id", "created_at"], name: "index_good_job_executions_on_process_id_and_created_at"
  end

  create_table "good_job_processes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "lock_type", limit: 2
    t.jsonb "state"
    t.datetime "updated_at", null: false
  end

  create_table "good_job_settings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "key"
    t.datetime "updated_at", null: false
    t.jsonb "value"
    t.index ["key"], name: "index_good_job_settings_on_key", unique: true
  end

  create_table "good_jobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "active_job_id"
    t.uuid "batch_callback_id"
    t.uuid "batch_id"
    t.text "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "cron_at"
    t.text "cron_key"
    t.text "error"
    t.integer "error_event", limit: 2
    t.integer "executions_count"
    t.datetime "finished_at"
    t.boolean "is_discrete"
    t.text "job_class"
    t.text "labels", array: true
    t.datetime "locked_at"
    t.uuid "locked_by_id"
    t.datetime "performed_at"
    t.integer "priority"
    t.text "queue_name"
    t.uuid "retried_good_job_id"
    t.datetime "scheduled_at"
    t.jsonb "serialized_params"
    t.datetime "updated_at", null: false
    t.index ["active_job_id", "created_at"], name: "index_good_jobs_on_active_job_id_and_created_at"
    t.index ["batch_callback_id"], name: "index_good_jobs_on_batch_callback_id", where: "(batch_callback_id IS NOT NULL)"
    t.index ["batch_id"], name: "index_good_jobs_on_batch_id", where: "(batch_id IS NOT NULL)"
    t.index ["concurrency_key", "created_at"], name: "index_good_jobs_on_concurrency_key_and_created_at"
    t.index ["concurrency_key"], name: "index_good_jobs_on_concurrency_key_when_unfinished", where: "(finished_at IS NULL)"
    t.index ["cron_key", "created_at"], name: "index_good_jobs_on_cron_key_and_created_at_cond", where: "(cron_key IS NOT NULL)"
    t.index ["cron_key", "cron_at"], name: "index_good_jobs_on_cron_key_and_cron_at_cond", unique: true, where: "(cron_key IS NOT NULL)"
    t.index ["finished_at"], name: "index_good_jobs_jobs_on_finished_at_only", where: "(finished_at IS NOT NULL)"
    t.index ["job_class"], name: "index_good_jobs_on_job_class"
    t.index ["labels"], name: "index_good_jobs_on_labels", where: "(labels IS NOT NULL)", using: :gin
    t.index ["locked_by_id"], name: "index_good_jobs_on_locked_by_id", where: "(locked_by_id IS NOT NULL)"
    t.index ["priority", "created_at"], name: "index_good_job_jobs_for_candidate_lookup", where: "(finished_at IS NULL)"
    t.index ["priority", "created_at"], name: "index_good_jobs_jobs_on_priority_created_at_when_unfinished", order: { priority: "DESC NULLS LAST" }, where: "(finished_at IS NULL)"
    t.index ["priority", "scheduled_at"], name: "index_good_jobs_on_priority_scheduled_at_unfinished_unlocked", where: "((finished_at IS NULL) AND (locked_by_id IS NULL))"
    t.index ["queue_name", "scheduled_at"], name: "index_good_jobs_on_queue_name_and_scheduled_at", where: "(finished_at IS NULL)"
    t.index ["scheduled_at"], name: "index_good_jobs_on_scheduled_at", where: "(finished_at IS NULL)"
  end

  create_table "leads", force: :cascade do |t|
    t.string "city"
    t.string "company_name"
    t.datetime "created_at", null: false
    t.bigint "manager_id"
    t.string "name"
    t.string "phone"
    t.string "source"
    t.datetime "updated_at", null: false
    t.string "utm_campaign"
    t.string "utm_medium"
    t.string "utm_source"
    t.index ["manager_id"], name: "index_leads_on_manager_id"
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

  create_table "tenant_invites", force: :cascade do |t|
    t.datetime "accepted_at"
    t.bigint "accepted_by_id"
    t.datetime "cancelled_at"
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "invited_by_admin_id"
    t.bigint "invited_by_user_id"
    t.integer "role", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.bigint "tenant_id", null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.index ["accepted_by_id"], name: "index_tenant_invites_on_accepted_by_id"
    t.index ["invited_by_admin_id"], name: "index_tenant_invites_on_invited_by_admin_id"
    t.index ["invited_by_user_id"], name: "index_tenant_invites_on_invited_by_user_id"
    t.index ["tenant_id", "status"], name: "index_tenant_invites_on_tenant_id_and_status"
    t.index ["tenant_id"], name: "index_tenant_invites_on_tenant_id"
    t.index ["token"], name: "index_tenant_invites_on_token", unique: true
  end

  create_table "tenant_memberships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "role", default: 0, null: false
    t.bigint "tenant_id", null: false
    t.bigint "tenant_invite_id"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["tenant_id", "user_id"], name: "index_tenant_memberships_on_tenant_id_and_user_id", unique: true
    t.index ["tenant_id"], name: "index_tenant_memberships_on_tenant_id"
    t.index ["tenant_invite_id"], name: "index_tenant_memberships_on_tenant_invite_id"
    t.index ["user_id"], name: "index_tenant_memberships_on_user_id"
  end

  create_table "tenants", force: :cascade do |t|
    t.bigint "admin_chat_id"
    t.integer "bookings_count", default: 0, null: false
    t.string "bot_token", null: false
    t.string "bot_username", null: false
    t.integer "chats_count", default: 0, null: false
    t.integer "clients_count", default: 0, null: false
    t.text "company_info"
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.datetime "last_message_at"
    t.bigint "manager_id"
    t.string "name", null: false
    t.bigint "owner_id"
    t.text "price_list"
    t.text "system_prompt"
    t.datetime "updated_at", null: false
    t.string "webhook_secret", null: false
    t.text "welcome_message"
    t.index ["key"], name: "index_tenants_on_key", unique: true
    t.index ["manager_id"], name: "index_tenants_on_manager_id"
    t.index ["name"], name: "index_tenants_on_name", unique: true
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
    t.string "email", null: false
    t.string "name"
    t.string "password_digest"
    t.bigint "telegram_user_id"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["telegram_user_id"], name: "index_users_on_telegram_user_id", unique: true
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
  add_foreign_key "chat_topics", "tenants"
  add_foreign_key "chats", "chat_topics"
  add_foreign_key "chats", "clients"
  add_foreign_key "chats", "tenants"
  add_foreign_key "clients", "telegram_users"
  add_foreign_key "clients", "tenants"
  add_foreign_key "leads", "admin_users", column: "manager_id"
  add_foreign_key "messages", "chats"
  add_foreign_key "tenant_invites", "admin_users", column: "invited_by_admin_id"
  add_foreign_key "tenant_invites", "tenants"
  add_foreign_key "tenant_invites", "users", column: "accepted_by_id"
  add_foreign_key "tenant_invites", "users", column: "invited_by_user_id"
  add_foreign_key "tenant_memberships", "tenant_invites"
  add_foreign_key "tenant_memberships", "tenants"
  add_foreign_key "tenant_memberships", "users"
  add_foreign_key "tenants", "admin_users", column: "manager_id"
  add_foreign_key "tenants", "users", column: "owner_id"
  add_foreign_key "users", "telegram_users"
  add_foreign_key "vehicles", "clients"
end
