require 'rails_helper'

RSpec.describe TransformNodeProcessor do
  let(:processor) { described_class.new }

  describe '#process' do
    context 'with column transformation' do
      let(:input_data) do
        [
          ['id', 'name', 'price', 'date'],
          ['1', 'Product A', '10.50', '2024-01-15'],
          ['2', 'Product B', '25.99', '2024-01-16']
        ]
      end

      let(:node) do
        {
          'id' => 'transform-1',
          'type' => 'transform',
          'data' => {
            'transformType' => 'column',
            'operations' => [
              {
                'column' => 'price',
                'operation' => 'toNumber',
                'newColumn' => 'price_numeric'
              },
              {
                'column' => 'name',
                'operation' => 'lowercase',
                'inPlace' => true
              }
            ]
          }
        }
      end

      let(:context) { { 'input-1' => input_data } }

      it 'applies column transformations' do
        result = processor.process(node, context)

        expect(result[:success]).to be true
        expect(result[:data][0]).to include('price_numeric')
        expect(result[:data][1]).to include(10.50)
        expect(result[:data][1][1]).to eq('product a')  # Name lowercased
      end

      it 'handles multiple operations' do
        node['data']['operations'] = [
          { 'column' => 'name', 'operation' => 'uppercase', 'inPlace' => true },
          { 'column' => 'price', 'operation' => 'multiply', 'value' => 2, 'newColumn' => 'double_price' }
        ]

        result = processor.process(node, context)

        expect(result[:success]).to be true
        expect(result[:data][1][1]).to eq('PRODUCT A')
        expect(result[:data][0]).to include('double_price')
        expect(result[:data][1]).to include(21.0)
      end
    end

    context 'with row filtering' do
      let(:input_data) do
        [
          ['id', 'status', 'amount'],
          ['1', 'active', '100'],
          ['2', 'inactive', '50'],
          ['3', 'active', '75']
        ]
      end

      let(:node) do
        {
          'id' => 'transform-1',
          'type' => 'transform',
          'data' => {
            'transformType' => 'filter',
            'conditions' => [
              {
                'column' => 'status',
                'operator' => '=',
                'value' => 'active'
              }
            ]
          }
        }
      end

      let(:context) { { 'input-1' => input_data } }

      it 'filters rows based on condition' do
        result = processor.process(node, context)

        expect(result[:success]).to be true
        expect(result[:data].size).to eq(3)  # Headers + 2 active rows
        expect(result[:data][1][0]).to eq('1')
        expect(result[:data][2][0]).to eq('3')
      end

      it 'handles multiple conditions with AND logic' do
        node['data']['conditions'] = [
          { 'column' => 'status', 'operator' => '=', 'value' => 'active' },
          { 'column' => 'amount', 'operator' => '>', 'value' => '80' }
        ]
        node['data']['logicalOperator'] = 'AND'

        result = processor.process(node, context)

        expect(result[:success]).to be true
        expect(result[:data].size).to eq(2)  # Headers + 1 matching row
        expect(result[:data][1][0]).to eq('1')
      end

      it 'handles multiple conditions with OR logic' do
        node['data']['conditions'] = [
          { 'column' => 'status', 'operator' => '=', 'value' => 'inactive' },
          { 'column' => 'amount', 'operator' => '>', 'value' => '80' }
        ]
        node['data']['logicalOperator'] = 'OR'

        result = processor.process(node, context)

        expect(result[:success]).to be true
        expect(result[:data].size).to eq(3)  # Headers + 2 matching rows
      end
    end

    context 'with aggregation' do
      let(:input_data) do
        [
          ['category', 'product', 'sales'],
          ['Electronics', 'Phone', '1000'],
          ['Electronics', 'Laptop', '1500'],
          ['Clothing', 'Shirt', '50'],
          ['Clothing', 'Pants', '75']
        ]
      end

      let(:node) do
        {
          'id' => 'transform-1',
          'type' => 'transform',
          'data' => {
            'transformType' => 'aggregate',
            'groupBy' => ['category'],
            'aggregations' => [
              {
                'column' => 'sales',
                'operation' => 'sum',
                'alias' => 'total_sales'
              },
              {
                'column' => 'product',
                'operation' => 'count',
                'alias' => 'product_count'
              }
            ]
          }
        }
      end

      let(:context) { { 'input-1' => input_data } }

      it 'performs aggregation operations' do
        result = processor.process(node, context)

        expect(result[:success]).to be true
        expect(result[:data][0]).to eq(['category', 'total_sales', 'product_count'])
        expect(result[:data]).to include(['Electronics', 2500.0, 2])
        expect(result[:data]).to include(['Clothing', 125.0, 2])
      end

      it 'handles average calculation' do
        node['data']['aggregations'] = [
          { 'column' => 'sales', 'operation' => 'avg', 'alias' => 'avg_sales' }
        ]

        result = processor.process(node, context)

        expect(result[:success]).to be true
        expect(result[:data]).to include(['Electronics', 1250.0])
        expect(result[:data]).to include(['Clothing', 62.5])
      end
    end

    context 'with sorting' do
      let(:input_data) do
        [
          ['id', 'name', 'score'],
          ['3', 'Charlie', '85'],
          ['1', 'Alice', '95'],
          ['2', 'Bob', '75']
        ]
      end

      let(:node) do
        {
          'id' => 'transform-1',
          'type' => 'transform',
          'data' => {
            'transformType' => 'sort',
            'sortBy' => [
              { 'column' => 'score', 'direction' => 'desc' }
            ]
          }
        }
      end

      let(:context) { { 'input-1' => input_data } }

      it 'sorts data by specified column' do
        result = processor.process(node, context)

        expect(result[:success]).to be true
        expect(result[:data][1][1]).to eq('Alice')  # Highest score first
        expect(result[:data][2][1]).to eq('Charlie')
        expect(result[:data][3][1]).to eq('Bob')  # Lowest score last
      end

      it 'handles multiple sort columns' do
        input_data << ['4', 'David', '85']  # Same score as Charlie
        context = { 'input-1' => input_data }

        node['data']['sortBy'] = [
          { 'column' => 'score', 'direction' => 'desc' },
          { 'column' => 'name', 'direction' => 'asc' }
        ]

        result = processor.process(node, context)

        expect(result[:success]).to be true
        # Among score 85, Charlie should come before David
        expect(result[:data][2][1]).to eq('Charlie')
        expect(result[:data][3][1]).to eq('David')
      end
    end

    context 'with custom expression' do
      let(:input_data) do
        [
          ['id', 'quantity', 'price'],
          ['1', '5', '10.50'],
          ['2', '3', '25.00']
        ]
      end

      let(:node) do
        {
          'id' => 'transform-1',
          'type' => 'transform',
          'data' => {
            'transformType' => 'expression',
            'expressions' => [
              {
                'expression' => 'quantity * price',
                'newColumn' => 'total'
              },
              {
                'expression' => 'price * 1.1',
                'newColumn' => 'price_with_tax'
              }
            ]
          }
        }
      end

      let(:context) { { 'input-1' => input_data } }

      it 'evaluates custom expressions' do
        result = processor.process(node, context)

        expect(result[:success]).to be true
        expect(result[:data][0]).to include('total', 'price_with_tax')
        expect(result[:data][1]).to include(52.5)  # 5 * 10.50
        expect(result[:data][1]).to include(11.55)  # 10.50 * 1.1
        expect(result[:data][2]).to include(75.0)  # 3 * 25.00
      end
    end

    context 'with column operations' do
      let(:input_data) do
        [
          ['id', 'first_name', 'last_name', 'email'],
          ['1', 'John', 'Doe', 'john@example.com'],
          ['2', 'Jane', 'Smith', 'jane@example.com']
        ]
      end

      let(:node) do
        {
          'id' => 'transform-1',
          'type' => 'transform',
          'data' => {
            'transformType' => 'column',
            'operations' => []
          }
        }
      end

      let(:context) { { 'input-1' => input_data } }

      it 'concatenates columns' do
        node['data']['operations'] = [
          {
            'operation' => 'concatenate',
            'columns' => ['first_name', 'last_name'],
            'separator' => ' ',
            'newColumn' => 'full_name'
          }
        ]

        result = processor.process(node, context)

        expect(result[:success]).to be true
        expect(result[:data][0]).to include('full_name')
        expect(result[:data][1]).to include('John Doe')
        expect(result[:data][2]).to include('Jane Smith')
      end

      it 'drops columns' do
        node['data']['operations'] = [
          { 'operation' => 'drop', 'columns' => ['email'] }
        ]

        result = processor.process(node, context)

        expect(result[:success]).to be true
        expect(result[:data][0]).not_to include('email')
        expect(result[:data][0]).to eq(['id', 'first_name', 'last_name'])
      end

      it 'renames columns' do
        node['data']['operations'] = [
          { 'operation' => 'rename', 'column' => 'first_name', 'newName' => 'given_name' }
        ]

        result = processor.process(node, context)

        expect(result[:success]).to be true
        expect(result[:data][0]).to include('given_name')
        expect(result[:data][0]).not_to include('first_name')
      end
    end

    context 'error handling' do
      let(:node) do
        {
          'id' => 'transform-1',
          'type' => 'transform',
          'data' => {}
        }
      end

      it 'handles missing transform type' do
        result = processor.process(node, { 'input-1' => [['id'], ['1']] })

        expect(result[:success]).to be false
        expect(result[:error]).to include('Transform type not specified')
      end

      it 'handles invalid transform type' do
        node['data']['transformType'] = 'invalid'
        result = processor.process(node, { 'input-1' => [['id'], ['1']] })

        expect(result[:success]).to be false
        expect(result[:error]).to include('Unsupported transform type')
      end

      it 'handles missing input data' do
        node['data']['transformType'] = 'column'
        result = processor.process(node, {})

        expect(result[:success]).to be false
        expect(result[:error]).to include('Missing or empty input data')
      end

      it 'handles invalid column references' do
        node['data'] = {
          'transformType' => 'column',
          'operations' => [
            { 'column' => 'nonexistent', 'operation' => 'uppercase' }
          ]
        }

        result = processor.process(node, { 'input-1' => [['id'], ['1']] })

        expect(result[:success]).to be false
        expect(result[:error]).to include('Column not found')
      end
    end
  end
end