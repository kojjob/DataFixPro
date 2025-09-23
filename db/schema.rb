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

ActiveRecord::Schema[8.1].define(version: 2025_09_23_010539) do
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
    t.datetime "created_at", precision: nil, null: false
    t.string "name", null: false
    t.integer "tenant_id", null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "pipelines", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.string "name", null: false
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
  add_foreign_key "pipelines", "tenants", name: "pipelines_tenant_id_fkey", on_delete: :cascade
  add_foreign_key "roles", "tenants", name: "roles_tenant_id_fkey", on_delete: :cascade
  add_foreign_key "roles_users", "roles", name: "roles_users_role_id_fkey", on_delete: :cascade
  add_foreign_key "roles_users", "users", name: "roles_users_user_id_fkey", on_delete: :cascade
  add_foreign_key "users", "tenants", name: "users_tenant_id_fkey", on_delete: :cascade
end
