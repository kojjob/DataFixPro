require 'rails_helper'

RSpec.describe Api::V1::PipelinesController, type: :controller do
  before do
    # Clear executors between tests
    Api::V1::PipelinesController.class_variable_set(:@@executors, {})
  end

  let(:valid_pipeline_config) do
    {
      nodes: [
        {
          id: 'input-1',
          type: 'input',
          data: {
            sourceType: 'csv',
            csvContent: "name,age\nAlice,30\nBob,25"
          }
        },
        {
          id: 'transform-1',
          type: 'transform',
          data: {
            transformType: 'column',
            operations: [
              { column: 'name', operation: 'uppercase', inPlace: true }
            ]
          }
        },
        {
          id: 'output-1',
          type: 'output',
          data: {
            outputType: 'json'
          }
        }
      ],
      edges: [
        { id: 'e1', source: 'input-1', target: 'transform-1' },
        { id: 'e2', source: 'transform-1', target: 'output-1' }
      ]
    }
  end

  describe 'POST #execute' do
    context 'with valid pipeline configuration' do
      it 'executes the pipeline successfully' do
        post :execute, params: { pipeline: valid_pipeline_config }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['execution_id']).to be_present
        expect(json['result']).to be_present
      end

      it 'returns transformed data' do
        post :execute, params: { pipeline: valid_pipeline_config }

        json = JSON.parse(response.body)
        result = JSON.parse(json['result']['content'])

        expect(result).to be_an(Array)
        expect(result[0]['name']).to eq('ALICE')
        expect(result[1]['name']).to eq('BOB')
      end

      it 'includes execution metrics' do
        post :execute, params: { pipeline: valid_pipeline_config }

        json = JSON.parse(response.body)
        expect(json['metrics']).to be_present
        expect(json['metrics']['total_time']).to be_a(Numeric)
        expect(json['metrics']['node_count']).to eq(3)
        expect(json['metrics']['successful_nodes']).to eq(3)
      end
    end

    context 'with invalid pipeline configuration' do
      it 'returns error for missing nodes' do
        post :execute, params: { pipeline: { edges: [] } }

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
        expect(json['error']).to include('nodes')
      end

      it 'returns error for invalid node type' do
        invalid_config = valid_pipeline_config.deep_dup
        invalid_config[:nodes][0][:type] = 'invalid'

        post :execute, params: { pipeline: invalid_config }

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
        expect(json['error']).to include('invalid node type')
      end

      it 'returns error for cyclic dependencies' do
        cyclic_config = {
          nodes: [
            { id: 'n1', type: 'transform', data: { transformType: 'column' } },
            { id: 'n2', type: 'transform', data: { transformType: 'column' } }
          ],
          edges: [
            { id: 'e1', source: 'n1', target: 'n2' },
            { id: 'e2', source: 'n2', target: 'n1' }
          ]
        }

        post :execute, params: { pipeline: cyclic_config }

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
        expect(json['error']).to include('cyclic')
      end
    end

    context 'with async execution' do
      it 'starts async execution when async flag is true' do
        post :execute, params: {
          pipeline: valid_pipeline_config,
          async: true
        }

        expect(response).to have_http_status(:accepted)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['execution_id']).to be_present
        expect(json['status']).to eq('running')
        expect(json['status_url']).to be_present
      end
    end
  end

  describe 'GET #status' do
    let(:execution_id) { SecureRandom.uuid }

    context 'with running execution' do
      before do
        allow_any_instance_of(PipelineExecutor).to receive(:get_status).and_return({
          id: execution_id,
          status: 'running',
          progress: 66,
          current_node: 'transform-1'
        })
      end

      it 'returns execution status' do
        get :status, params: { id: execution_id }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['status']).to eq('running')
        expect(json['progress']).to eq(66)
        expect(json['current_node']).to eq('transform-1')
      end
    end

    context 'with completed execution' do
      before do
        allow_any_instance_of(PipelineExecutor).to receive(:get_status).and_return({
          id: execution_id,
          status: 'completed',
          progress: 100,
          result: { content: '[{"name": "ALICE"}, {"name": "BOB"}]' },
          metrics: { total_time: 1.23 }
        })
      end

      it 'returns completed status with result' do
        get :status, params: { id: execution_id }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['status']).to eq('completed')
        expect(json['progress']).to eq(100)
        expect(json['result']).to be_present
        expect(json['metrics']).to be_present
      end
    end

    context 'with failed execution' do
      before do
        allow_any_instance_of(PipelineExecutor).to receive(:get_status).and_return({
          id: execution_id,
          status: 'failed',
          error: 'Node transform-1 failed: Invalid column',
          failed_node: 'transform-1'
        })
      end

      it 'returns failed status with error details' do
        get :status, params: { id: execution_id }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['status']).to eq('failed')
        expect(json['error']).to include('Invalid column')
        expect(json['failed_node']).to eq('transform-1')
      end
    end

    context 'with unknown execution' do
      it 'returns not found' do
        get :status, params: { id: 'unknown-id' }

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['error']).to include('not found')
      end
    end
  end

  describe 'POST #stop' do
    let(:execution_id) { SecureRandom.uuid }

    context 'with running execution' do
      before do
        allow_any_instance_of(PipelineExecutor).to receive(:stop).and_return(true)
        allow_any_instance_of(PipelineExecutor).to receive(:get_status).and_return({
          id: execution_id,
          status: 'stopped'
        })
      end

      it 'stops the execution' do
        post :stop, params: { id: execution_id }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['status']).to eq('stopped')
      end
    end

    context 'with unknown execution' do
      it 'returns not found' do
        post :stop, params: { id: 'unknown-id' }

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'POST #validate' do
    context 'with valid pipeline' do
      it 'returns validation success' do
        post :validate, params: { pipeline: valid_pipeline_config }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['valid']).to be true
        expect(json['errors']).to be_empty
      end
    end

    context 'with invalid pipeline' do
      it 'returns validation errors' do
        invalid_config = valid_pipeline_config.deep_dup
        invalid_config[:nodes][0][:type] = 'invalid'

        post :validate, params: { pipeline: invalid_config }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['valid']).to be false
        expect(json['errors']).to include('invalid node type: invalid')
      end

      it 'validates edge references' do
        invalid_config = valid_pipeline_config.deep_dup
        invalid_config[:edges] << {
          id: 'e3',
          source: 'non-existent',
          target: 'output-1'
        }

        post :validate, params: { pipeline: invalid_config }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['valid']).to be false
        expect(json['errors']).to include(/non-existent/)
      end
    end
  end

  describe 'GET #execution_history' do
    it 'returns list of recent executions' do
      # Populate some execution history
      Api::V1::PipelinesController.class_variable_set(:@@executors, {
        'exec-1' => {
          status: 'completed',
          started_at: 1.hour.ago,
          completed_at: 55.minutes.ago,
          result: { metrics: { nodes_executed: 3 } }
        },
        'exec-2' => {
          status: 'failed',
          started_at: 2.hours.ago,
          error: 'Transform failed'
        }
      })

      get :execution_history

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['executions']).to be_an(Array)
      expect(json['executions'].size).to eq(2)
      expect(json['executions'][0]['id']).to eq('exec-1')
      expect(json['executions'][0]['status']).to eq('completed')
    end

    it 'supports pagination' do
      get :execution_history, params: { page: 2, per_page: 10 }

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json).to have_key('executions')
      expect(json).to have_key('pagination')
    end
  end
end