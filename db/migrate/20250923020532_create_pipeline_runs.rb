class CreatePipelineRuns < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    create_table :pipeline_runs do |t|
      t.string :status, null: false, default: 'running'
      t.datetime :started_at, null: false
      t.datetime :completed_at
      t.integer :duration
      t.string :trigger_type, null: false, default: 'manual'
      t.text :error_message
      t.jsonb :metadata, null: false, default: {}
      t.references :pipeline, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end

    add_index :pipeline_runs, :status, algorithm: :concurrently
    add_index :pipeline_runs, :started_at, algorithm: :concurrently
    add_index :pipeline_runs, [:pipeline_id, :started_at], algorithm: :concurrently
    add_index :pipeline_runs, [:status, :started_at], algorithm: :concurrently
  end
end
