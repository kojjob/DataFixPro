require 'mysql2'

module Connectors
  class MysqlConnector
    attr_reader :data_source

    def initialize(data_source)
      @data_source = data_source
    end

    def test_connection
      client = nil
      begin
        client = Mysql2::Client.new(connection_options)

        # Update connection status
        data_source.update!(
          connection_status: 'connected',
          last_connected_at: Time.current
        )

        { success: true, message: 'Connection successful' }
      rescue Mysql2::Error => e
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
        client&.close
      end
    end

    def execute_query(query)
      client = nil
      begin
        client = Mysql2::Client.new(connection_options)
        results = client.query(query)

        {
          success: true,
          data: results.to_a,
          row_count: results.count
        }
      rescue Mysql2::Error => e
        {
          success: false,
          error: e.message
        }
      ensure
        client&.close
      end
    end

    def fetch_metadata(type, options = {})
      client = nil
      begin
        client = Mysql2::Client.new(connection_options)

        case type
        when :tables
          query = "SHOW TABLES"
          results = client.query(query)
          table_key = results.first.keys.first if results.first

          {
            success: true,
            data: results.map { |row| row[table_key] }
          }
        when :columns
          table = options[:table]
          raise ArgumentError, "Table name required" unless table

          query = "SHOW COLUMNS FROM #{table}"
          results = client.query(query)

          {
            success: true,
            data: results.to_a
          }
        else
          {
            success: false,
            error: "Unknown metadata type: #{type}"
          }
        end
      rescue Mysql2::Error => e
        {
          success: false,
          error: e.message
        }
      ensure
        client&.close
      end
    end

    private

    def connection_options
      options = {
        host: data_source.host,
        port: data_source.port || 3306,
        username: data_source.username,
        password: data_source.password,
        database: data_source.database_name,
        connect_timeout: 10,
        read_timeout: 10,
        write_timeout: 10
      }

      # Merge any additional connection options
      if data_source.connection_options.present?
        options.merge!(data_source.connection_options.symbolize_keys)
      end

      options
    end
  end
end