require 'rails_helper'

RSpec.describe PipelineExecutor do
  let(:pipeline) { create(:pipeline) }
  let(:executor) { described_class.new(pipeline) }

  describe '#initialize' do
    it 'initializes with a pipeline' do
      expect(executor.pipeline).to eq(pipeline)
    end

    it 'initializes with empty execution context' do
      expect(executor.instance_variable_get(:@execution_context)).to eq({})
    end
  end

  describe '#execute' do
    context 'with simple linear pipeline' do
      let(:nodes) do
        [
          { id: 'input-1', type: 'input', data: { source: 'test.csv' } },
          { id: 'transform-1', type: 'transform', data: { operation: 'uppercase' } },
          { id: 'output-1', type: 'output', data: { destination: 'result.csv' } }
        ]
      end

      let(:edges) do
        [
          { source: 'input-1', target: 'transform-1' },
          { source: 'transform-1', target: 'output-1' }
        ]
      end

      before do
        pipeline.update(configuration: { nodes: nodes, edges: edges })
      end

      it 'executes nodes in topological order' do
        allow_any_instance_of(InputNodeProcessor).to receive(:process)
          .and_return({ success: true, data: [['test']] })
        allow_any_instance_of(TransformNodeProcessor).to receive(:process)
          .and_return({ success: true, data: [['TEST']] })
        allow_any_instance_of(OutputNodeProcessor).to receive(:process)
          .and_return({ success: true })

        result = executor.execute
        expect(result[:success]).to be true
        expect(result[:executed_nodes]).to eq(['input-1', 'transform-1', 'output-1'])
      end

      it 'stops execution on error' do
        allow_any_instance_of(InputNodeProcessor).to receive(:process)
          .and_return({ success: false, error: 'File not found' })

        result = executor.execute
        expect(result[:success]).to be false
        expect(result[:error]).to eq('File not found')
        expect(result[:failed_node]).to eq('input-1')
      end
    end

    context 'with join node' do
      let(:nodes) do
        [
          { id: 'input-1', type: 'input', data: { source: 'users.csv' } },
          { id: 'input-2', type: 'input', data: { source: 'orders.csv' } },
          {
            id: 'join-1',
            type: 'join',
            data: {
              joinType: 'inner',
              leftTable: 'users',
              rightTable: 'orders',
              joinConditions: [
                { leftField: 'id', operator: '=', rightField: 'user_id' }
              ]
            }
          },
          { id: 'output-1', type: 'output', data: { destination: 'joined.csv' } }
        ]
      end

      let(:edges) do
        [
          { source: 'input-1', target: 'join-1', targetHandle: 'left' },
          { source: 'input-2', target: 'join-1', targetHandle: 'right' },
          { source: 'join-1', target: 'output-1' }
        ]
      end

      before do
        pipeline.update(configuration: { nodes: nodes, edges: edges })
      end

      it 'executes join operation with data from both inputs' do
        users_data = [
          ['id', 'name'],
          ['1', 'Alice'],
          ['2', 'Bob']
        ]

        orders_data = [
          ['id', 'user_id', 'amount'],
          ['101', '1', '50.00'],
          ['102', '2', '75.00']
        ]

        allow_any_instance_of(InputNodeProcessor).to receive(:process) do |processor, node, _context|
          if node[:data][:source] == 'users.csv'
            { success: true, data: users_data }
          else
            { success: true, data: orders_data }
          end
        end

        allow_any_instance_of(JoinNodeProcessor).to receive(:process)
          .and_return({ success: true, data: 'joined_data' })
        allow_any_instance_of(OutputNodeProcessor).to receive(:process)
          .and_return({ success: true })

        result = executor.execute
        expect(result[:success]).to be true
        expect(result[:executed_nodes]).to include('join-1')
      end

      it 'waits for all inputs before executing join' do
        execution_order = []

        allow_any_instance_of(InputNodeProcessor).to receive(:process) do |_processor, node, _context|
          execution_order << node[:id]
          { success: true, data: [] }
        end

        allow_any_instance_of(JoinNodeProcessor).to receive(:process) do |_processor, node, _context|
          execution_order << node[:id]
          { success: true, data: [] }
        end

        allow_any_instance_of(OutputNodeProcessor).to receive(:process) do |_processor, node, _context|
          execution_order << node[:id]
          { success: true }
        end

        executor.execute

        # Join should execute after both inputs
        join_index = execution_order.index('join-1')
        input1_index = execution_order.index('input-1')
        input2_index = execution_order.index('input-2')

        expect(join_index).to be > input1_index
        expect(join_index).to be > input2_index
      end
    end

    context 'with split node' do
      let(:nodes) do
        [
          { id: 'input-1', type: 'input', data: { source: 'data.csv' } },
          {
            id: 'split-1',
            type: 'split',
            data: {
              splitType: 'conditional',
              conditions: [
                { id: '1', name: 'High', field: 'amount', operator: '>', value: '100' },
                { id: '2', name: 'Low', field: 'amount', operator: '<=', value: '100' }
              ]
            }
          },
          { id: 'output-1', type: 'output', data: { destination: 'high.csv' } },
          { id: 'output-2', type: 'output', data: { destination: 'low.csv' } }
        ]
      end

      let(:edges) do
        [
          { source: 'input-1', target: 'split-1' },
          { source: 'split-1', sourceHandle: 'output1', target: 'output-1' },
          { source: 'split-1', sourceHandle: 'output2', target: 'output-2' }
        ]
      end

      before do
        pipeline.update(configuration: { nodes: nodes, edges: edges })
      end

      it 'routes data to multiple outputs based on conditions' do
        input_data = [
          ['id', 'amount'],
          ['1', '150'],
          ['2', '75'],
          ['3', '200'],
          ['4', '50']
        ]

        allow_any_instance_of(InputNodeProcessor).to receive(:process)
          .and_return({ success: true, data: input_data })

        split_result = {
          success: true,
          outputs: {
            'output1' => [['id', 'amount'], ['1', '150'], ['3', '200']],
            'output2' => [['id', 'amount'], ['2', '75'], ['4', '50']]
          }
        }

        allow_any_instance_of(SplitNodeProcessor).to receive(:process)
          .and_return(split_result)

        output_calls = []
        allow_any_instance_of(OutputNodeProcessor).to receive(:process) do |_processor, node, context|
          output_calls << { node: node[:id], data: context[:data] }
          { success: true }
        end

        result = executor.execute
        expect(result[:success]).to be true
        expect(output_calls).to have_exactly(2).items
      end
    end

    context 'with validation node' do
      let(:nodes) do
        [
          { id: 'input-1', type: 'input', data: { source: 'data.csv' } },
          {
            id: 'validation-1',
            type: 'validation',
            data: {
              validationMode: 'strict',
              validationRules: [
                { id: '1', field: 'email', type: 'format', rule: 'email' },
                { id: '2', field: 'age', type: 'range', min: 18, max: 100 }
              ]
            }
          },
          { id: 'output-valid', type: 'output', data: { destination: 'valid.csv' } },
          { id: 'output-invalid', type: 'output', data: { destination: 'invalid.csv' } }
        ]
      end

      let(:edges) do
        [
          { source: 'input-1', target: 'validation-1' },
          { source: 'validation-1', sourceHandle: 'valid', target: 'output-valid' },
          { source: 'validation-1', sourceHandle: 'invalid', target: 'output-invalid' }
        ]
      end

      before do
        pipeline.update(configuration: { nodes: nodes, edges: edges })
      end

      it 'routes valid and invalid data to separate outputs' do
        input_data = [
          ['email', 'age'],
          ['alice@example.com', '25'],
          ['invalid-email', '30'],
          ['bob@example.com', '150']
        ]

        allow_any_instance_of(InputNodeProcessor).to receive(:process)
          .and_return({ success: true, data: input_data })

        validation_result = {
          success: true,
          outputs: {
            'valid' => [['email', 'age'], ['alice@example.com', '25']],
            'invalid' => [['email', 'age'], ['invalid-email', '30'], ['bob@example.com', '150']]
          },
          statistics: {
            totalRecords: 3,
            validRecords: 1,
            invalidRecords: 2,
            errors: {
              email: 1,
              age: 1
            }
          }
        }

        allow_any_instance_of(ValidationNodeProcessor).to receive(:process)
          .and_return(validation_result)

        output_calls = []
        allow_any_instance_of(OutputNodeProcessor).to receive(:process) do |_processor, node, context|
          output_calls << { node: node[:id], data: context[:data] }
          { success: true }
        end

        result = executor.execute
        expect(result[:success]).to be true
        expect(result[:statistics][:validation_1]).to eq(validation_result[:statistics])
      end

      it 'stops on first error in strict mode' do
        allow_any_instance_of(InputNodeProcessor).to receive(:process)
          .and_return({ success: true, data: [] })

        allow_any_instance_of(ValidationNodeProcessor).to receive(:process)
          .and_return({ success: false, error: 'Validation failed: Invalid email format' })

        result = executor.execute
        expect(result[:success]).to be false
        expect(result[:error]).to include('Validation failed')
      end
    end

    context 'with complex pipeline' do
      it 'handles cyclic dependency detection' do
        nodes = [
          { id: 'node-1', type: 'transform' },
          { id: 'node-2', type: 'transform' },
          { id: 'node-3', type: 'transform' }
        ]

        edges = [
          { source: 'node-1', target: 'node-2' },
          { source: 'node-2', target: 'node-3' },
          { source: 'node-3', target: 'node-1' } # Creates cycle
        ]

        pipeline.update(configuration: { nodes: nodes, edges: edges })

        result = executor.execute
        expect(result[:success]).to be false
        expect(result[:error]).to include('Cyclic dependency detected')
      end

      it 'handles disconnected nodes' do
        nodes = [
          { id: 'input-1', type: 'input', data: { source: 'data.csv' } },
          { id: 'transform-1', type: 'transform' }, # Disconnected
          { id: 'output-1', type: 'output', data: { destination: 'result.csv' } }
        ]

        edges = [
          { source: 'input-1', target: 'output-1' }
        ]

        pipeline.update(configuration: { nodes: nodes, edges: edges })

        result = executor.execute
        expect(result[:success]).to be true
        expect(result[:executed_nodes]).not_to include('transform-1')
        expect(result[:warnings]).to include('Node transform-1 is disconnected')
      end

      it 'collects execution metrics' do
        nodes = [
          { id: 'input-1', type: 'input', data: { source: 'test.csv' } },
          { id: 'output-1', type: 'output', data: { destination: 'result.csv' } }
        ]

        edges = [
          { source: 'input-1', target: 'output-1' }
        ]

        pipeline.update(configuration: { nodes: nodes, edges: edges })

        allow_any_instance_of(InputNodeProcessor).to receive(:process) do
          sleep(0.1) # Simulate processing time
          { success: true, data: [] }
        end

        allow_any_instance_of(OutputNodeProcessor).to receive(:process)
          .and_return({ success: true })

        result = executor.execute
        expect(result[:metrics]).to include(:total_execution_time)
        expect(result[:metrics][:node_execution_times]).to have_key('input-1')
        expect(result[:metrics][:node_execution_times]['input-1']).to be > 0
      end
    end
  end

  describe '#validate_pipeline' do
    it 'validates pipeline configuration' do
      nodes = [
        { id: 'input-1', type: 'input', data: { source: 'test.csv' } }
      ]

      edges = []

      pipeline.update(configuration: { nodes: nodes, edges: edges })

      validation = executor.validate_pipeline
      expect(validation[:valid]).to be true
      expect(validation[:warnings]).to include('No output nodes detected')
    end

    it 'detects invalid node types' do
      nodes = [
        { id: 'node-1', type: 'invalid_type' }
      ]

      pipeline.update(configuration: { nodes: nodes, edges: [] })

      validation = executor.validate_pipeline
      expect(validation[:valid]).to be false
      expect(validation[:errors]).to include('Unknown node type: invalid_type')
    end

    it 'validates edge references' do
      nodes = [
        { id: 'node-1', type: 'input' }
      ]

      edges = [
        { source: 'node-1', target: 'non-existent' }
      ]

      pipeline.update(configuration: { nodes: nodes, edges: edges })

      validation = executor.validate_pipeline
      expect(validation[:valid]).to be false
      expect(validation[:errors]).to include('Edge references non-existent node: non-existent')
    end
  end

  describe '#get_execution_plan' do
    it 'returns topological order of execution' do
      nodes = [
        { id: 'A', type: 'input' },
        { id: 'B', type: 'transform' },
        { id: 'C', type: 'transform' },
        { id: 'D', type: 'output' }
      ]

      edges = [
        { source: 'A', target: 'B' },
        { source: 'A', target: 'C' },
        { source: 'B', target: 'D' },
        { source: 'C', target: 'D' }
      ]

      pipeline.update(configuration: { nodes: nodes, edges: edges })

      plan = executor.get_execution_plan

      # A should come before B and C
      expect(plan.index('A')).to be < plan.index('B')
      expect(plan.index('A')).to be < plan.index('C')

      # B and C should come before D
      expect(plan.index('B')).to be < plan.index('D')
      expect(plan.index('C')).to be < plan.index('D')
    end
  end
end