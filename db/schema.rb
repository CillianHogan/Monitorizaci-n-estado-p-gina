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

ActiveRecord::Schema[8.0].define(version: 2026_09_22_104852) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

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
    t.index ["user_id"], name: "index_api_endpoints_on_user_id"
  end

  create_table "domain_status_histories", force: :cascade do |t|
    t.bigint "domain_id", null: false
    t.integer "status"
    t.datetime "recorded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.index ["public_token"], name: "index_domains_on_public_token", unique: true
    t.index ["user_id"], name: "index_domains_on_user_id"
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

  add_foreign_key "api_endpoints", "users"
  add_foreign_key "domain_status_histories", "domains"
  add_foreign_key "domains", "users"
end
