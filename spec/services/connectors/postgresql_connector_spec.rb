require 'rails_helper'

RSpec.describe Connectors::PostgresqlConnector do
  let(:tenant) { create(:tenant) }
  let(:data_source) do
    create(:data_source,
      tenant: tenant,
      connection_type: 'postgresql',
      host: 'localhost',
      port: 5432,
      database_name: 'test_db',
      username: 'test_user',
      password: 'test_password'
    )
  end

  describe '#initialize' do
    it 'initializes with a data source' do
      connector = described_class.new(data_source)
      expect(connector.data_source).to eq(data_source)
    end
  end

  describe '#test_connection' do
    subject { described_class.new(data_source) }

    context 'with valid credentials' do
      before do
        allow(PG).to receive(:connect).and_return(double('connection', close: true))
      end

      it 'returns success status' do
        result = subject.test_connection
        expect(result[:success]).to be true
      end

      it 'includes success message' do
        result = subject.test_connection
        expect(result[:message]).to eq('Connection successful')
      end

      it 'updates connection status' do
        subject.test_connection
        expect(data_source.reload.connection_status).to eq('connected')
      end

      it 'updates last_connected_at' do
        freeze_time do
          subject.test_connection
          expect(data_source.reload.last_connected_at).to eq(Time.current)
        end
      end
    end

    context 'with invalid credentials' do
      before do
        allow(PG).to receive(:connect).and_raise(PG::ConnectionBad.new('password authentication failed'))
      end

      it 'returns failure status' do
        result = subject.test_connection
        expect(result[:success]).to be false
      end

      it 'includes error message' do
        result = subject.test_connection
        expect(result[:error]).to include('password authentication failed')
      end

      it 'updates connection status to failed' do
        subject.test_connection
        expect(data_source.reload.connection_status).to eq('failed')
      end

      it 'stores connection errors' do
        subject.test_connection
        errors = data_source.reload.connection_errors
        expect(errors.last['error']).to include('password authentication failed')
        expect(errors.last['timestamp']).not_to be_nil
      end
    end

    context 'with connection timeout' do
      before do
        allow(PG).to receive(:connect).and_raise(PG::ConnectionBad.new('timeout expired'))
      end

      it 'returns timeout error' do
        result = subject.test_connection
        expect(result[:success]).to be false
        expect(result[:error]).to include('timeout expired')
      end
    end
  end

  describe '#execute_query' do
    subject { described_class.new(data_source) }
    let(:connection) { double('pg_connection') }

    context 'with valid query' do
      let(:query) { 'SELECT * FROM users LIMIT 10' }
      let(:result_set) do
        [
          { 'id' => 1, 'name' => 'John Doe' },
          { 'id' => 2, 'name' => 'Jane Smith' }
        ]
      end

      before do
        allow(PG).to receive(:connect).and_return(connection)
        allow(connection).to receive(:exec).with(query).and_return(result_set)
        allow(connection).to receive(:close)
        allow(result_set).to receive(:to_a).and_return(result_set)
      end

      it 'returns query results' do
        result = subject.execute_query(query)
        expect(result[:success]).to be true
        expect(result[:data]).to eq(result_set)
      end

      it 'returns row count' do
        result = subject.execute_query(query)
        expect(result[:row_count]).to eq(2)
      end

      it 'closes connection after query' do
        expect(connection).to receive(:close)
        subject.execute_query(query)
      end
    end

    context 'with invalid query' do
      let(:query) { 'INVALID SQL QUERY' }

      before do
        allow(PG).to receive(:connect).and_return(connection)
        allow(connection).to receive(:exec).and_raise(PG::SyntaxError.new('syntax error'))
        allow(connection).to receive(:close)
      end

      it 'returns error' do
        result = subject.execute_query(query)
        expect(result[:success]).to be false
        expect(result[:error]).to include('syntax error')
      end

      it 'closes connection on error' do
        expect(connection).to receive(:close)
        subject.execute_query(query)
      end
    end
  end

  describe '#fetch_metadata' do
    subject { described_class.new(data_source) }
    let(:connection) { double('pg_connection') }

    before do
      allow(PG).to receive(:connect).and_return(connection)
      allow(connection).to receive(:close)
    end

    context 'fetching table list' do
      let(:tables_result) do
        [
          { 'tablename' => 'users', 'schemaname' => 'public' },
          { 'tablename' => 'posts', 'schemaname' => 'public' }
        ]
      end

      before do
        allow(connection).to receive(:exec).with(/SELECT tablename/).and_return(tables_result)
        allow(tables_result).to receive(:to_a).and_return(tables_result)
      end

      it 'returns list of tables' do
        result = subject.fetch_metadata(:tables)
        expect(result[:success]).to be true
        expect(result[:data]).to include('users', 'posts')
      end
    end

    context 'fetching column info' do
      let(:columns_result) do
        [
          { 'column_name' => 'id', 'data_type' => 'integer', 'is_nullable' => 'NO' },
          { 'column_name' => 'name', 'data_type' => 'character varying', 'is_nullable' => 'YES' }
        ]
      end

      before do
        allow(connection).to receive(:exec).with(/information_schema.columns/).and_return(columns_result)
        allow(columns_result).to receive(:to_a).and_return(columns_result)
      end

      it 'returns column information' do
        result = subject.fetch_metadata(:columns, table: 'users')
        expect(result[:success]).to be true
        expect(result[:data]).to eq(columns_result)
      end
    end
  end

  describe '#connection_options' do
    subject { described_class.new(data_source) }

    it 'builds connection hash from data source' do
      options = subject.send(:connection_options)
      expect(options[:host]).to eq('localhost')
      expect(options[:port]).to eq(5432)
      expect(options[:dbname]).to eq('test_db')
      expect(options[:user]).to eq('test_user')
      expect(options[:password]).to eq('test_password')
    end

    it 'includes custom connection options' do
      data_source.connection_options = { 'sslmode' => 'require' }
      options = subject.send(:connection_options)
      expect(options[:sslmode]).to eq('require')
    end

    it 'sets default timeout' do
      options = subject.send(:connection_options)
      expect(options[:connect_timeout]).to eq(10)
    end
  end
end