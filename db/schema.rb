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

ActiveRecord::Schema[8.0].define(version: 2026_10_01_110234) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "api_endpoint_status_histories", force: :cascade do |t|
    t.bigint "api_endpoint_id", null: false
    t.integer "status", default: 0
    t.integer "response_time_ms"
    t.integer "http_code"
    t.datetime "recorded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["api_endpoint_id", "recorded_at"], name: "idx_on_api_endpoint_id_recorded_at_f741e75b85"
    t.index ["api_endpoint_id"], name: "index_api_endpoint_status_histories_on_api_endpoint_id"
  end

  create_table "api_endpoints", force: :cascade do |t|
    t.string "name"
    t.string "url"
    t.integer "status", default: 0
    t.integer "http_method", default: 0
    t.json "headers"
    t.json "expected_response"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "notify_email", default: true, null: false
    t.string "notify_email_address"
    t.boolean "notify_discord", default: false, null: false
    t.string "discord_webhook_url"
    t.boolean "notify_telegram", default: false, null: false
    t.string "telegram_chat_id"
    t.string "telegram_bot_token"
    t.integer "last_response_time_ms"
    t.integer "last_http_code"
    t.string "public_token"
    t.index ["public_token"], name: "index_api_endpoints_on_public_token", unique: true
    t.index ["user_id"], name: "index_api_endpoints_on_user_id"
  end

  create_table "domain_status_histories", force: :cascade do |t|
    t.bigint "domain_id", null: false
    t.integer "status"
    t.datetime "recorded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "response_time_ms"
    t.integer "http_code"
    t.index ["domain_id"], name: "index_domain_status_histories_on_domain_id"
  end

  create_table "domains", force: :cascade do |t|
    t.string "name"
    t.string "url"
    t.integer "status", default: 0
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "public_token"
    t.boolean "ssl_valid"
    t.string "ssl_issuer"
    t.datetime "ssl_expires_at"
    t.integer "ssl_days_remaining"
    t.date "ssl_alert_sent_at"
    t.integer "max_latency_threshold_ms"
    t.datetime "latency_alert_sent_at"
    t.string "expected_keyword"
    t.boolean "latency_alert_enabled", default: false, null: false
    t.datetime "down_alert_sent_at"
    t.string "discord_webhook_url"
    t.boolean "notify_discord", default: false, null: false
    t.string "telegram_bot_token"
    t.string "telegram_chat_id"
    t.boolean "notify_telegram", default: false, null: false
    t.boolean "notify_email", default: true, null: false
    t.integer "last_response_time_ms"
    t.string "notify_email_address"
    t.index ["public_token"], name: "index_domains_on_public_token", unique: true
    t.index ["user_id"], name: "index_domains_on_user_id"
  end

  create_table "notification_channels", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "channel_type", null: false
    t.string "destination", null: false
    t.string "name"
    t.boolean "is_default", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "channel_type"], name: "index_notification_channels_on_user_id_and_channel_type"
    t.index ["user_id"], name: "index_notification_channels_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.string "role", default: "user", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "api_endpoint_status_histories", "api_endpoints"
  add_foreign_key "api_endpoints", "users"
  add_foreign_key "domain_status_histories", "domains"
  add_foreign_key "domains", "users"
  add_foreign_key "notification_channels", "users"
end
