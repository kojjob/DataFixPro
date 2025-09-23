require 'pg'

module Connectors
  class PostgresqlConnector
    attr_reader :data_source

    def initialize(data_source)
      @data_source = data_source
    end

    def test_connection
      connection = nil
      begin
        connection = PG.connect(connection_options)

        # Update connection status
        data_source.update!(
          connection_status: 'connected',
          last_connected_at: Time.current
        )

        { success: true, message: 'Connection successful' }
      rescue PG::ConnectionBad => e
        # Store connection error
        errors = data_source.connection_errors || []
        errors << {
          'error' => e.message,
          'timestamp' => Time.current.iso8601
        }

        data_source.update!(
          connection_status: 'failed',
          connection_errors: errors
        )

        { success: false, error: e.message }
      ensure
        connection&.close
      end
    end

    def execute_query(query)
      connection = nil
      begin
        connection = PG.connect(connection_options)
        result = connection.exec(query)

        {
          success: true,
          data: result.to_a,
          row_count: result.ntuples
        }
      rescue PG::Error => e
        {
          success: false,
          error: e.message
        }
      ensure
        connection&.close
      end
    end

    def fetch_metadata(type, options = {})
      connection = nil
      begin
        connection = PG.connect(connection_options)

        case type
        when :tables
          query = <<-SQL
            SELECT tablename
            FROM pg_tables
            WHERE schemaname = 'public'
            ORDER BY tablename
          SQL
          result = connection.exec(query)

          {
            success: true,
            data: result.map { |row| row['tablename'] }
          }
        when :columns
          table = options[:table]
          raise ArgumentError, "Table name required" unless table

          query = <<-SQL
            SELECT
              column_name,
              data_type,
              is_nullable
            FROM information_schema.columns
            WHERE table_name = '#{table}'
              AND table_schema = 'public'
            ORDER BY ordinal_position
          SQL
          result = connection.exec(query)

          {
            success: true,
            data: result.to_a
          }
        else
          {
            success: false,
            error: "Unknown metadata type: #{type}"
          }
        end
      rescue PG::Error => e
        {
          success: false,
          error: e.message
        }
      ensure
        connection&.close
      end
    end

    private

    def connection_options
      options = {
        host: data_source.host,
        port: data_source.port || 5432,
        dbname: data_source.database_name,
        user: data_source.username,
        password: data_source.password,
        connect_timeout: 10
      }

      # Merge any additional connection options
      if data_source.connection_options.present?
        options.merge!(data_source.connection_options.symbolize_keys)
      end

      options
    end
  end
end