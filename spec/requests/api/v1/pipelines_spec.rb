require 'rails_helper'

RSpec.describe 'Api::V1::Pipelines', type: :request do
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
              {
                column: 'name',
                operation: 'uppercase',
                inPlace: true
              }
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

  describe 'POST /api/v1/pipelines/execute' do
    context 'with valid pipeline configuration' do
      it 'executes the pipeline successfully' do
        post '/api/v1/pipelines/execute', params: { pipeline: valid_pipeline_config }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['execution_id']).to be_present
        expect(json['result']).to be_present
      end

      it 'returns transformed data' do
        post '/api/v1/pipelines/execute', params: { pipeline: valid_pipeline_config }

        json = JSON.parse(response.body)
        result = JSON.parse(json['result']['content'])

        expect(result).to be_an(Array)
        expect(result[0]['name']).to eq('ALICE')
        expect(result[1]['name']).to eq('BOB')
      end
    end

    context 'with invalid pipeline configuration' do
      it 'returns error for missing nodes' do
        post '/api/v1/pipelines/execute', params: { pipeline: { edges: [] } }

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
        expect(json['error']).to include('Pipeline must have nodes')
      end

      it 'returns error for invalid node type' do
        invalid_config = {
          nodes: [{ id: 'node-1', type: 'invalid' }],
          edges: []
        }
        post '/api/v1/pipelines/execute', params: { pipeline: invalid_config }

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
        expect(json['error']).to include('invalid node type')
      end
    end

    context 'with async execution' do
      it 'returns execution ID and status URL' do
        post '/api/v1/pipelines/execute', params: { pipeline: valid_pipeline_config, async: true }

        expect(response).to have_http_status(:accepted)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['execution_id']).to be_present
        expect(json['status']).to eq('running')
        expect(json['status_url']).to include('/api/v1/pipelines/')
      end
    end

    context 'with empty pipeline param' do
      it 'handles missing pipeline gracefully' do
        post '/api/v1/pipelines/execute', params: {}

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
      end
    end
  end

  describe 'GET /api/v1/pipelines/:id/status' do
    let(:execution_id) { 'test-exec-123' }

    context 'with running execution' do
      before do
        Api::V1::PipelinesController.class_variable_set(:@@executors, {
          execution_id => {
            executor: double('executor', get_status: {
              progress: 66,
              current_node: 'transform-1'
            }),
            status: 'running',
            started_at: Time.current
          }
        })
      end

      it 'returns execution status' do
        get "/api/v1/pipelines/#{execution_id}/status"

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['status']).to eq('running')
        expect(json['progress']).to eq(66)
        expect(json['current_node']).to eq('transform-1')
      end
    end

    context 'with completed execution' do
      before do
        Api::V1::PipelinesController.class_variable_set(:@@executors, {
          execution_id => {
            status: 'completed',
            started_at: 1.hour.ago,
            completed_at: 55.minutes.ago,
            result: {
              result: { data: 'test result' },
              metrics: { nodes_executed: 3, total_time: 5.2 }
            }
          }
        })
      end

      it 'returns completed status with result' do
        get "/api/v1/pipelines/#{execution_id}/status"

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['status']).to eq('completed')
        expect(json['progress']).to eq(100)
        expect(json['result']).to eq({ 'data' => 'test result' })
        expect(json['metrics']).to include('nodes_executed' => 3)
      end
    end

    context 'with failed execution' do
      before do
        Api::V1::PipelinesController.class_variable_set(:@@executors, {
          execution_id => {
            status: 'failed',
            started_at: 30.minutes.ago,
            error: 'Node transform-1 failed: Invalid operation'
          }
        })
      end

      it 'returns failed status with error details' do
        get "/api/v1/pipelines/#{execution_id}/status"

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['status']).to eq('failed')
        expect(json['error']).to include('Invalid operation')
      end
    end

    context 'with non-existent execution' do
      it 'returns 404' do
        get '/api/v1/pipelines/non-existent/status'

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Execution not found')
      end
    end
  end

  describe 'POST /api/v1/pipelines/:id/stop' do
    let(:execution_id) { 'test-exec-456' }

    context 'with running execution' do
      let(:mock_executor) { double('executor') }

      before do
        allow(mock_executor).to receive(:stop)
        Api::V1::PipelinesController.class_variable_set(:@@executors, {
          execution_id => {
            executor: mock_executor,
            status: 'running',
            started_at: Time.current
          }
        })
      end

      it 'stops the execution' do
        post "/api/v1/pipelines/#{execution_id}/stop"

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['status']).to eq('stopped')
      end
    end

    context 'with non-existent execution' do
      it 'returns 404' do
        post '/api/v1/pipelines/non-existent/stop'

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Execution not found')
      end
    end
  end

  describe 'POST /api/v1/pipelines/validate' do
    context 'with valid pipeline' do
      it 'returns valid status' do
        post '/api/v1/pipelines/validate', params: { pipeline: valid_pipeline_config }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['valid']).to be true
        expect(json['errors']).to be_empty
      end
    end

    context 'with invalid pipeline' do
      it 'returns validation errors' do
        invalid_config = valid_pipeline_config.deep_dup
        invalid_config[:nodes] << { id: 'invalid-node', type: 'invalid' }

        post '/api/v1/pipelines/validate', params: { pipeline: invalid_config }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['valid']).to be false
        expect(json['errors']).to include('invalid node type: invalid')
      end

      it 'validates edge references' do
        invalid_config = valid_pipeline_config.deep_dup
        invalid_config[:edges] << { source: 'non-existent', target: 'also-non-existent' }

        post '/api/v1/pipelines/validate', params: { pipeline: invalid_config }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['valid']).to be false
        expect(json['errors']).to include('Edge references non-existent node: non-existent')
      end
    end
  end

  describe 'GET /api/v1/pipelines/execution_history' do
    before do
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
    end

    it 'returns list of recent executions' do
      get '/api/v1/pipelines/execution_history'

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['executions']).to be_an(Array)
      expect(json['executions'].size).to eq(2)

      # Check that executions are returned in reverse order (newest first)
      exec_ids = json['executions'].map { |e| e['id'] }
      expect(exec_ids).to include('exec-1', 'exec-2')
    end

    it 'supports pagination' do
      get '/api/v1/pipelines/execution_history', params: { page: 1, per_page: 1 }

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['executions'].size).to eq(1)
      expect(json['pagination']['page']).to eq(1)
      expect(json['pagination']['per_page']).to eq(1)
      expect(json['pagination']['total']).to eq(2)
      expect(json['pagination']['total_pages']).to eq(2)
    end
  end
end