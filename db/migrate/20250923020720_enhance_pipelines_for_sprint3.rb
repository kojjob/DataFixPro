class EnhancePipelinesForSprint3 < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_column :pipelines, :description, :text
    add_column :pipelines, :status, :string, null: false, default: 'draft'
    add_column :pipelines, :schedule_type, :string
    add_column :pipelines, :schedule_cron, :string
    add_column :pipelines, :schedule_interval, :integer
    add_column :pipelines, :next_run_at, :datetime
    add_column :pipelines, :last_run_at, :datetime
    add_reference :pipelines, :data_source, null: false, index: { algorithm: :concurrently }

    add_index :pipelines, :status, algorithm: :concurrently
    add_index :pipelines, :schedule_type, algorithm: :concurrently
    add_index :pipelines, :next_run_at, algorithm: :concurrently
    add_index :pipelines, [:tenant_id, :name], unique: true, algorithm: :concurrently
    add_index :pipelines, [:status, :schedule_type], algorithm: :concurrently
  end
end
