require 'rails_helper'

RSpec.describe InputNodeProcessor do
  let(:processor) { described_class.new }

  describe '#process' do
    context 'with CSV input' do
      let(:node) do
        {
          'id' => 'input-1',
          'type' => 'input',
          'data' => {
            'sourceType' => 'csv',
            'csvContent' => "id,name,email\n1,Alice,alice@example.com\n2,Bob,bob@example.com"
          }
        }
      end

      let(:context) { {} }

      it 'parses CSV data correctly' do
        result = processor.process(node, context)

        expect(result[:success]).to be true
        expect(result[:data]).to be_an(Array)
        expect(result[:data].size).to eq(3) # Headers + 2 rows
        expect(result[:data][0]).to eq(['id', 'name', 'email'])
        expect(result[:data][1]).to eq(['1', 'Alice', 'alice@example.com'])
        expect(result[:data][2]).to eq(['2', 'Bob', 'bob@example.com'])
      end

      it 'handles empty CSV data' do
        node['data']['csvContent'] = ''
        result = processor.process(node, context)

        expect(result[:success]).to be false
        expect(result[:error]).to include('Empty CSV data')
      end

      it 'handles CSV with only headers' do
        node['data']['csvContent'] = "id,name,email"
        result = processor.process(node, context)

        expect(result[:success]).to be true
        expect(result[:data].size).to eq(1)
        expect(result[:data][0]).to eq(['id', 'name', 'email'])
      end

      it 'handles CSV with different delimiters' do
        node['data']['delimiter'] = ';'
        node['data']['csvContent'] = "id;name;email\n1;Alice;alice@example.com"

        result = processor.process(node, context)

        expect(result[:success]).to be true
        expect(result[:data][0]).to eq(['id', 'name', 'email'])
        expect(result[:data][1]).to eq(['1', 'Alice', 'alice@example.com'])
      end

      it 'handles CSV with quotes' do
        node['data']['csvContent'] = "name,description\n\"Alice\",\"Says \"\"Hello\"\" to Bob\""

        result = processor.process(node, context)

        expect(result[:success]).to be true
        expect(result[:data][1]).to eq(['Alice', 'Says "Hello" to Bob'])
      end
    end

    context 'with JSON input' do
      let(:node) do
        {
          'id' => 'input-1',
          'type' => 'input',
          'data' => {
            'sourceType' => 'json',
            'jsonContent' => '[{"id": 1, "name": "Alice"}, {"id": 2, "name": "Bob"}]'
          }
        }
      end

      let(:context) { {} }

      it 'converts JSON to table format' do
        result = processor.process(node, context)

        expect(result[:success]).to be true
        expect(result[:data][0]).to eq(['id', 'name'])
        expect(result[:data][1]).to eq([1, 'Alice'])
        expect(result[:data][2]).to eq([2, 'Bob'])
      end

      it 'handles invalid JSON' do
        node['data']['jsonContent'] = 'invalid json'
        result = processor.process(node, context)

        expect(result[:success]).to be false
        expect(result[:error]).to include('Invalid JSON')
      end

      it 'handles empty JSON array' do
        node['data']['jsonContent'] = '[]'
        result = processor.process(node, context)

        expect(result[:success]).to be false
        expect(result[:error]).to include('Empty JSON data')
      end

      it 'handles nested JSON objects' do
        node['data']['jsonContent'] = '[{"id": 1, "user": {"name": "Alice", "age": 30}}]'
        result = processor.process(node, context)

        expect(result[:success]).to be true
        expect(result[:data][0]).to include('user.name', 'user.age')
        expect(result[:data][1]).to include('Alice', 30)
      end
    end

    context 'with database input' do
      let(:node) do
        {
          'id' => 'input-1',
          'type' => 'input',
          'data' => {
            'sourceType' => 'database',
            'query' => 'SELECT * FROM users',
            'connectionId' => 'test-connection'
          }
        }
      end

      let(:context) { {} }

      it 'executes database query' do
        # Mock database connection
        allow(processor).to receive(:execute_query).and_return([
          { 'id' => 1, 'name' => 'Alice' },
          { 'id' => 2, 'name' => 'Bob' }
        ])

        result = processor.process(node, context)

        expect(result[:success]).to be true
        expect(result[:data][0]).to eq(['id', 'name'])
        expect(result[:data][1]).to eq([1, 'Alice'])
      end

      it 'handles database connection errors' do
        allow(processor).to receive(:execute_query).and_raise(StandardError.new('Connection failed'))

        result = processor.process(node, context)

        expect(result[:success]).to be false
        expect(result[:error]).to include('Connection failed')
      end

      it 'handles empty query results' do
        allow(processor).to receive(:execute_query).and_return([])

        result = processor.process(node, context)

        expect(result[:success]).to be false
        expect(result[:error]).to include('No data returned from query')
      end
    end

    context 'with API input' do
      let(:node) do
        {
          'id' => 'input-1',
          'type' => 'input',
          'data' => {
            'sourceType' => 'api',
            'endpoint' => 'https://api.example.com/users',
            'method' => 'GET',
            'headers' => { 'Authorization' => 'Bearer token123' }
          }
        }
      end

      let(:context) { {} }

      it 'fetches data from API' do
        # Mock API response
        allow(processor).to receive(:fetch_from_api).and_return([
          { 'id' => 1, 'name' => 'Alice' },
          { 'id' => 2, 'name' => 'Bob' }
        ])

        result = processor.process(node, context)

        expect(result[:success]).to be true
        expect(result[:data][0]).to eq(['id', 'name'])
        expect(result[:data][1]).to eq([1, 'Alice'])
      end

      it 'handles API errors' do
        allow(processor).to receive(:fetch_from_api).and_raise(StandardError.new('API error'))

        result = processor.process(node, context)

        expect(result[:success]).to be false
        expect(result[:error]).to include('API error')
      end

      it 'handles pagination' do
        node['data']['pagination'] = true
        node['data']['pageSize'] = 10

        allow(processor).to receive(:fetch_all_pages).and_return([
          { 'id' => 1, 'name' => 'Alice' },
          { 'id' => 2, 'name' => 'Bob' },
          { 'id' => 3, 'name' => 'Charlie' }
        ])

        result = processor.process(node, context)

        expect(result[:success]).to be true
        expect(result[:data].size).to eq(4) # Headers + 3 rows
      end
    end

    context 'error handling' do
      let(:node) do
        {
          'id' => 'input-1',
          'type' => 'input',
          'data' => {}
        }
      end

      it 'handles missing source type' do
        result = processor.process(node, {})

        expect(result[:success]).to be false
        expect(result[:error]).to include('Source type not specified')
      end

      it 'handles invalid source type' do
        node['data']['sourceType'] = 'invalid'
        result = processor.process(node, {})

        expect(result[:success]).to be false
        expect(result[:error]).to include('Unsupported source type')
      end

      it 'handles missing node data' do
        node.delete('data')
        result = processor.process(node, {})

        expect(result[:success]).to be false
        expect(result[:error]).to include('Node data missing')
      end
    end
  end
end