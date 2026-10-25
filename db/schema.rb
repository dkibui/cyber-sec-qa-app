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

ActiveRecord::Schema[8.1].define(version: 2026_10_25_001632) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "controls", force: :cascade do |t|
    t.bigint "domain_id", null: false
    t.integer "sequence", null: false
    t.text "description", null: false
    t.string "owasp"
    t.string "cwe_nist"
    t.integer "default_severity", default: 1, null: false
    t.datetime "retired_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["domain_id", "sequence"], name: "index_controls_on_domain_id_and_sequence", unique: true
    t.index ["domain_id"], name: "index_controls_on_domain_id"
  end

  create_table "domains", force: :cascade do |t|
    t.integer "number", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_domains_on_name", unique: true
    t.index ["number"], name: "index_domains_on_number", unique: true
  end

  create_table "projects", force: :cascade do |t|
    t.string "name", null: false
    t.integer "stage", default: 0, null: false
    t.bigint "architect_id"
    t.bigint "developer_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["architect_id"], name: "index_projects_on_architect_id"
    t.index ["developer_id"], name: "index_projects_on_developer_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "role", default: 4, null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "controls", "domains"
  add_foreign_key "projects", "users", column: "architect_id"
  add_foreign_key "projects", "users", column: "developer_id"
  add_foreign_key "sessions", "users"
end
