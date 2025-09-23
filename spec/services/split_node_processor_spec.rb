require 'rails_helper'

RSpec.describe SplitNodeProcessor do
  let(:processor) { described_class.new }

  describe '#process' do
    context 'with conditional split' do
      let(:node) do
        {
          'id' => 'split-1',
          'type' => 'split',
          'data' => {
            'splitType' => 'conditional',
            'conditions' => [
              {
                'id' => '1',
                'name' => 'High Value',
                'field' => 'amount',
                'operator' => '>',
                'value' => '100'
              },
              {
                'id' => '2',
                'name' => 'Medium Value',
                'field' => 'amount',
                'operator' => '>=',
                'value' => '50'
              },
              {
                'id' => '3',
                'name' => 'Low Value',
                'isElse' => true
              }
            ]
          }
        }
      end

      let(:input_data) do
        [
          ['id', 'name', 'amount'],
          ['1', 'Alice', '150'],
          ['2', 'Bob', '75'],
          ['3', 'Charlie', '30'],
          ['4', 'David', '200'],
          ['5', 'Eve', '50']
        ]
      end

      let(:context) do
        { 'input-1' => input_data }
      end

      it 'splits data based on conditions' do
        result = processor.process(node, context)

        expect(result[:success]).to be true
        expect(result[:outputs]).to be_a(Hash)
        expect(result[:outputs].keys).to contain_exactly('output1', 'output2', 'output3')

        # High Value (>100): Alice (150) and David (200)
        high_value = result[:outputs]['output1']
        expect(high_value[0]).to eq(['id', 'name', 'amount']) # Headers
        expect(high_value[1..].map { |row| row[1] }).to contain_exactly('Alice', 'David')

        # Medium Value (>=50): Bob (75) and Eve (50)
        medium_value = result[:outputs]['output2']
        expect(medium_value[1..].map { |row| row[1] }).to contain_exactly('Bob', 'Eve')

        # Low Value (else): Charlie (30)
        low_value = result[:outputs]['output3']
        expect(low_value[1..].map { |row| row[1] }).to contain_exactly('Charlie')
      end

      it 'evaluates conditions in order' do
        # Test that first matching condition wins
        node['data']['conditions'] = [
          {
            'id' => '1',
            'name' => 'Greater than 50',
            'field' => 'amount',
            'operator' => '>',
            'value' => '50'
          },
          {
            'id' => '2',
            'name' => 'Greater than 100',
            'field' => 'amount',
            'operator' => '>',
            'value' => '100'
          }
        ]

        result = processor.process(node, context)

        # All values >50 should go to first output
        # Values >100 would also match second condition but should already be taken
        output1 = result[:outputs]['output1']
        expect(output1[1..].map { |row| row[1] }).to contain_exactly('Alice', 'Bob', 'David')

        output2 = result[:outputs]['output2']
        expect(output2[1..]).to be_empty
      end

      it 'handles string comparisons' do
        node['data']['conditions'] = [
          {
            'id' => '1',
            'name' => 'Names A-M',
            'field' => 'name',
            'operator' => '<',
            'value' => 'M'
          },
          {
            'id' => '2',
            'name' => 'Names N-Z',
            'isElse' => true
          }
        ]

        result = processor.process(node, context)

        output1 = result[:outputs]['output1']
        expect(output1[1..].map { |row| row[1] }).to contain_exactly('Alice', 'Bob', 'Charlie', 'David', 'Eve')

        output2 = result[:outputs]['output2']
        expect(output2[1..]).to be_empty # No names start with N or later
      end

      it 'handles equality operator' do
        node['data']['conditions'] = [
          {
            'id' => '1',
            'name' => 'Exactly 75',
            'field' => 'amount',
            'operator' => '=',
            'value' => '75'
          },
          {
            'id' => '2',
            'name' => 'Others',
            'isElse' => true
          }
        ]

        result = processor.process(node, context)

        output1 = result[:outputs]['output1']
        expect(output1[1..].map { |row| row[1] }).to contain_exactly('Bob')

        output2 = result[:outputs]['output2']
        expect(output2[1..].map { |row| row[1] }).to contain_exactly('Alice', 'Charlie', 'David', 'Eve')
      end

      it 'tracks row counts for each output' do
        result = processor.process(node, context)

        expect(result[:statistics]).to include(
          'output1' => 2, # Alice, David
          'output2' => 2, # Bob, Eve
          'output3' => 1  # Charlie
        )
      end
    end

    context 'with random split' do
      let(:node) do
        {
          'id' => 'split-1',
          'type' => 'split',
          'data' => {
            'splitType' => 'random',
            'splitRatio' => [70, 30]
          }
        }
      end

      let(:input_data) do
        [
          ['id', 'name'],
          *((1..100).map { |i| [i.to_s, "Person#{i}"] })
        ]
      end

      let(:context) do
        { 'input-1' => input_data }
      end

      it 'splits data randomly according to ratio' do
        # Set random seed for reproducible test
        srand(12345)

        result = processor.process(node, context)

        expect(result[:success]).to be true

        output1_count = result[:outputs]['output1'].size - 1 # Minus header
        output2_count = result[:outputs]['output2'].size - 1

        # Check that all rows are distributed
        expect(output1_count + output2_count).to eq(100)

        # Check ratio is approximately correct (within 10% tolerance)
        expect(output1_count).to be_between(63, 77) # 70% ± 7%
        expect(output2_count).to be_between(23, 37) # 30% ± 7%
      end

      it 'maintains row integrity in random split' do
        srand(12345)

        result = processor.process(node, context)

        # Check that rows are complete and not corrupted
        output1 = result[:outputs]['output1']
        output2 = result[:outputs]['output2']

        # All rows should have same number of columns as input
        all_output_rows = output1[1..] + output2[1..]
        all_output_rows.each do |row|
          expect(row.size).to eq(2)
          expect(row[0]).to match(/^\d+$/)
          expect(row[1]).to match(/^Person\d+$/)
        end
      end
    end

    context 'with hash split' do
      let(:node) do
        {
          'id' => 'split-1',
          'type' => 'split',
          'data' => {
            'splitType' => 'hash',
            'hashField' => 'user_id',
            'buckets' => 3
          }
        }
      end

      let(:input_data) do
        [
          ['user_id', 'name', 'value'],
          ['user_001', 'Alice', '100'],
          ['user_002', 'Bob', '200'],
          ['user_003', 'Charlie', '300'],
          ['user_004', 'David', '400'],
          ['user_005', 'Eve', '500'],
          ['user_006', 'Frank', '600']
        ]
      end

      let(:context) do
        { 'input-1' => input_data }
      end

      it 'splits data deterministically based on hash' do
        result = processor.process(node, context)

        expect(result[:success]).to be true
        expect(result[:outputs].keys).to contain_exactly('output1', 'output2', 'output3')

        # Hash split should be deterministic - same ID always goes to same bucket
        result2 = processor.process(node, context)
        expect(result[:outputs]).to eq(result2[:outputs])
      end

      it 'distributes data evenly across buckets' do
        # Generate more data for better distribution test
        large_input = [
          ['user_id', 'value'],
          *((1..300).map { |i| ["user_#{i.to_s.rjust(3, '0')}", i.to_s] })
        ]
        context = { 'input-1' => large_input }

        result = processor.process(node, context)

        bucket_sizes = result[:outputs].values.map { |output| output.size - 1 } # Minus headers

        # Check relatively even distribution (within 20% of expected)
        expected_size = 100
        bucket_sizes.each do |size|
          expect(size).to be_between(80, 120)
        end
      end

      it 'handles missing hash field' do
        node['data']['hashField'] = 'non_existent'

        result = processor.process(node, context)

        expect(result[:success]).to be false
        expect(result[:error]).to include('Hash field not found')
      end
    end

    context 'with round-robin split' do
      let(:node) do
        {
          'id' => 'split-1',
          'type' => 'split',
          'data' => {
            'splitType' => 'round-robin',
            'outputs' => 3
          }
        }
      end

      let(:input_data) do
        [
          ['id', 'value'],
          ['1', 'A'],
          ['2', 'B'],
          ['3', 'C'],
          ['4', 'D'],
          ['5', 'E'],
          ['6', 'F'],
          ['7', 'G']
        ]
      end

      let(:context) do
        { 'input-1' => input_data }
      end

      it 'distributes rows in round-robin fashion' do
        result = processor.process(node, context)

        expect(result[:success]).to be true

        # Output1: rows 1, 4, 7
        output1 = result[:outputs]['output1']
        expect(output1[1..].map { |row| row[0] }).to eq(['1', '4', '7'])

        # Output2: rows 2, 5
        output2 = result[:outputs]['output2']
        expect(output2[1..].map { |row| row[0] }).to eq(['2', '5'])

        # Output3: rows 3, 6
        output3 = result[:outputs]['output3']
        expect(output3[1..].map { |row| row[0] }).to eq(['3', '6'])
      end

      it 'maintains order within each output' do
        result = processor.process(node, context)

        # Check that values are in sequence within each output
        output1_values = result[:outputs]['output1'][1..].map { |row| row[1] }
        expect(output1_values).to eq(['A', 'D', 'G'])
      end
    end

    context 'error handling' do
      let(:node) do
        {
          'id' => 'split-1',
          'type' => 'split',
          'data' => {
            'splitType' => 'conditional',
            'conditions' => [
              {
                'id' => '1',
                'field' => 'amount',
                'operator' => '>',
                'value' => '100'
              }
            ]
          }
        }
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

      it 'handles invalid split type' do
        node['data']['splitType'] = 'invalid'
        context = { 'input-1' => [['id'], ['1']] }

        result = processor.process(node, context)

        expect(result[:success]).to be false
        expect(result[:error]).to include('Unsupported split type')
      end

      it 'handles missing field in conditional split' do
        node['data']['conditions'][0]['field'] = 'non_existent'
        context = { 'input-1' => [['id', 'amount'], ['1', '100']] }

        result = processor.process(node, context)

        expect(result[:success]).to be false
        expect(result[:error]).to include('Field not found')
      end

      it 'handles missing split configuration' do
        node['data'] = {}
        context = { 'input-1' => [['id'], ['1']] }

        result = processor.process(node, context)

        expect(result[:success]).to be false
        expect(result[:error]).to include('Split type not specified')
      end

      it 'handles invalid split ratio' do
        node['data'] = {
          'splitType' => 'random',
          'splitRatio' => [60, 30] # Doesn't sum to 100
        }
        context = { 'input-1' => [['id'], ['1']] }

        result = processor.process(node, context)

        expect(result[:success]).to be false
        expect(result[:error]).to include('Split ratio must sum to 100')
      end
    end
  end
end