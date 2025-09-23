class EnhanceDataSourcesForConnections < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_column :data_sources, :connection_type, :string, null: false, default: 'postgresql'
    add_column :data_sources, :host, :string, null: false, default: 'localhost'
    add_column :data_sources, :port, :integer
    add_column :data_sources, :database_name, :string, null: false, default: ''
    add_column :data_sources, :username, :string
    add_column :data_sources, :encrypted_password, :text
    add_column :data_sources, :encrypted_password_iv, :string
    add_column :data_sources, :connection_options, :jsonb, default: {}
    add_column :data_sources, :last_connected_at, :datetime
    add_column :data_sources, :connection_status, :string, default: 'disconnected'
    add_column :data_sources, :connection_errors, :jsonb, default: []

    add_index :data_sources, :connection_type, algorithm: :concurrently
    add_index :data_sources, :connection_status, algorithm: :concurrently
  end
end