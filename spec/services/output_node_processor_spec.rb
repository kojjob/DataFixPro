require 'rails_helper'

RSpec.describe OutputNodeProcessor do
  let(:processor) { described_class.new }

  describe '#process' do
    let(:input_data) do
      [
        ['id', 'name', 'email'],
        ['1', 'Alice', 'alice@example.com'],
        ['2', 'Bob', 'bob@example.com']
      ]
    end

    context 'with CSV output' do
      let(:node) do
        {
          'id' => 'output-1',
          'type' => 'output',
          'data' => {
            'outputType' => 'csv',
            'filename' => 'output.csv'
          }
        }
      end

      let(:context) { { 'input-1' => input_data } }

      it 'generates CSV format' do
        result = processor.process(node, context)

        expect(result[:success]).to be true
        expect(result[:format]).to eq('csv')
        expect(result[:content]).to include('id,name,email')
        expect(result[:content]).to include('1,Alice,alice@example.com')
        expect(result[:content]).to include('2,Bob,bob@example.com')
      end

      it 'handles custom delimiter' do
        node['data']['delimiter'] = ';'
        result = processor.process(node, context)

        expect(result[:success]).to be true
        expect(result[:content]).to include('id;name;email')
        expect(result[:content]).to include('1;Alice;alice@example.com')
      end

      it 'includes headers by default' do
        result = processor.process(node, context)

        expect(result[:success]).to be true
        lines = result[:content].split("\n")
        expect(lines.first).to eq('id,name,email')
      end

      it 'excludes headers when specified' do
        node['data']['includeHeaders'] = false
        result = processor.process(node, context)

        expect(result[:success]).to be true
        lines = result[:content].split("\n")
        expect(lines.first).to eq('1,Alice,alice@example.com')
      end
    end

    context 'with JSON output' do
      let(:node) do
        {
          'id' => 'output-1',
          'type' => 'output',
          'data' => {
            'outputType' => 'json',
            'filename' => 'output.json'
          }
        }
      end

      let(:context) { { 'input-1' => input_data } }

      it 'generates JSON format' do
        result = processor.process(node, context)

        expect(result[:success]).to be true
        expect(result[:format]).to eq('json')

        parsed = JSON.parse(result[:content])
        expect(parsed).to be_an(Array)
        expect(parsed.size).to eq(2)
        expect(parsed[0]).to eq({ 'id' => '1', 'name' => 'Alice', 'email' => 'alice@example.com' })
        expect(parsed[1]).to eq({ 'id' => '2', 'name' => 'Bob', 'email' => 'bob@example.com' })
      end

      it 'formats JSON with pretty print when specified' do
        node['data']['prettyPrint'] = true
        result = processor.process(node, context)

        expect(result[:success]).to be true
        expect(result[:content]).to include("  ")  # Indentation
        expect(result[:content].lines.count).to be > 3  # Multiple lines
      end
    end

    context 'with database output' do
      let(:node) do
        {
          'id' => 'output-1',
          'type' => 'output',
          'data' => {
            'outputType' => 'database',
            'tableName' => 'users',
            'connectionId' => 'test-connection',
            'insertMode' => 'append'
          }
        }
      end

      let(:context) { { 'input-1' => input_data } }

      it 'prepares database insert' do
        allow(processor).to receive(:insert_to_database).and_return(2)

        result = processor.process(node, context)

        expect(result[:success]).to be true
        expect(result[:format]).to eq('database')
        expect(result[:rowsInserted]).to eq(2)
      end

      it 'handles replace mode' do
        node['data']['insertMode'] = 'replace'
        allow(processor).to receive(:truncate_table).and_return(true)
        allow(processor).to receive(:insert_to_database).and_return(2)

        result = processor.process(node, context)

        expect(result[:success]).to be true
        expect(result[:rowsInserted]).to eq(2)
      end

      it 'handles database errors' do
        allow(processor).to receive(:insert_to_database).and_raise(StandardError.new('Database error'))

        result = processor.process(node, context)

        expect(result[:success]).to be false
        expect(result[:error]).to include('Database error')
      end
    end

    context 'with API output' do
      let(:node) do
        {
          'id' => 'output-1',
          'type' => 'output',
          'data' => {
            'outputType' => 'api',
            'endpoint' => 'https://api.example.com/data',
            'method' => 'POST',
            'headers' => { 'Authorization' => 'Bearer token123' }
          }
        }
      end

      let(:context) { { 'input-1' => input_data } }

      it 'sends data to API' do
        allow(processor).to receive(:send_to_api).and_return({ status: 200, body: 'Success' })

        result = processor.process(node, context)

        expect(result[:success]).to be true
        expect(result[:format]).to eq('api')
        expect(result[:response]).to eq({ status: 200, body: 'Success' })
      end

      it 'handles API errors' do
        allow(processor).to receive(:send_to_api).and_raise(StandardError.new('API error'))

        result = processor.process(node, context)

        expect(result[:success]).to be false
        expect(result[:error]).to include('API error')
      end

      it 'supports batch sending' do
        node['data']['batchSize'] = 1
        allow(processor).to receive(:send_batch_to_api).and_return([
          { status: 200, body: 'Batch 1 success' },
          { status: 200, body: 'Batch 2 success' }
        ])

        result = processor.process(node, context)

        expect(result[:success]).to be true
        expect(result[:responses]).to be_an(Array)
        expect(result[:responses].size).to eq(2)
      end
    end

    context 'with file output' do
      let(:node) do
        {
          'id' => 'output-1',
          'type' => 'output',
          'data' => {
            'outputType' => 'file',
            'filename' => 'output.txt',
            'format' => 'csv'
          }
        }
      end

      let(:context) { { 'input-1' => input_data } }

      it 'generates file content' do
        result = processor.process(node, context)

        expect(result[:success]).to be true
        expect(result[:format]).to eq('file')
        expect(result[:filename]).to eq('output.txt')
        expect(result[:content]).to include('id,name,email')
      end

      it 'supports compression' do
        node['data']['compress'] = true
        result = processor.process(node, context)

        expect(result[:success]).to be true
        expect(result[:compressed]).to be true
        expect(result[:filename]).to eq('output.txt.gz')
      end
    end

    context 'with statistics' do
      let(:node) do
        {
          'id' => 'output-1',
          'type' => 'output',
          'data' => {
            'outputType' => 'csv',
            'includeStats' => true
          }
        }
      end

      let(:context) { { 'input-1' => input_data } }

      it 'includes processing statistics' do
        result = processor.process(node, context)

        expect(result[:success]).to be true
        expect(result[:statistics]).to be_present
        expect(result[:statistics][:rows_processed]).to eq(2)
        expect(result[:statistics][:columns]).to eq(3)
      end
    end

    context 'error handling' do
      let(:node) do
        {
          'id' => 'output-1',
          'type' => 'output',
          'data' => {}
        }
      end

      it 'handles missing output type' do
        result = processor.process(node, { 'input-1' => input_data })

        expect(result[:success]).to be false
        expect(result[:error]).to include('Output type not specified')
      end

      it 'handles invalid output type' do
        node['data']['outputType'] = 'invalid'
        result = processor.process(node, { 'input-1' => input_data })

        expect(result[:success]).to be false
        expect(result[:error]).to include('Unsupported output type')
      end

      it 'handles missing input data' do
        result = processor.process(node, {})

        expect(result[:success]).to be false
        expect(result[:error]).to include('Missing input data')
      end

      it 'handles empty input data' do
        result = processor.process(node, { 'input-1' => [] })

        expect(result[:success]).to be false
        expect(result[:error]).to include('Empty input data')
      end
    end
  end
end