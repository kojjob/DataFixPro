require 'rails_helper'

RSpec.describe JoinNodeProcessor do
  let(:processor) { described_class.new }

  describe '#process' do
    let(:node) do
      {
        'id' => 'join-1',
        'type' => 'join',
        'data' => {
          'joinType' => 'inner',
          'leftTable' => 'users',
          'rightTable' => 'orders',
          'joinConditions' => [
            {
              'leftField' => 'id',
              'operator' => '=',
              'rightField' => 'user_id'
            }
          ],
          'selectedFields' => {
            'left' => ['id', 'name', 'email'],
            'right' => ['order_id', 'amount', 'status']
          }
        }
      }
    end

    context 'with inner join' do
      let(:left_data) do
        [
          ['id', 'name', 'email', 'created_at'],
          ['1', 'Alice', 'alice@example.com', '2024-01-01'],
          ['2', 'Bob', 'bob@example.com', '2024-01-02'],
          ['3', 'Charlie', 'charlie@example.com', '2024-01-03']
        ]
      end

      let(:right_data) do
        [
          ['order_id', 'user_id', 'amount', 'status'],
          ['101', '1', '50.00', 'completed'],
          ['102', '2', '75.00', 'pending'],
          ['103', '1', '30.00', 'completed'],
          ['104', '4', '100.00', 'completed'] # user_id 4 doesn't exist
        ]
      end

      let(:context) do
        {
          'input-1' => left_data,
          'input-2' => right_data
        }
      end

      it 'performs inner join correctly' do
        result = processor.process(node, context)

        expect(result[:success]).to be true
        expect(result[:data]).to be_an(Array)

        # Check headers
        expect(result[:data][0]).to eq(['id', 'name', 'email', 'order_id', 'amount', 'status'])

        # Check data rows - should have 3 rows (2 for Alice, 1 for Bob)
        expect(result[:data].size).to eq(4) # 1 header + 3 data rows

        # Verify joined data
        data_rows = result[:data][1..]
        alice_rows = data_rows.select { |row| row[1] == 'Alice' }
        bob_rows = data_rows.select { |row| row[1] == 'Bob' }

        expect(alice_rows.size).to eq(2)
        expect(bob_rows.size).to eq(1)

        # Charlie should not appear (no orders)
        charlie_rows = data_rows.select { |row| row[1] == 'Charlie' }
        expect(charlie_rows.size).to eq(0)
      end

      it 'respects field selection' do
        result = processor.process(node, context)

        # Should only include selected fields
        expect(result[:data][0]).not_to include('created_at')
        expect(result[:data][0]).to include('id', 'name', 'email')
        expect(result[:data][0]).to include('order_id', 'amount', 'status')
        expect(result[:data][0]).not_to include('user_id') # Not in selected fields
      end
    end

    context 'with left join' do
      let(:node) do
        {
          'id' => 'join-1',
          'type' => 'join',
          'data' => {
            'joinType' => 'left',
            'leftTable' => 'users',
            'rightTable' => 'orders',
            'joinConditions' => [
              {
                'leftField' => 'id',
                'operator' => '=',
                'rightField' => 'user_id'
              }
            ],
            'selectedFields' => {
              'left' => ['id', 'name'],
              'right' => ['order_id', 'amount']
            }
          }
        }
      end

      let(:left_data) do
        [
          ['id', 'name'],
          ['1', 'Alice'],
          ['2', 'Bob'],
          ['3', 'Charlie']
        ]
      end

      let(:right_data) do
        [
          ['order_id', 'user_id', 'amount'],
          ['101', '1', '50.00'],
          ['102', '2', '75.00']
        ]
      end

      let(:context) do
        {
          'input-1' => left_data,
          'input-2' => right_data
        }
      end

      it 'includes all left table records' do
        result = processor.process(node, context)

        expect(result[:success]).to be true

        # Should have all 3 users
        data_rows = result[:data][1..]
        user_names = data_rows.map { |row| row[1] }.uniq
        expect(user_names).to contain_exactly('Alice', 'Bob', 'Charlie')

        # Charlie should have null values for order fields
        charlie_row = data_rows.find { |row| row[1] == 'Charlie' }
        expect(charlie_row[2]).to be_nil # order_id
        expect(charlie_row[3]).to be_nil # amount
      end
    end

    context 'with right join' do
      let(:node) do
        {
          'id' => 'join-1',
          'type' => 'join',
          'data' => {
            'joinType' => 'right',
            'leftTable' => 'users',
            'rightTable' => 'orders',
            'joinConditions' => [
              {
                'leftField' => 'id',
                'operator' => '=',
                'rightField' => 'user_id'
              }
            ],
            'selectedFields' => {
              'left' => ['id', 'name'],
              'right' => ['order_id', 'user_id', 'amount']
            }
          }
        }
      end

      let(:left_data) do
        [
          ['id', 'name'],
          ['1', 'Alice'],
          ['2', 'Bob']
        ]
      end

      let(:right_data) do
        [
          ['order_id', 'user_id', 'amount'],
          ['101', '1', '50.00'],
          ['102', '2', '75.00'],
          ['103', '3', '100.00'] # user_id 3 doesn't exist in left
        ]
      end

      let(:context) do
        {
          'input-1' => left_data,
          'input-2' => right_data
        }
      end

      it 'includes all right table records' do
        result = processor.process(node, context)

        expect(result[:success]).to be true

        # Should have all 3 orders
        data_rows = result[:data][1..]
        expect(data_rows.size).to eq(3)

        # Order 103 should have null values for user fields
        order_103_row = data_rows.find { |row| row[2] == '103' }
        expect(order_103_row[0]).to be_nil # id
        expect(order_103_row[1]).to be_nil # name
      end
    end

    context 'with full outer join' do
      let(:node) do
        {
          'id' => 'join-1',
          'type' => 'join',
          'data' => {
            'joinType' => 'full',
            'leftTable' => 'users',
            'rightTable' => 'orders',
            'joinConditions' => [
              {
                'leftField' => 'id',
                'operator' => '=',
                'rightField' => 'user_id'
              }
            ],
            'selectedFields' => {
              'left' => ['id', 'name'],
              'right' => ['order_id', 'user_id']
            }
          }
        }
      end

      let(:left_data) do
        [
          ['id', 'name'],
          ['1', 'Alice'],
          ['2', 'Bob'],
          ['3', 'Charlie'] # No orders
        ]
      end

      let(:right_data) do
        [
          ['order_id', 'user_id'],
          ['101', '1'],
          ['102', '2'],
          ['103', '4'] # User doesn't exist
        ]
      end

      let(:context) do
        {
          'input-1' => left_data,
          'input-2' => right_data
        }
      end

      it 'includes all records from both tables' do
        result = processor.process(node, context)

        expect(result[:success]).to be true

        # Should have 4 rows: Alice+101, Bob+102, Charlie+null, null+103
        data_rows = result[:data][1..]
        expect(data_rows.size).to eq(4)

        # Charlie should have null order
        charlie_row = data_rows.find { |row| row[1] == 'Charlie' }
        expect(charlie_row[2]).to be_nil

        # Order 103 should have null user
        order_103_row = data_rows.find { |row| row[2] == '103' }
        expect(order_103_row[0]).to be_nil
        expect(order_103_row[1]).to be_nil
      end
    end

    context 'with multiple join conditions' do
      let(:node) do
        {
          'id' => 'join-1',
          'type' => 'join',
          'data' => {
            'joinType' => 'inner',
            'leftTable' => 'products',
            'rightTable' => 'inventory',
            'joinConditions' => [
              {
                'leftField' => 'product_id',
                'operator' => '=',
                'rightField' => 'product_id'
              },
              {
                'leftField' => 'warehouse',
                'operator' => '=',
                'rightField' => 'location'
              }
            ],
            'selectedFields' => {
              'left' => ['product_id', 'name', 'warehouse'],
              'right' => ['quantity', 'last_updated']
            }
          }
        }
      end

      let(:left_data) do
        [
          ['product_id', 'name', 'warehouse'],
          ['P001', 'Widget', 'NYC'],
          ['P001', 'Widget', 'LA'],
          ['P002', 'Gadget', 'NYC']
        ]
      end

      let(:right_data) do
        [
          ['product_id', 'location', 'quantity', 'last_updated'],
          ['P001', 'NYC', '100', '2024-01-15'],
          ['P001', 'LA', '50', '2024-01-14'],
          ['P002', 'LA', '75', '2024-01-13'] # Wrong location for P002
        ]
      end

      let(:context) do
        {
          'input-1' => left_data,
          'input-2' => right_data
        }
      end

      it 'applies all join conditions' do
        result = processor.process(node, context)

        expect(result[:success]).to be true

        # Should only match when both product_id AND location match
        data_rows = result[:data][1..]
        expect(data_rows.size).to eq(2) # Only P001-NYC and P001-LA match

        # P002-NYC should not match with P002-LA
        p002_rows = data_rows.select { |row| row[0] == 'P002' }
        expect(p002_rows).to be_empty
      end
    end

    context 'with different operators' do
      let(:node) do
        {
          'id' => 'join-1',
          'type' => 'join',
          'data' => {
            'joinType' => 'inner',
            'leftTable' => 'employees',
            'rightTable' => 'salaries',
            'joinConditions' => [
              {
                'leftField' => 'level',
                'operator' => '>=',
                'rightField' => 'min_level'
              },
              {
                'leftField' => 'level',
                'operator' => '<=',
                'rightField' => 'max_level'
              }
            ],
            'selectedFields' => {
              'left' => ['name', 'level'],
              'right' => ['salary_grade', 'base_salary']
            }
          }
        }
      end

      let(:left_data) do
        [
          ['name', 'level'],
          ['Alice', '3'],
          ['Bob', '5'],
          ['Charlie', '8']
        ]
      end

      let(:right_data) do
        [
          ['salary_grade', 'min_level', 'max_level', 'base_salary'],
          ['Junior', '1', '3', '50000'],
          ['Mid', '4', '6', '75000'],
          ['Senior', '7', '10', '100000']
        ]
      end

      let(:context) do
        {
          'input-1' => left_data,
          'input-2' => right_data
        }
      end

      it 'supports different comparison operators' do
        result = processor.process(node, context)

        expect(result[:success]).to be true

        data_rows = result[:data][1..]

        # Alice (level 3) -> Junior
        alice_row = data_rows.find { |row| row[0] == 'Alice' }
        expect(alice_row[2]).to eq('Junior')

        # Bob (level 5) -> Mid
        bob_row = data_rows.find { |row| row[0] == 'Bob' }
        expect(bob_row[2]).to eq('Mid')

        # Charlie (level 8) -> Senior
        charlie_row = data_rows.find { |row| row[0] == 'Charlie' }
        expect(charlie_row[2]).to eq('Senior')
      end
    end

    context 'error handling' do
      it 'handles missing left data' do
        context = { 'input-2' => [['id'], ['1']] }
        result = processor.process(node, context)

        expect(result[:success]).to be false
        expect(result[:error]).to include('Missing left input data')
      end

      it 'handles missing right data' do
        context = { 'input-1' => [['id'], ['1']] }
        result = processor.process(node, context)

        expect(result[:success]).to be false
        expect(result[:error]).to include('Missing right input data')
      end

      it 'handles empty data' do
        context = {
          'input-1' => [],
          'input-2' => []
        }
        result = processor.process(node, context)

        expect(result[:success]).to be false
        expect(result[:error]).to include('Empty input data')
      end

      it 'handles missing join conditions' do
        node['data']['joinConditions'] = []
        context = {
          'input-1' => [['id'], ['1']],
          'input-2' => [['id'], ['1']]
        }
        result = processor.process(node, context)

        expect(result[:success]).to be false
        expect(result[:error]).to include('No join conditions specified')
      end

      it 'handles invalid field references' do
        node['data']['joinConditions'] = [
          {
            'leftField' => 'non_existent',
            'operator' => '=',
            'rightField' => 'user_id'
          }
        ]
        context = {
          'input-1' => [['id'], ['1']],
          'input-2' => [['user_id'], ['1']]
        }
        result = processor.process(node, context)

        expect(result[:success]).to be false
        expect(result[:error]).to include('Field not found')
      end
    end
  end
end