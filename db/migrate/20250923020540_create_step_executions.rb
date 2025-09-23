class CreateStepExecutions < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    create_table :step_executions do |t|
      t.string :status, null: false, default: 'running'
      t.string :step_type, null: false
      t.datetime :started_at, null: false
      t.datetime :completed_at
      t.integer :duration
      t.integer :input_rows, default: 0
      t.integer :output_rows, default: 0
      t.text :error_message
      t.jsonb :metadata, null: false, default: {}
      t.references :pipeline_run, null: false, foreign_key: { on_delete: :cascade }
      t.references :pipeline_step, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end

    add_index :step_executions, :status, algorithm: :concurrently
    add_index :step_executions, :step_type, algorithm: :concurrently
    add_index :step_executions, :started_at, algorithm: :concurrently
    add_index :step_executions, [:pipeline_run_id, :pipeline_step_id], algorithm: :concurrently
    add_index :step_executions, [:status, :started_at], algorithm: :concurrently
  end
end
