class AddDataSourceToPipelines < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_reference :pipelines, :data_source, null: true, index: { algorithm: :concurrently }
    add_foreign_key :pipelines, :data_sources, on_delete: :cascade
  end
end
