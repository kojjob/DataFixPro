class AddPipelineConfigToPipelines < ActiveRecord::Migration[8.1]
  def change
    add_column :pipelines, :pipeline_config, :jsonb
  end
end
