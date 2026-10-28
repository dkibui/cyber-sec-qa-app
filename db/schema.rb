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

ActiveRecord::Schema[8.1].define(version: 2026_10_28_172413) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "assessments", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.integer "gate", null: false
    t.integer "round", default: 1, null: false
    t.bigint "tester_id"
    t.text "components_in_scope"
    t.integer "outcome", default: 0, null: false
    t.datetime "decided_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id", "gate", "round"], name: "index_assessments_on_project_id_and_gate_and_round", unique: true
    t.index ["project_id"], name: "index_assessments_on_project_id"
    t.index ["tester_id"], name: "index_assessments_on_tester_id"
  end

  create_table "control_results", force: :cascade do |t|
    t.bigint "assessment_id", null: false
    t.bigint "control_id", null: false
    t.integer "status", default: 0, null: false
    t.integer "severity", default: 1, null: false
    t.text "comments"
    t.string "owner"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assessment_id", "control_id"], name: "index_control_results_on_assessment_id_and_control_id", unique: true
    t.index ["assessment_id"], name: "index_control_results_on_assessment_id"
    t.index ["control_id"], name: "index_control_results_on_control_id"
  end

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

  create_table "evidences", force: :cascade do |t|
    t.bigint "finding_id", null: false
    t.string "caption", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["finding_id"], name: "index_evidences_on_finding_id"
  end

  create_table "findings", force: :cascade do |t|
    t.bigint "assessment_id", null: false
    t.bigint "control_result_id", null: false
    t.string "category"
    t.text "test_objective"
    t.text "observations"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assessment_id"], name: "index_findings_on_assessment_id"
    t.index ["control_result_id"], name: "index_findings_on_control_result_id"
  end

  create_table "overrides", force: :cascade do |t|
    t.bigint "assessment_id", null: false
    t.bigint "approver_id", null: false
    t.text "comments", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["approver_id"], name: "index_overrides_on_approver_id"
    t.index ["assessment_id"], name: "index_overrides_on_assessment_id", unique: true
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

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "assessments", "projects"
  add_foreign_key "assessments", "users", column: "tester_id"
  add_foreign_key "control_results", "assessments"
  add_foreign_key "control_results", "controls"
  add_foreign_key "controls", "domains"
  add_foreign_key "evidences", "findings"
  add_foreign_key "findings", "assessments"
  add_foreign_key "findings", "control_results"
  add_foreign_key "overrides", "assessments"
  add_foreign_key "overrides", "users", column: "approver_id"
  add_foreign_key "projects", "users", column: "architect_id"
  add_foreign_key "projects", "users", column: "developer_id"
  add_foreign_key "sessions", "users"
end
