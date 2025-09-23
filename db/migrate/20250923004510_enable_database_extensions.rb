class EnableDatabaseExtensions < ActiveRecord::Migration[8.1]
  def change
    # Enable UUID support
    enable_extension 'pgcrypto' unless extension_enabled?('pgcrypto')
    enable_extension 'uuid-ossp' unless extension_enabled?('uuid-ossp')

    # Enable full-text search
    enable_extension 'pg_trgm' unless extension_enabled?('pg_trgm')
    enable_extension 'unaccent' unless extension_enabled?('unaccent')

    # Enable JSON indexing
    enable_extension 'btree_gin' unless extension_enabled?('btree_gin')
    enable_extension 'btree_gist' unless extension_enabled?('btree_gist')

    # Enable TimescaleDB for time-series data (optional, might not be installed)
    # enable_extension 'timescaledb' unless extension_enabled?('timescaledb')
  end
end
