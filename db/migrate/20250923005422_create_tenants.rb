class CreateTenants < ActiveRecord::Migration[8.1]
  def change
    create_table :tenants do |t|
      t.string :name, null: false
      t.string :subdomain, null: false
      t.string :custom_domain
      t.string :plan, null: false, default: 'starter'
      t.string :status, null: false, default: 'active'
      t.string :api_key, null: false
      t.jsonb :settings, null: false, default: {}
      t.datetime :suspended_at
      t.jsonb :plan_changes, null: false, default: []

      t.timestamps
    end

    add_index :tenants, :subdomain, unique: true
    add_index :tenants, :custom_domain, unique: true, where: "custom_domain IS NOT NULL"
    add_index :tenants, :api_key, unique: true
    add_index :tenants, :status
    add_index :tenants, :plan
    add_index :tenants, :settings, using: :gin
  end
end