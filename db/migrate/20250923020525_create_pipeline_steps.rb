class CreatePipelineSteps < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    create_table :pipeline_steps do |t|
      t.string :name, null: false
      t.text :description
      t.string :step_type, null: false
      t.integer :position, null: false
      t.string :status, null: false, default: 'enabled'
      t.jsonb :configuration, null: false, default: {}
      t.references :pipeline, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end

    add_index :pipeline_steps, :step_type, algorithm: :concurrently
    add_index :pipeline_steps, :position, algorithm: :concurrently
    add_index :pipeline_steps, :status, algorithm: :concurrently
    add_index :pipeline_steps, [:pipeline_id, :position], unique: true, algorithm: :concurrently
    add_index :pipeline_steps, [:pipeline_id, :step_type], algorithm: :concurrently
  end
end
