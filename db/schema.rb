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

ActiveRecord::Schema[8.1].define(version: 2025_09_23_020540) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "hstore"
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"
  enable_extension "uuid-ossp"

  create_table "dashboards", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.string "name", null: false
    t.integer "tenant_id", null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "data_sources", id: :serial, force: :cascade do |t|
    t.jsonb "connection_errors", default: []
    t.jsonb "connection_options", default: {}
    t.string "connection_status", default: "disconnected"
    t.string "connection_type", default: "postgresql", null: false
    t.datetime "created_at", precision: nil, null: false
    t.string "database_name", default: "", null: false
    t.text "encrypted_password"
    t.string "encrypted_password_iv"
    t.string "host", default: "localhost", null: false
    t.datetime "last_connected_at"
    t.string "name", null: false
    t.text "password"
    t.integer "port"
    t.integer "tenant_id", null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "username"
    t.index ["connection_status"], name: "index_data_sources_on_connection_status"
    t.index ["connection_type"], name: "index_data_sources_on_connection_type"
  end

  create_table "pipeline_runs", force: :cascade do |t|
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.integer "duration"
    t.text "error_message"
    t.jsonb "metadata", default: {}, null: false
    t.bigint "pipeline_id", null: false
    t.datetime "started_at", null: false
    t.string "status", default: "running", null: false
    t.string "trigger_type", default: "manual", null: false
    t.datetime "updated_at", null: false
    t.index ["pipeline_id", "started_at"], name: "index_pipeline_runs_on_pipeline_id_and_started_at"
    t.index ["pipeline_id"], name: "index_pipeline_runs_on_pipeline_id"
    t.index ["started_at"], name: "index_pipeline_runs_on_started_at"
    t.index ["status", "started_at"], name: "index_pipeline_runs_on_status_and_started_at"
    t.index ["status"], name: "index_pipeline_runs_on_status"
  end

  create_table "pipeline_steps", force: :cascade do |t|
    t.jsonb "configuration", default: {}, null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.bigint "pipeline_id", null: false
    t.integer "position", null: false
    t.string "status", default: "enabled", null: false
    t.string "step_type", null: false
    t.datetime "updated_at", null: false
    t.index ["pipeline_id", "position"], name: "index_pipeline_steps_on_pipeline_id_and_position", unique: true
    t.index ["pipeline_id", "step_type"], name: "index_pipeline_steps_on_pipeline_id_and_step_type"
    t.index ["pipeline_id"], name: "index_pipeline_steps_on_pipeline_id"
    t.index ["position"], name: "index_pipeline_steps_on_position"
    t.index ["status"], name: "index_pipeline_steps_on_status"
    t.index ["step_type"], name: "index_pipeline_steps_on_step_type"
  end

  create_table "pipelines", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.text "description"
    t.datetime "last_run_at"
    t.string "name", null: false
    t.datetime "next_run_at"
    t.string "schedule_cron"
    t.integer "schedule_interval"
    t.string "schedule_type"
    t.string "status", default: "draft", null: false
    t.integer "tenant_id", null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "roles", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.string "name", null: false
    t.jsonb "permissions", default: {}
    t.integer "tenant_id", null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["tenant_id", "name"], name: "index_roles_on_tenant_id_and_name", unique: true
  end

  create_table "roles_users", primary_key: ["role_id", "user_id"], force: :cascade do |t|
    t.integer "role_id", null: false
    t.integer "user_id", null: false
  end

  create_table "step_executions", force: :cascade do |t|
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.integer "duration"
    t.text "error_message"
    t.integer "input_rows", default: 0
    t.jsonb "metadata", default: {}, null: false
    t.integer "output_rows", default: 0
    t.bigint "pipeline_run_id", null: false
    t.bigint "pipeline_step_id", null: false
    t.datetime "started_at", null: false
    t.string "status", default: "running", null: false
    t.string "step_type", null: false
    t.datetime "updated_at", null: false
    t.index ["pipeline_run_id", "pipeline_step_id"], name: "index_step_executions_on_pipeline_run_id_and_pipeline_step_id"
    t.index ["pipeline_run_id"], name: "index_step_executions_on_pipeline_run_id"
    t.index ["pipeline_step_id"], name: "index_step_executions_on_pipeline_step_id"
    t.index ["started_at"], name: "index_step_executions_on_started_at"
    t.index ["status", "started_at"], name: "index_step_executions_on_status_and_started_at"
    t.index ["status"], name: "index_step_executions_on_status"
    t.index ["step_type"], name: "index_step_executions_on_step_type"
  end

  create_table "tenants", id: :serial, force: :cascade do |t|
    t.string "api_key", null: false
    t.datetime "created_at", precision: nil, null: false
    t.string "custom_domain"
    t.string "name", null: false
    t.string "plan", default: "starter", null: false
    t.jsonb "plan_changes", default: [], null: false
    t.jsonb "settings", default: {}, null: false
    t.string "status", default: "active", null: false
    t.string "subdomain", null: false
    t.datetime "suspended_at", precision: nil
    t.datetime "updated_at", precision: nil, null: false
    t.index ["api_key"], name: "index_tenants_on_api_key", unique: true
    t.index ["subdomain"], name: "index_tenants_on_subdomain", unique: true
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.string "email", null: false
    t.string "name"
    t.string "password_digest"
    t.integer "tenant_id", null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["tenant_id", "email"], name: "index_users_on_tenant_id_and_email", unique: true
  end

  add_foreign_key "dashboards", "tenants", name: "dashboards_tenant_id_fkey", on_delete: :cascade
  add_foreign_key "data_sources", "tenants", name: "data_sources_tenant_id_fkey", on_delete: :cascade
  add_foreign_key "pipeline_runs", "pipelines", on_delete: :cascade
  add_foreign_key "pipeline_steps", "pipelines", on_delete: :cascade
  add_foreign_key "pipelines", "tenants", name: "pipelines_tenant_id_fkey", on_delete: :cascade
  add_foreign_key "roles", "tenants", name: "roles_tenant_id_fkey", on_delete: :cascade
  add_foreign_key "roles_users", "roles", name: "roles_users_role_id_fkey", on_delete: :cascade
  add_foreign_key "roles_users", "users", name: "roles_users_user_id_fkey", on_delete: :cascade
  add_foreign_key "step_executions", "pipeline_runs", on_delete: :cascade
  add_foreign_key "step_executions", "pipeline_steps", on_delete: :cascade
  add_foreign_key "users", "tenants", name: "users_tenant_id_fkey", on_delete: :cascade
end
