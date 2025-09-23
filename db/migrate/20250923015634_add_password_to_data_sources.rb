class AddPasswordToDataSources < ActiveRecord::Migration[8.1]
  def change
    add_column :data_sources, :password, :text
  end
end
